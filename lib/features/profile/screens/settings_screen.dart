import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/navigation/app_drawer.dart';

/// Settings Screen - Pengaturan
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openFeedback(BuildContext context) async {
    const email = 'bisimousu@gmail.com';
    const subject = 'Masukan untuk Aplikasi Bisimo';
    const body = 'Halo Tim Bisimo,\n\nSaya ingin memberikan masukan:\n\n';

    final Uri emailUri = Uri.parse(
      'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      // Langsung launch tanpa cek canLaunchUrl
      final launched = await launchUrl(emailUri, mode: LaunchMode.externalApplication);

      if (!launched && context.mounted) {
        _showEmailFallback(context, email);
      }
    } catch (e) {
      if (context.mounted) {
        _showEmailFallback(context, email);
      }
    }
  }

  void _showEmailFallback(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Kirim Masukan',
          style: TextStyle(fontFamily: AppFonts.nunito, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kirim email ke:', style: TextStyle(fontFamily: AppFonts.nunito)),
            const SizedBox(height: 8),
            SelectableText(
              email,
              style: const TextStyle(
                fontFamily: AppFonts.nunito,
                fontWeight: FontWeight.w700,
                color: Color(0xFF41B37E),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: email));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email disalin ke clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Salin Email',
              style: TextStyle(fontFamily: AppFonts.nunito, color: Color(0xFF41B37E)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(fontFamily: AppFonts.nunito, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
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
            fontFamily: AppFonts.nunito,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.settings),
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
                    fontFamily: AppFonts.nunito,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bisimo adalah Aplikasi mendeteksi emosional anak-anak tunarungu dari Bahasa Isyarat Bisindo serta mimik wajah anak.',
                  style: TextStyle(
                    fontFamily: AppFonts.nunito,
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
                    onTap: () => _openFeedback(context),
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
                          fontFamily: AppFonts.nunito,
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

