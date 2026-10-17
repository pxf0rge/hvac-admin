import 'package:flutter/material.dart';
import 'package:hvac_admin/design_system/tokens/app_colors.dart';

abstract final class AppTypography {
  static const headlineLarge = TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const headlineMedium = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const titleLarge = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const titleMedium = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const bodyLarge = TextStyle(fontSize: 15, color: AppColors.textPrimary);
  static const bodyMedium = TextStyle(fontSize: 14, color: AppColors.textPrimary);
  static const bodySmall = TextStyle(fontSize: 13, color: AppColors.textSecondary);
  static const labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static const labelSmall = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted);
}
