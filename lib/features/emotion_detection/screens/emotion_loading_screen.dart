import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';

/// Loading Screen - Shows while detecting emotion
class EmotionLoadingScreen extends StatefulWidget {
  const EmotionLoadingScreen({super.key});

  @override
  State<EmotionLoadingScreen> createState() => _EmotionLoadingScreenState();
}

class _EmotionLoadingScreenState extends State<EmotionLoadingScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _dotsController;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();

    // Wave animation controller
    _waveController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat();

    // Dots animation controller
    _dotsController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _dotCount = (_dotCount + 1) % 4; // 0, 1, 2, 3 (0 = no dots)
          });
          _dotsController.forward(from: 0);
        }
      });
    _dotsController.forward();

    // Navigate to chat after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        context.go(AppRoutes.chat);
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  String _getDotsText() {
    return '.' * _dotCount;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cimo with sonar wave background
            SizedBox(
              width: screenWidth * 0.7,
              height: screenWidth * 0.7,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _SonarWavePainter(progress: _waveController.value),
                    child: Center(
                      child: SizedBox(
                        width: screenWidth * 0.45,
                        height: screenWidth * 0.45,
                        child: Image.asset(AssetPaths.cimoJoy, fit: BoxFit.contain),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),

            // Loading text with animated dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Mendeteksi perasaanmu',
                  style: TextStyle(
                    fontFamily: AppFonts.lexend,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    _getDotsText(),
                    style: const TextStyle(
                      fontFamily: AppFonts.lexend,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for sonar wave effect on inner circle
class _SonarWavePainter extends CustomPainter {
  final double progress;

  _SonarWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.45;
    final innerRadius = size.width * 0.35;

    // Outer circle (FFBD30) - static
    final outerPaint = Paint()
      ..color = const Color(0xFFFFBD30)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, outerPaint);

    // Inner circle (FFD859) - static base
    final innerPaint = Paint()
      ..color = const Color(0xFFFFD859)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerPaint);

    // Sonar waves emanating from inner circle
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i * 0.33) % 1.0;
      final waveRadius = innerRadius + (outerRadius - innerRadius) * waveProgress;
      final opacity = (1.0 - waveProgress) * 0.6;

      final wavePaint = Paint()
        ..color = const Color(0xFFFFD859).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      canvas.drawCircle(center, waveRadius, wavePaint);
    }
  }

  @override
  bool shouldRepaint(_SonarWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
