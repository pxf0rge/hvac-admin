import 'package:flutter/material.dart';
import 'package:hvac_admin/design_system/tokens/tokens.dart';

/// Arctic HVAC app mark: a glacier-gradient rounded tile with a snowflake.
///
/// Pure visual identity element — the *company* name/logo shown next to it is
/// user-supplied via `company_settings` and never faked here.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 40, this.radius});

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryStrong],
        ),
        borderRadius: BorderRadius.circular(radius ?? size * 0.24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Icon(
        Icons.ac_unit_rounded,
        color: Colors.white,
        size: size * 0.58,
      ),
    );
  }
}
