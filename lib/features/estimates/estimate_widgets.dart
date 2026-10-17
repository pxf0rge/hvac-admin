import 'package:flutter/material.dart';
import 'package:hvac_admin/core/billing/estimate_totals.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';

class EstimateStatusChip extends StatelessWidget {
  const EstimateStatusChip({super.key, required this.status});

  final EstimateStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      EstimateStatus.draft => (AppColors.surfaceHover, AppColors.textSecondary),
      EstimateStatus.sent => (AppColors.primaryMuted, AppColors.primary),
      EstimateStatus.approved => (AppColors.successMuted, AppColors.success),
      EstimateStatus.declined => (AppColors.dangerMuted, AppColors.danger),
      EstimateStatus.expired => (AppColors.warningMuted, AppColors.warning),
    };
    return StatusChip(label: status.label, background: background, foreground: foreground);
  }
}

class EstimatePreviewCard extends StatelessWidget {
  const EstimatePreviewCard({
    super.key,
    required this.estimate,
    this.customerName = 'Customer',
    this.propertyAddress = '',
    this.jobNumber = '',
    this.taxRate = EstimateTotals.defaultTaxRate,
  });

  final OfficeEstimate estimate;
  final String customerName;
  final String propertyAddress;
  final String jobNumber;
  final double taxRate;

  @override
  Widget build(BuildContext context) {
    final totals = EstimateTotals.fromItems(estimate.items, taxRate: taxRate);
    return SurfaceCard(
      key: const Key('estimate-preview'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(estimate.number, style: AppTypography.headlineMedium)),
              EstimateStatusChip(status: estimate.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(customerName, style: AppTypography.titleMedium),
          if (propertyAddress.isNotEmpty) Text(propertyAddress, style: AppTypography.bodySmall),
          if (jobNumber.isNotEmpty) Text('Job $jobNumber', style: AppTypography.bodySmall),
          Text('Issued ${formatDate(estimate.date)}', style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Line items'),
          for (final item in estimate.items) ...[
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
          _TotalRow(label: 'Subtotal', value: formatCurrency(totals.subtotal)),
          _TotalRow(label: 'Tax (${(taxRate * 100).toStringAsFixed(2)}%)', value: formatCurrency(totals.tax)),
          _TotalRow(label: 'Total', value: formatCurrency(totals.total), emphasized: true),
          if (estimate.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(estimate.notes, style: AppTypography.bodySmall),
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
