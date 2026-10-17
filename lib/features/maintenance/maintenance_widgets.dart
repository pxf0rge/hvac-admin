import 'package:flutter/material.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/design_system/design_system.dart';

class MaintenanceAgreementStatusChip extends StatelessWidget {
  const MaintenanceAgreementStatusChip({super.key, required this.status});

  final MaintenanceAgreementStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      MaintenanceAgreementStatus.active => ('Active', AppColors.successMuted, AppColors.success),
      MaintenanceAgreementStatus.paused => ('Paused', AppColors.warningMuted, AppColors.warning),
      MaintenanceAgreementStatus.expired => ('Expired', AppColors.dangerMuted, AppColors.danger),
      MaintenanceAgreementStatus.cancelled => ('Cancelled', AppColors.border, AppColors.textSecondary),
    };
    return StatusChip(label: label, background: background, foreground: foreground);
  }
}
