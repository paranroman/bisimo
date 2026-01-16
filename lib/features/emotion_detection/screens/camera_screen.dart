import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';

/// Camera Screen - Emotion Detection via Camera
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Find front camera
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _onSendPressed() {
    // Navigate to loading screen
    context.push(AppRoutes.emotionDetection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Deteksi Emosional',
          style: TextStyle(
            fontFamily: AppFonts.sfProRounded,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;

          final circleSize = screenWidth * 0.55; // Ukuran lingkaran
          final circleLeft = -(circleSize * 0.25); // Posisi kiri
          final circleBottom = -(circleSize * 0.4); // Posisi bawah

          final cimoSize = screenWidth * 0.4; // Ukuran Cimo
          final cimoLeft = 1.0; // Posisi kiri 
          final cimoBottom = 10.0; // Posisi bawah 

          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  color: Colors.white,
                  child: _isCameraInitialized && _cameraController != null
                      ? CameraPreview(_cameraController!)
                      : const Center(child: CircularProgressIndicator(color: Color(0xFF41B37E))),
                ),
              ),

              // Yellow circle background 
              Positioned(
                left: circleLeft,
                bottom: circleBottom,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFBD30)),
                ),
              ),

              // Cimo
              Positioned(
                left: cimoLeft,
                bottom: cimoBottom,
                child: SizedBox(
                  width: cimoSize,
                  height: cimoSize,
                  child: Image.asset(AssetPaths.cimoJoy, fit: BoxFit.contain),
                ),
              ),

              // Send Button - bottom right
              Positioned(
                right: 24,
                bottom: 40,
                child: GestureDetector(
                  onTap: _onSendPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF41B37E),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D7D58),
                          offset: const Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Kirim',
                          style: TextStyle(
                            fontFamily: AppFonts.sfProRounded,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.send, color: Colors.black, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
