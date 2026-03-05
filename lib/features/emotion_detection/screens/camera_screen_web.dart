import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Stub CameraScreen shown on web platform.
///
/// The camera + hand-landmark detection pipeline relies on native JNI
/// (Android / iOS only) and cannot run in a browser. This stub prevents
/// the `dart:ffi` compile error on web.
class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off_rounded, size: 72, color: Colors.grey),
              SizedBox(height: 24),
              Text(
                'Fitur Kamera Tidak Tersedia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Deteksi BISINDO membutuhkan kamera native '
                'yang hanya tersedia di aplikasi Android / iOS.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
