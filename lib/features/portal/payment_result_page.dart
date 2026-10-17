import 'package:flutter/material.dart';
import 'package:hvac_admin/design_system/design_system.dart';

/// Public Stripe redirect targets (no auth).
class PaymentResultPage extends StatelessWidget {
  const PaymentResultPage({
    super.key,
    required this.success,
    this.title,
    this.message,
  });

  final bool success;
  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title ?? (success ? 'Payment received' : 'Payment cancelled');
    final resolvedMessage = message ??
        (success
            ? 'Thank you. Your invoice will update once the payment is confirmed. You can close this window.'
            : 'No charge was made. You can try again from your invoice link or contact the office.');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: SurfaceCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    success ? Icons.check_circle_outline : Icons.cancel_outlined,
                    size: 48,
                    color: success ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    resolvedTitle,
                    style: AppTypography.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    resolvedMessage,
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
