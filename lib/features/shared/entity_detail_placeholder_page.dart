import 'package:flutter/material.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/design_system/design_system.dart';

class EntityDetailPlaceholderPage extends StatelessWidget {
  const EntityDetailPlaceholderPage({
    super.key,
    required this.title,
    required this.entityId,
    this.module,
  });

  final String title;
  final String entityId;
  final AdminModule? module;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: EmptyState(
        icon: module?.icon ?? Icons.description_outlined,
        title: '$title detail',
        message: 'ID: $entityId\nFull $title screens arrive in a later phase.',
      ),
    );
  }
}
