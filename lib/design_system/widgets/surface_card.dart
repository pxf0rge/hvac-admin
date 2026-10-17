import 'package:flutter/material.dart';
import 'package:hvac_admin/design_system/tokens/tokens.dart';

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpacing.lg)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      // Material ancestor so ListTiles/ink wells inside cards paint their
      // splashes on this surface instead of warning about the DecoratedBox.
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}
