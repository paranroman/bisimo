import 'package:flutter/material.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/responsive_helper.dart';

/// Emotion detection button with sparkle icon
/// Green button with 3D shadow effect
class EmotionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const EmotionButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    const buttonColor = Color(0xFF41B37E);
    const shadowColor = Color(0xFF2D7D58);
    final buttonHeight = r.h(70);
    final shadowOffset = r.h(5);

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
                borderRadius: BorderRadius.circular(r.radius(20)),
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
                  borderRadius: BorderRadius.circular(r.radius(20)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title with sparkle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Kenali emosi mu',
                          style: TextStyle(
                            fontFamily: AppFonts.nunito,
                            fontSize: r.sp(20),
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: r.w(8)),
                        // Sparkle icon
                        _buildSparkleIcon(r),
                      ],
                    ),
                    SizedBox(height: r.h(2)),
                    // Subtitle
                    Text(
                      'Bercerita kepada kamera dengan wajah dan bahasa isyarat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: r.sp(11),
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

  Widget _buildSparkleIcon(ResponsiveHelper r) {
    final sparkleSize = r.img(24);
    return CustomPaint(size: Size(sparkleSize, sparkleSize), painter: _SparklePainter());
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

