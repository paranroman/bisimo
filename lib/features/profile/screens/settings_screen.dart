import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../shared/widgets/navigation/app_drawer.dart';

/// Settings Screen - Pengaturan
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openFeedback() async {
    // Open email for feedback
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'bisimousu@gmail.com',
      queryParameters: {
        'subject': 'Masukan untuk Aplikasi Bisimo',
        'body': 'Halo Tim Bisimo,\n\nSaya ingin memberikan masukan:\n\n',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            fontFamily: AppFonts.sfProRounded,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image - fill entire screen
          Image.asset(
            AssetPaths.settingBackground,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.bottomCenter,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: Colors.white);
            },
          ),

          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                // Cimo Avatar
                Center(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFBD30),
                      border: Border.all(color: const Color(0xFFFFD859), width: 8),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.asset(AssetPaths.cimoJoy, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Tentang Kami Section
                const Text(
                  'Tentang Kami',
                  style: TextStyle(
                    fontFamily: AppFonts.sfProRounded,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bisimo adalah Aplikasi mendeteksi emosional anak-anak tunarungu dari Bahasa Isyarat Bisindo serta mimik wajah anak.',
                  style: TextStyle(
                    fontFamily: AppFonts.sfProRounded,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 30),

                // Beri Masukan Button
                Center(
                  child: GestureDetector(
                    onTap: _openFeedback,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                      child: const Text(
                        'Beri Masukan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFonts.sfProRounded,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
