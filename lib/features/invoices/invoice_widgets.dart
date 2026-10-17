import 'package:flutter/material.dart';
import 'package:hvac_admin/core/billing/estimate_totals.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/models/office_payment.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';

class InvoiceStatusChip extends StatelessWidget {
  const InvoiceStatusChip({super.key, required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      InvoiceStatus.draft => (AppColors.surfaceHover, AppColors.textSecondary),
      InvoiceStatus.sent => (AppColors.primaryMuted, AppColors.primary),
      InvoiceStatus.paid => (AppColors.successMuted, AppColors.success),
      InvoiceStatus.overdue => (AppColors.dangerMuted, AppColors.danger),
      InvoiceStatus.cancelled => (AppColors.warningMuted, AppColors.warning),
    };
    return StatusChip(label: status.label, background: background, foreground: foreground);
  }
}

class InvoicePreviewCard extends StatelessWidget {
  const InvoicePreviewCard({
    super.key,
    required this.invoice,
    this.customerName = 'Customer',
    this.propertyAddress = '',
    this.jobNumber = '',
  });

  final OfficeInvoice invoice;
  final String customerName;
  final String propertyAddress;
  final String jobNumber;

  @override
  Widget build(BuildContext context) {
    // Phase 22: use the invoice's own tax rate (0 when tax-free).
    final taxRate = (invoice.taxRatePct ?? 0) / 100.0;
    final tax = invoice.amount * taxRate;
    return SurfaceCard(
      key: const Key('invoice-preview'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(invoice.number, style: AppTypography.headlineMedium)),
              InvoiceStatusChip(status: invoice.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(customerName, style: AppTypography.titleMedium),
          if (propertyAddress.isNotEmpty) Text(propertyAddress, style: AppTypography.bodySmall),
          if (jobNumber.isNotEmpty) Text('Job $jobNumber', style: AppTypography.bodySmall),
          Text(
            'Issued ${formatDate(invoice.date)} · Due ${formatDate(invoice.dueDate)}',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Line items'),
          for (final item in invoice.items) ...[
            Row(
              children: [
                Expanded(child: Text(item.description, style: AppTypography.bodyMedium)),
                Text(
                  '${item.quantity} × ${formatCurrency(item.unitPrice)}',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(formatCurrency(item.total), style: AppTypography.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const Divider(),
          _TotalRow(label: 'Subtotal', value: formatCurrency(invoice.amount)),
          _TotalRow(
            label: taxRate == 0
                ? 'Tax (0%)'
                : 'Tax (${invoice.taxRatePct!.toStringAsFixed(2)}%)',
            value: formatCurrency(tax),
          ),
          _TotalRow(
            label: 'Total due',
            value: formatCurrency(invoice.amount + tax),
            emphasized: true,
          ),
          if (invoice.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(invoice.notes, style: AppTypography.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized ? AppTypography.titleMedium : AppTypography.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class PaymentHistoryCard extends StatelessWidget {
  const PaymentHistoryCard({super.key, required this.payment});

  final OfficePayment payment;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      key: Key('payment-row-${payment.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${payment.status.label} · ${formatCurrency(payment.amount)}',
            style: AppTypography.titleMedium,
          ),
          Text(
            '${payment.provider} · ${payment.providerPaymentId ?? payment.id}',
            style: AppTypography.labelSmall,
          ),
          if (payment.checkoutUrl != null)
            Text(payment.checkoutUrl!, style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}
