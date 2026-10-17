import 'package:flutter/material.dart';
import 'package:hvac_admin/design_system/tokens/tokens.dart';
import 'package:hvac_admin/design_system/widgets/app_loading_dots.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const AppLoadingDots()
        : icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(label),
                ],
              );
    final button = FilledButton(onPressed: isLoading ? null : onPressed, child: child);
    if (expanded) return SizedBox(width: double.infinity, child: button);
    return button;
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expanded = false,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? AppLoadingDots(color: Theme.of(context).colorScheme.primary)
        : icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(label),
                ],
              );
    final button = OutlinedButton(onPressed: isLoading ? null : onPressed, child: child);
    if (expanded) return SizedBox(width: double.infinity, child: button);
    return button;
  }
}

class AppTextAction extends StatelessWidget {
  const AppTextAction({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}
