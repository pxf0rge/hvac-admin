import 'package:flutter/material.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/tokens/tokens.dart';
import 'package:hvac_admin/design_system/widgets/status_chip.dart';

class JobStatusChip extends StatelessWidget {
  const JobStatusChip({super.key, required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      JobStatus.completed => (AppColors.successMuted, AppColors.success),
      JobStatus.cancelled => (AppColors.dangerMuted, AppColors.danger),
      JobStatus.inProgress || JobStatus.onTheWay || JobStatus.arrived => (AppColors.primaryMuted, AppColors.primary),
      _ => (AppColors.surfaceHover, AppColors.textSecondary),
    };
    return StatusChip(label: status.label, background: background, foreground: foreground);
  }
}

class WarrantyChip extends StatelessWidget {
  const WarrantyChip({super.key, required this.state});

  final WarrantyState state;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (state) {
      WarrantyState.expired => (AppColors.dangerMuted, AppColors.danger),
      WarrantyState.expiringSoon => (AppColors.warningMuted, AppColors.warning),
      WarrantyState.active => (AppColors.successMuted, AppColors.success),
    };
    return StatusChip(
      label: switch (state) {
        WarrantyState.expired => 'Expired',
        WarrantyState.expiringSoon => 'Expiring',
        WarrantyState.active => 'Active',
      },
      background: background,
      foreground: foreground,
    );
  }
}

class TimelineRow extends StatelessWidget {
  const TimelineRow({super.key, required this.event, this.isLast = false});

  final TimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: AppTypography.titleMedium),
                if (event.detail.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(event.detail, style: AppTypography.bodySmall),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(formatDate(event.at), style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
