import 'package:flutter/material.dart';
import '../../../core/constants/app_fonts.dart';

/// Reusable Primary Button with 3D shadow effect
/// Used throughout the app for consistent button styling
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color? shadowColor;
  final double width;
  final double height;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final Widget? prefixIcon;
  final double shadowOffset;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.shadowColor,
    this.width = 200,
    this.height = 56,
    this.borderRadius = 30,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w700,
    this.prefixIcon,
    this.shadowOffset = 4,
  });

  /// Primary green button (Masuk)
  factory PrimaryButton.masuk({
    required VoidCallback? onPressed,
    double width = 200,
    double height = 56,
  }) {
    return PrimaryButton(
      text: 'Masuk',
      onPressed: onPressed,
      backgroundColor: const Color(0xFF41B37E),
      textColor: Colors.black,
      shadowColor: const Color(0xFF2D7D58),
      width: width,
      height: height,
    );
  }

  /// Google sign-in button
  factory PrimaryButton.google({
    required VoidCallback? onPressed,
    required Widget prefixIcon,
    double width = 240,
    double height = 52,
  }) {
    return PrimaryButton(
      text: 'Lanjut dengan Google',
      onPressed: onPressed,
      backgroundColor: const Color(0xFFDDFFEF),
      textColor: const Color(0xFF1A1A1A),
      shadowColor: const Color(0xFFB5D4C5),
      width: width,
      height: height,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      prefixIcon: prefixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveShadowColor = shadowColor ?? _darkenColor(backgroundColor, 0.3);

    return SizedBox(
      width: width,
      height: height + shadowOffset,
      child: Stack(
        children: [
          // Shadow/3D effect layer (behind)
          Positioned(
            top: shadowOffset,
            left: 0,
            right: 0,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: effectiveShadowColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
          // Main button layer (front)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: onPressed,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Center(
                  child: prefixIcon != null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            prefixIcon!,
                            const SizedBox(width: 12),
                            Text(
                              text,
                              style: TextStyle(
                                fontFamily: AppFonts.nunito,
                                fontSize: fontSize,
                                fontWeight: fontWeight,
                                color: textColor,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          text,
                          style: TextStyle(
                            fontFamily: AppFonts.nunito,
                            fontSize: fontSize,
                            fontWeight: fontWeight,
                            color: textColor,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Darkens a color by a given amount (0.0 - 1.0)
  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }
}

