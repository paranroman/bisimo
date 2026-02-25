import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

/// Bisimo App Typography
class AppTextStyles {
  AppTextStyles._();

  // ============ SPECIAL FONTS ============

  /// App Name "Bisimo" - Baloo2 Bold
  static const TextStyle appName = TextStyle(
    fontFamily: AppFonts.baloo2,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// App Tagline - SF Pro Rounded Regular
  static const TextStyle appTagline = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Welcome Title - Lexend Regular
  static const TextStyle welcomeTitle = TextStyle(
    fontFamily: AppFonts.lexend,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Button Text - SF Pro Rounded Bold
  static const TextStyle buttonText = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );

  /// Link Text - SF Pro Rounded Bold
  static const TextStyle linkText = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ============ HEADINGS ============

  static const TextStyle h1 = TextStyle(
    fontFamily: AppFonts.lexend,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: AppFonts.lexend,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: AppFonts.lexend,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: AppFonts.lexend,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h5 = TextStyle(
    fontFamily: AppFonts.lexend,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ============ BODY TEXT ============

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ============ LABELS ============

  static const TextStyle labelLarge = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ============ BUTTON ============

  static const TextStyle buttonLarge = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );

  // ============ CAPTION ============

  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
    height: 1.4,
  );

  // ============ INPUT ============

  static const TextStyle input = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle inputHint = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
    height: 1.5,
  );

  static const TextStyle inputError = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
    height: 1.4,
  );

  // ============ LINK ============

  static const TextStyle link = TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    height: 1.4,
    decoration: TextDecoration.underline,
  );
}

