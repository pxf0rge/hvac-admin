import 'package:flutter/material.dart';
import 'package:hvac_admin/design_system/tokens/tokens.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.foreground,
    this.background,
  });

  final String label;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? AppColors.surfaceHover,
        borderRadius: AppRadii.smAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: foreground ?? AppColors.textSecondary,
        ),
      ),
    );
  }
}
