import 'package:flutter/material.dart';
import 'package:hvac_admin/core/errors/failure_mapper.dart';
import 'package:hvac_admin/core/errors/hvac_failure.dart';
import 'package:hvac_admin/design_system/design_system.dart';

class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.retryable = false,
  });

  factory FormErrorBanner.fromError(
    Object error, {
    Key? key,
    VoidCallback? onRetry,
  }) {
    final failure = FailureMapper.map(error);
    return FormErrorBanner(
      key: key,
      message: failure.message,
      onRetry: failure.isRetryable ? onRetry : null,
      retryable: failure.isRetryable,
    );
  }

  final String message;
  final VoidCallback? onRetry;
  final bool retryable;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
          ),
          if (retryable && onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

void showFailureSnackBar(
  BuildContext context,
  Object error, {
  VoidCallback? onRetry,
}) {
  final failure = FailureMapper.map(error);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(failure.message),
      action: failure.isRetryable && onRetry != null
          ? SnackBarAction(label: 'Retry', onPressed: onRetry)
          : null,
    ),
  );
}
