import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';
import '../services/emotion_api_service.dart';

/// Loading Screen — Memanggil cloud API (face + motion) selama animasi loading,
/// lalu navigasi ke ChatScreen dengan hasil emosi.
class EmotionLoadingScreen extends StatefulWidget {
  const EmotionLoadingScreen({super.key, this.faceImageBytes, this.motionSequence});

  /// JPEG bytes foto wajah 224×224 (dari CameraScreen).
  final Uint8List? faceImageBytes;

  /// Motion sequence 60×154 (sudah di-interpolasi dari CameraScreen).
  final List<List<double>>? motionSequence;

  @override
  State<EmotionLoadingScreen> createState() => _EmotionLoadingScreenState();
}

class _EmotionLoadingScreenState extends State<EmotionLoadingScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _dotsController;
  int _dotCount = 0;

  final EmotionApiService _emotionApi = EmotionApiService();

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
            _dotCount = (_dotCount + 1) % 4;
          });
          _dotsController.forward(from: 0);
        }
      });
    _dotsController.forward();

    // ── Panggil cloud API & navigasi ke chat setelah selesai ──────────
    _detectAndNavigate();
  }

  /// Panggil cloud API untuk face + motion secara paralel,
  /// tunggu minimal 2 detik (agar animasi tetap terlihat),
  /// lalu navigasi ke ChatScreen dengan hasil emosi.
  Future<void> _detectAndNavigate() async {
    final stopwatch = Stopwatch()..start();

    MultimodalEmotionResult emotionResult;

    try {
      // ── Panggil kedua API secara paralel ──────────────────────────
      final futures = await Future.wait([_detectFace(), _detectMotion()]);

      final faceEmotion = futures[0] as EmotionResult?;
      final motionEmotion = futures[1] as EmotionResult?;

      // ── Gabungkan hasil — weighted fusion lokal (70% face + 30% motion) ─
      emotionResult = MultimodalEmotionResult.fusionLocal(
        faceEmotion: faceEmotion,
        motionEmotion: motionEmotion,
      );

      debugPrint('[EmotionLoading] ✅ Emotion result: $emotionResult');
    } catch (e) {
      debugPrint('[EmotionLoading] ❌ API error: $e');
      // Fallback → Neutral
      emotionResult = MultimodalEmotionResult(
        finalEmotion: EmotionResult(emotion: 'Neutral', confidence: 0.0),
      );
    }

    // ── Pastikan animasi loading tampil minimal 2 detik ──────────────
    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 2000) {
      await Future.delayed(Duration(milliseconds: 2000 - elapsed));
    }

    // ── Navigasi ke ChatScreen dengan data emosi ─────────────────────
    if (mounted) {
      context.go(
        AppRoutes.chat,
        extra: <String, dynamic>{
          'finalEmotion': emotionResult.finalEmotion.emotion,
          'finalConfidence': emotionResult.finalEmotion.confidence,
        },
      );
    }
  }
  // ...existing code...

  /// Panggil cloud BiLSTM untuk deteksi emosi dari isyarat BISINDO.
  Future<EmotionResult?> _detectMotion() async {
    if (widget.motionSequence == null) return null;
    try {
      return await _emotionApi.detectMotionEmotion(widget.motionSequence!);
    } catch (e) {
      debugPrint('[EmotionLoading] Motion API error: $e');
      return null;
    }
  }

  /// Panggil cloud API untuk deteksi emosi dari wajah.
  Future<EmotionResult?> _detectFace() async {
    if (widget.faceImageBytes == null) return null;
    try {
      return await _emotionApi.detectFaceEmotion(widget.faceImageBytes!);
    } catch (e) {
      debugPrint('[EmotionLoading] Face API error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _dotsController.dispose();
    _emotionApi.dispose();
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
        ..color = const Color(0xFFFFD859).withValues(alpha: opacity)
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
