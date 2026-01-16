import 'package:flutter/material.dart';

/// Bisimo App Color Palette
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF4A90D9);
  static const Color primaryLight = Color(0xFF7AB3E8);
  static const Color primaryDark = Color(0xFF2E6BB5);

  // Secondary Colors
  static const Color secondary = Color(0xFFFFA726);
  static const Color secondaryLight = Color(0xFFFFCC80);
  static const Color secondaryDark = Color(0xFFF57C00);

  // Background Colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFFE8ECF0);
  static const Color surface = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFFB2BEC3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Emotion Colors (untuk indikator emosi Cimo)
  static const Color emotionJoy = Color(0xFFFFD93D);
  static const Color emotionSad = Color(0xFF6C9BCF);
  static const Color emotionAngry = Color(0xFFE74C3C);
  static const Color emotionFear = Color(0xFF9B59B6);
  static const Color emotionSurprise = Color(0xFFFF9F43);
  static const Color emotionDisgust = Color(0xFF2ECC71);
  static const Color emotionNeutral = Color(0xFF95A5A6);

  // Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);

  // Border & Divider
  static const Color border = Color(0xFFDFE6E9);
  static const Color divider = Color(0xFFECF0F1);

  // Shadow
  static const Color shadow = Color(0x1A000000);

  // Gradient Colors
  static const List<Color> primaryGradient = [Color(0xFF4A90D9), Color(0xFF7AB3E8)];

  static const List<Color> backgroundGradient = [Color(0xFFF5F7FA), Color(0xFFE8ECF0)];
}
