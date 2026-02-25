import 'package:flutter/material.dart';
import '../../../core/constants/app_fonts.dart';

/// Emotion detection button with sparkle icon
/// Green button with 3D shadow effect
class EmotionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const EmotionButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    const buttonColor = Color(0xFF41B37E);
    const shadowColor = Color(0xFF2D7D58);
    const buttonHeight = 70.0;
    const shadowOffset = 5.0;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight + shadowOffset,
      child: Stack(
        children: [
          // Shadow layer
          Positioned(
            top: shadowOffset,
            left: 0,
            right: 0,
            child: Container(
              height: buttonHeight,
              decoration: BoxDecoration(
                color: shadowColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Main button layer
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: onPressed,
              child: Container(
                height: buttonHeight,
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title with sparkle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Kenali emosi mu',
                          style: TextStyle(
                            fontFamily: AppFonts.nunito,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sparkle icon
                        _buildSparkleIcon(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Subtitle
                    const Text(
                      'Bercerita kepada kamera dengan wajah dan bahasa isyarat',
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkleIcon() {
    return CustomPaint(size: const Size(24, 24), painter: _SparklePainter());
  }
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF98E4C9)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw 4-pointed star sparkle
    final path = Path();

    // Top point
    path.moveTo(centerX, 0);
    path.quadraticBezierTo(centerX + 3, centerY - 3, centerX + size.width * 0.35, centerY);

    // Right point
    path.quadraticBezierTo(centerX + 3, centerY + 3, centerX, size.height);

    // Bottom point
    path.quadraticBezierTo(centerX - 3, centerY + 3, centerX - size.width * 0.35, centerY);

    // Left point
    path.quadraticBezierTo(centerX - 3, centerY - 3, centerX, 0);

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

