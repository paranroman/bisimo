import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Reusable BoxDecoration and other decorations
class AppDecorations {
  AppDecorations._();

  // Card Decoration
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
    boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
  );

  // Elevated Card Decoration
  static BoxDecoration get elevatedCard => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
    boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: const Offset(0, 4))],
  );

  // Input Field Decoration
  static BoxDecoration get inputField => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(color: AppColors.border, width: AppSizes.inputBorderWidth),
  );

  // Primary Gradient Decoration
  static BoxDecoration get primaryGradient => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: AppColors.primaryGradient,
    ),
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
  );

  // Circle Avatar Decoration
  static BoxDecoration circleAvatar({Color? color}) => BoxDecoration(
    color: color ?? AppColors.primaryLight,
    shape: BoxShape.circle,
    boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
  );

  // Bottom Sheet Decoration
  static BoxDecoration get bottomSheet => const BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(AppSizes.radiusXL),
      topRight: Radius.circular(AppSizes.radiusXL),
    ),
  );

  // Chat Bubble - User
  static BoxDecoration get chatBubbleUser => BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.only(
      topLeft: const Radius.circular(AppSizes.radiusL),
      topRight: const Radius.circular(AppSizes.radiusL),
      bottomLeft: const Radius.circular(AppSizes.radiusL),
      bottomRight: const Radius.circular(AppSizes.radiusXS),
    ),
  );

  // Chat Bubble - Cimo
  static BoxDecoration get chatBubbleCimo => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.only(
      topLeft: const Radius.circular(AppSizes.radiusL),
      topRight: const Radius.circular(AppSizes.radiusL),
      bottomLeft: const Radius.circular(AppSizes.radiusXS),
      bottomRight: const Radius.circular(AppSizes.radiusL),
    ),
    border: Border.all(color: AppColors.border, width: 1),
  );

  // Emotion Card Decoration
  static BoxDecoration emotionCard({required Color color}) => BoxDecoration(
    color: color.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
    border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
  );

  // Camera Preview Decoration
  static BoxDecoration get cameraPreview => BoxDecoration(
    color: AppColors.textPrimary,
    borderRadius: BorderRadius.circular(AppSizes.radiusL),
  );

  // Overlay Decoration
  static BoxDecoration get overlay => BoxDecoration(
    color: AppColors.textPrimary.withValues(alpha: 0.5),
    borderRadius: BorderRadius.circular(AppSizes.radiusM),
  );
}
