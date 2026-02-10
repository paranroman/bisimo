import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/api_provider.dart';
import '../services/emotion_api_service.dart';
import '../screens/detection_error_screen.dart';

class EmotionLoadingScreen extends StatefulWidget {
  const EmotionLoadingScreen({super.key, this.faceImageBytes, this.motionSequence});

  final Uint8List? faceImageBytes;
  final List<List<double>>? motionSequence;

  @override
  State<EmotionLoadingScreen> createState() => _EmotionLoadingScreenState();
}

class _EmotionLoadingScreenState extends State<EmotionLoadingScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _dotsController;
  int _dotCount = 0;
  bool _hasNavigated = false;

  /// Timeout: jika API tidak selesai dalam 30 detik, navigasi ke error screen.
  static const int _loadingTimeoutSeconds = 30;
  Timer? _loadingTimeoutTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = _loadingTimeoutSeconds;

  late final EmotionApiService _emotionApi;

  @override
  void initState() {
    super.initState();

    _emotionApi = context.read<ApiProvider>().emotionApi;

    _waveController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat();

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

    // Defer navigation to after the first frame to avoid
    // "setState() called during build" error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLoadingTimeout();
      _detectAndNavigate();
    });
  }

  /// Start loading timeout — jika deteksi gagal dalam _loadingTimeoutSeconds,
  /// otomatis navigasi ke error screen.
  void _startLoadingTimeout() {
    _secondsRemaining = _loadingTimeoutSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _hasNavigated) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining = _loadingTimeoutSeconds - timer.tick;
      });
    });

    _loadingTimeoutTimer = Timer(Duration(seconds: _loadingTimeoutSeconds), () {
      _countdownTimer?.cancel();
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        debugPrint('[EmotionLoading] ⏰ Timeout! Navigasi ke error screen.');
        context.go(AppRoutes.detectionError, extra: DetectionErrorType.apiError);
      }
    });
  }

  void _cancelLoadingTimeout() {
    _loadingTimeoutTimer?.cancel();
    _countdownTimer?.cancel();
  }

  Future<void> _detectAndNavigate() async {
    final stopwatch = Stopwatch()..start();

    // Validate required data — navigate to error screen if missing
    if (widget.faceImageBytes == null) {
      debugPrint('[EmotionLoading] ❌ Missing face data.');
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        _cancelLoadingTimeout();
        context.go(AppRoutes.detectionError, extra: DetectionErrorType.faceNotDetected);
      }
      return;
    }
    if (widget.motionSequence == null) {
      debugPrint('[EmotionLoading] ❌ Missing motion data.');
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        _cancelLoadingTimeout();
        context.go(AppRoutes.detectionError, extra: DetectionErrorType.handNotDetected);
      }
      return;
    }

    try {
      final CombinedEmotionResult result = await _emotionApi.detectCombinedEmotion(
        faceImageBytes: widget.faceImageBytes!,
        motionSequence: widget.motionSequence!,
      );

      debugPrint('[EmotionLoading] ✅ Combined emotion result: ${result.finalEmotion}');

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 2000) {
        await Future.delayed(Duration(milliseconds: 2000 - elapsed));
      }

      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        _cancelLoadingTimeout();
        context.go(AppRoutes.chat, extra: result);
      }
    } catch (e) {
      debugPrint('[EmotionLoading] ❌ API error: $e');
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 2000) {
        await Future.delayed(Duration(milliseconds: 2000 - elapsed));
      }
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        _cancelLoadingTimeout();
        context.go(AppRoutes.detectionError, extra: DetectionErrorType.apiError);
      }
    }
  }

  @override
  void dispose() {
    _cancelLoadingTimeout();
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
            const SizedBox(height: 12),
            Text(
              'Waktu tersisa: ${_secondsRemaining}s',
              style: TextStyle(
                fontFamily: AppFonts.lexend,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _secondsRemaining <= 10 ? Colors.red.shade400 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SonarWavePainter extends CustomPainter {
  final double progress;

  _SonarWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.45;
    final innerRadius = size.width * 0.35;

    final outerPaint = Paint()
      ..color = const Color(0xFFFFBD30)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, outerPaint);

    final innerPaint = Paint()
      ..color = const Color(0xFFFFD859)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerPaint);

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
