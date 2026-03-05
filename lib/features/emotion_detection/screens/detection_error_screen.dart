import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/responsive_helper.dart';

/// Tipe error deteksi emosi.
enum DetectionErrorType { faceNotDetected, handNotDetected, apiError }

/// Screen yang ditampilkan ketika deteksi emosi gagal.
class DetectionErrorScreen extends StatelessWidget {
  const DetectionErrorScreen({super.key, required this.errorType});

  final DetectionErrorType errorType;

  String get _title => 'Deteksi Gagal';

  String get _message {
    switch (errorType) {
      case DetectionErrorType.faceNotDetected:
        return 'Wajah tidak terdeteksi. Pastikan wajahmu terlihat jelas oleh kamera.';
      case DetectionErrorType.handNotDetected:
        return 'Gerakan isyarat tidak terdeteksi. Pastikan tanganmu terlihat jelas.';
      case DetectionErrorType.apiError:
        return 'Terjadi kesalahan saat menganalisis. Silakan coba lagi.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final cimoSize = r.img(180);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: r.w(32)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cimo sedih
                SizedBox(
                  width: cimoSize,
                  height: cimoSize,
                  child: Image.asset(AssetPaths.cimoSad, fit: BoxFit.contain),
                ),
                SizedBox(height: r.h(32)),

                // Judul
                Text(
                  _title,
                  style: TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: r.sp(20),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: r.h(16)),

                // Pesan error
                Text(
                  _message,
                  style: TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: r.sp(14),
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: r.h(40)),

                // Tombol "Coba Lagi"
                SizedBox(
                  width: double.infinity,
                  height: r.h(50),
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.camera),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF41B37E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(25))),
                      elevation: 0,
                    ),
                    child: Text(
                      'Coba Lagi',
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: r.sp(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: r.h(12)),

                // Tombol "Chat Tanpa Kamera"
                SizedBox(
                  width: double.infinity,
                  height: r.h(50),
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.chat),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF41B37E),
                      side: const BorderSide(color: Color(0xFF41B37E), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(25))),
                    ),
                    child: Text(
                      'Chat Tanpa Kamera',
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: r.sp(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

