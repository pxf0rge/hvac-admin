import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/invoice_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/messaging/message_templates.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/payments/payments_status_service.dart';
import 'package:hvac_admin/core/portal/portal_link_service.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/features/communication/communication_page.dart';
import 'package:hvac_admin/features/invoices/invoice_widgets.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:provider/provider.dart';

class InvoiceDetailPage extends StatefulWidget {
  const InvoiceDetailPage({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  OfficeInvoice? _invoice;
  bool _loading = true;
  String? _checkoutHint;
  String? _actionError;
  String _payOnlineLabel = PaymentsReadiness.fallback.label;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final customers = context.read<CustomerController>();
    final jobs = context.read<JobController>();
    final invoices = context.read<InvoiceController>();
    final paymentsStatus = context.read<PaymentsStatusService>();
    await customers.load();
    await jobs.loadDispatch();
    final invoice = await invoices.loadInvoice(widget.invoiceId);
    final readiness = await paymentsStatus.fetch();
    if (mounted) {
      setState(() {
        _invoice = invoice;
        _payOnlineLabel = readiness.label;
        _loading = false;
      });
    }
  }

  Future<void> _sendInvoice() async {
    final invoice = _invoice;
    if (invoice == null) return;
    final directory = context.read<CustomerController>();
    final property = directory.propertyById(invoice.propertyId);
    final customer = property == null ? null : directory.customerById(property.customerId);
    if (customer == null) return;

    await context.read<InvoiceController>().markSent(invoice.id);
    final portalUrl = await context.read<PortalLinkService>().mintInvoiceUrl(invoice.id);
    if (!mounted) return;
    context.go(
      communicationPath(
        entityType: CommunicationEntityType.customer,
        entityId: customer.id,
        template: MessageTemplateKind.invoiceLink,
        variables: {
          'invoice_number': invoice.number,
          'invoice_url': portalUrl,
          // Phase 22: amount due is the tax-inclusive grand total.
          'amount_due': formatCurrency(invoice.grandTotal),
          'due_date': formatDate(invoice.dueDate),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState(message: 'Loading invoice…');
    final invoice = _invoice;
    if (invoice == null) {
      return const EmptyState(title: 'Invoice not found', icon: Icons.receipt_long_outlined);
    }

    final directory = context.watch<CustomerController>();
    final invoices = context.watch<InvoiceController>();
    final status = invoices.displayStatus(invoice);
    final display = invoice.copyWith(status: status);
    final unpaid = status == InvoiceStatus.sent || status == InvoiceStatus.overdue;
    final payments = invoices.paymentsForInvoice(invoice.id);
    final job = context.read<JobController>().jobById(invoice.jobId);
    final property = directory.propertyById(invoice.propertyId);
    final customer = property == null ? null : directory.customerById(property.customerId);

    return ListView(
      key: const Key('invoice-detail'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      children: [
        InvoicePreviewCard(
          invoice: display,
          customerName: customer?.displayName ?? 'Customer',
          propertyAddress: property?.fullAddress ?? '',
          jobNumber: job?.jobNumber ?? '',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_actionError != null) ...[
          Text(_actionError!, style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
          const SizedBox(height: AppSpacing.sm),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (invoice.status == InvoiceStatus.draft)
              AppPrimaryButton(
                key: const Key('invoice-send'),
                label: 'Send to customer',
                icon: Icons.send_outlined,
                onPressed: _sendInvoice,
              ),
            if (unpaid) ...[
              AppPrimaryButton(
                key: const Key('pay-online'),
                label: _payOnlineLabel,
                icon: Icons.credit_card_outlined,
                onPressed: () async {
                  setState(() => _actionError = null);
                  try {
                    final session = await context.read<InvoiceController>().startOnlineCheckout(invoice.id);
                    if (!mounted) return;
                    setState(() => _checkoutHint = session.checkoutUrl);
                    await Clipboard.setData(ClipboardData(text: session.checkoutUrl));
                  } catch (error) {
                    if (!mounted) return;
                    setState(() => _actionError = error.toString());
                  }
                },
              ),
              AppSecondaryButton(
                key: const Key('record-payment'),
                label: 'Record payment',
                icon: Icons.payments_outlined,
                onPressed: () async {
                  await context.read<InvoiceController>().recordManualPayment(invoice.id);
                  await _load();
                },
              ),
            ],
            if (invoice.status != InvoiceStatus.paid && invoice.status != InvoiceStatus.cancelled)
              AppSecondaryButton(
                label: 'Void invoice',
                icon: Icons.block_outlined,
                onPressed: () async {
                  await context.read<InvoiceController>().markVoid(invoice.id);
                  await _load();
                },
              ),
            if (job != null)
              AppSecondaryButton(
                label: 'Open job',
                onPressed: () => context.go('${AdminModule.jobs.path}/${job.id}'),
              ),
            if (invoice.estimateId != null)
              AppSecondaryButton(
                label: 'View estimate',
                onPressed: () => context.go('${AdminModule.estimates.path}/${invoice.estimateId}'),
              ),
          ],
        ),
        if (_checkoutHint != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Checkout URL (copied): $_checkoutHint',
            key: const Key('checkout-url-hint'),
            style: AppTypography.labelSmall,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text('Payment history', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (payments.isEmpty)
          Text('No payments yet.', style: AppTypography.bodySmall)
        else
          for (final payment in payments)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: PaymentHistoryCard(payment: payment),
            ),
      ],
    );
  }
}
