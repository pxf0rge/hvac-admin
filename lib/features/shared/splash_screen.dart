import 'package:flutter/material.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';

/// Branded boot splash. Shown while the app restores the office session; the
/// router then continues automatically to the dashboard (session restored) or
/// the login screen — the user never sees an intermediate login flash.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('splash-screen'),
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppBrandMark(size: 76, radius: 20),
            const SizedBox(height: AppSpacing.lg),
            Text(adminStrings(context).appTitle, style: AppTypography.headlineLarge),
            const SizedBox(height: AppSpacing.xxl),
            const _SplashDots(),
          ],
        ),
      ),
    );
  }
}

/// Static dots (no animation) so widget tests can `pumpAndSettle` through boot.
class _SplashDots extends StatelessWidget {
  const _SplashDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, opacity) in const [1.0, 0.6, 0.3].indexed)
          Padding(
            padding: EdgeInsets.only(right: index < 2 ? 6 : 0),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
            ),
          ),
      ],
    );
  }
}
