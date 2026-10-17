import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/invoice_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/invoices/invoice_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:hvac_admin/features/shared/widgets/paged_search_list.dart';
import 'package:provider/provider.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  InvoiceStatus? _status;
  bool _overdueOnly = false;
  bool _highValueOnly = false;

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceController>();
    return Padding(
      key: const Key('invoices-page'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoices', style: AppTypography.headlineMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text('Create, send, and track invoices with payment status.', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              AppPrimaryButton(
                label: 'New invoice',
                icon: Icons.add,
                onPressed: () => context.go('${AdminModule.invoices.path}/new'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _status == null && !_overdueOnly,
                onSelected: (_) => setState(() {
                  _status = null;
                  _overdueOnly = false;
                }),
              ),
              FilterChip(
                label: const Text('Overdue'),
                selected: _overdueOnly,
                onSelected: (_) => setState(() {
                  _overdueOnly = true;
                  _status = null;
                }),
              ),
              for (final status in InvoiceStatus.values)
                FilterChip(
                  label: Text(status.label),
                  selected: _status == status && !_overdueOnly,
                  onSelected: (_) => setState(() {
                    _status = status;
                    _overdueOnly = false;
                  }),
                ),
              FilterChip(
                label: const Text('\$500+'),
                selected: _highValueOnly,
                onSelected: (value) => setState(() => _highValueOnly = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: PagedSearchList<OfficeInvoice>(
              refreshToken: invoices.refreshToken,
              listKey: const Key('invoices-list'),
              searchHint: 'Search invoice number or notes',
              emptyTitle: 'No invoices',
              emptyMessage: 'Create an invoice from a job or convert an approved estimate.',
              fetchPage: (offset, query) => invoices.fetchInvoicesPage(
                offset: offset,
                search: query,
                status: _overdueOnly ? null : _status,
                overdueOnly: _overdueOnly,
                minAmount: _highValueOnly ? 500 : null,
              ),
              itemBuilder: (context, invoice) {
                final status = invoices.displayStatus(invoice);
                final totals = invoices.totalsFor(invoice);
                return MobileListTile(
                  key: Key('invoice-row-${invoice.id}'),
                  title: invoice.number,
                  subtitle: invoice.notes.isEmpty ? status.label : invoice.notes,
                  meta: '${formatCurrency(totals.total)} · Due ${formatDate(invoice.dueDate)}',
                  trailing: InvoiceStatusChip(status: status),
                  onTap: () => context.go('${AdminModule.invoices.path}/${invoice.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
