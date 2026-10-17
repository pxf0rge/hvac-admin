import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/estimate_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/messaging/message_templates.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/portal/portal_link_service.dart';
import 'package:hvac_admin/features/communication/communication_page.dart';
import 'package:hvac_admin/features/estimates/estimate_widgets.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:provider/provider.dart';

class EstimateDetailPage extends StatefulWidget {
  const EstimateDetailPage({super.key, required this.estimateId});

  final String estimateId;

  @override
  State<EstimateDetailPage> createState() => _EstimateDetailPageState();
}

class _EstimateDetailPageState extends State<EstimateDetailPage> {
  OfficeEstimate? _estimate;
  OfficeInvoice? _invoice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final estimates = context.read<EstimateController>();
    await context.read<CustomerController>().load();
    await context.read<JobController>().loadDispatch();
    final estimate = await estimates.loadEstimate(widget.estimateId);
    final invoice = estimate == null ? null : await estimates.invoiceForEstimate(estimate.id);
    if (mounted) {
      setState(() {
        _estimate = estimate;
        _invoice = invoice;
        _loading = false;
      });
    }
  }

  Future<void> _sendEstimate() async {
    final estimate = _estimate;
    if (estimate == null) return;
    final directory = context.read<CustomerController>();
    final property = directory.propertyById(estimate.propertyId);
    final customer = property == null ? null : directory.customerById(property.customerId);
    if (customer == null) return;

    await context.read<EstimateController>().markSent(estimate.id);
    final portalUrl = await context.read<PortalLinkService>().mintEstimateUrl(estimate.id);
    if (!mounted) return;
    context.go(
      communicationPath(
        entityType: CommunicationEntityType.customer,
        entityId: customer.id,
        template: MessageTemplateKind.estimateLink,
        variables: {
          'estimate_number': estimate.number,
          'estimate_url': portalUrl,
        },
      ),
    );
  }

  Future<void> _convert() async {
    final estimate = _estimate;
    if (estimate == null) return;
    final invoice = await context.read<EstimateController>().convertToInvoice(estimate.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Draft invoice ${invoice.number} created.')),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState(message: 'Loading estimate…');
    final estimate = _estimate;
    if (estimate == null) {
      return const EmptyState(title: 'Estimate not found', icon: Icons.request_quote_outlined);
    }

    final directory = context.watch<CustomerController>();
    final job = context.read<JobController>().jobById(estimate.jobId);
    final property = directory.propertyById(estimate.propertyId);
    final customer = property == null ? null : directory.customerById(property.customerId);

    return ListView(
      key: const Key('estimate-detail'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      children: [
        EstimatePreviewCard(
          estimate: estimate,
          customerName: customer?.displayName ?? 'Customer',
          propertyAddress: property?.fullAddress ?? '',
          jobNumber: job?.jobNumber ?? '',
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (estimate.status == EstimateStatus.draft)
              AppPrimaryButton(
                key: const Key('estimate-send'),
                label: 'Send to customer',
                icon: Icons.send_outlined,
                onPressed: _sendEstimate,
              ),
            if (estimate.status == EstimateStatus.sent) ...[
              AppSecondaryButton(
                label: 'Mark approved',
                icon: Icons.check_circle_outline,
                onPressed: () async {
                  await context.read<EstimateController>().markApproved(estimate.id);
                  await _load();
                },
              ),
              AppSecondaryButton(
                label: 'Mark declined',
                icon: Icons.cancel_outlined,
                onPressed: () async {
                  await context.read<EstimateController>().markDeclined(estimate.id);
                  await _load();
                },
              ),
            ],
            if (estimate.status == EstimateStatus.approved && _invoice == null)
              AppSecondaryButton(
                key: const Key('estimate-convert'),
                label: 'Convert to invoice',
                icon: Icons.receipt_long_outlined,
                onPressed: _convert,
              ),
            if (_invoice != null)
              AppSecondaryButton(
                label: 'View invoice ${_invoice!.number}',
                icon: Icons.open_in_new,
                onPressed: () => context.go('${AdminModule.invoices.path}/${_invoice!.id}'),
              ),
            if (job != null)
              AppSecondaryButton(
                label: 'Open job',
                onPressed: () => context.go('${AdminModule.jobs.path}/${job.id}'),
              ),
          ],
        ),
      ],
    );
  }
}
