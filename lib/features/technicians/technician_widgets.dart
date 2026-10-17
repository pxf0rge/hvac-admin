import 'package:flutter/material.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/design_system/design_system.dart';

class TechnicianStatusChip extends StatelessWidget {
  const TechnicianStatusChip({super.key, required this.status});

  final TechnicianStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _statusColor(status);
    return StatusChip(label: status.label, background: background, foreground: foreground);
  }
}

(Color, Color) technicianStatusColors(TechnicianStatus status) => _statusColor(status);

(Color, Color) _statusColor(TechnicianStatus status) {
  return switch (status) {
    TechnicianStatus.available => (AppColors.successMuted, AppColors.success),
    TechnicianStatus.assigned => (AppColors.primaryMuted, AppColors.primary),
    TechnicianStatus.onTheWay || TechnicianStatus.driving => (AppColors.warningMuted, AppColors.warning),
    TechnicianStatus.onJob => (AppColors.primaryMuted, AppColors.primary),
    TechnicianStatus.offDuty => (AppColors.surfaceHover, AppColors.textSecondary),
  };
}
