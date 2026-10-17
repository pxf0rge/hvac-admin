import 'package:flutter/material.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/design_system/design_system.dart';

class ModulePlaceholderPage extends StatelessWidget {
  const ModulePlaceholderPage({super.key, required this.module});

  final AdminModule module;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: EmptyState(
        icon: module.icon,
        title: module.label,
        message: '${module.label} module arrives in a later phase.',
      ),
    );
  }
}
