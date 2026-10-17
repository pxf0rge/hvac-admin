import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/design_system/design_system.dart';

class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.lock_outline,
      title: 'Access denied',
      message: 'You do not have permission to view this module.',
      action: AppPrimaryButton(
        label: 'Back to dashboard',
        onPressed: () => context.go('/dashboard'),
      ),
    );
  }
}
