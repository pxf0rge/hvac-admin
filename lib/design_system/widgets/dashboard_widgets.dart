import 'package:flutter/material.dart';
import 'package:hvac_admin/design_system/tokens/tokens.dart';
import 'package:hvac_admin/design_system/widgets/surface_card.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTypography.titleLarge)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(color: valueColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.bodySmall),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}
