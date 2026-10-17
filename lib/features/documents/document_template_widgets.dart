import 'package:flutter/material.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/design_system/design_system.dart';

class TemplateStatusChip extends StatelessWidget {
  const TemplateStatusChip({super.key, required this.status});

  final DocumentTemplateStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      DocumentTemplateStatus.active => (AppColors.successMuted, AppColors.success),
      DocumentTemplateStatus.draft => (AppColors.warningMuted, AppColors.warning),
      DocumentTemplateStatus.archived => (AppColors.surfaceHover, AppColors.textMuted),
    };
    return StatusChip(label: status.label, background: colors.$1, foreground: colors.$2);
  }
}
