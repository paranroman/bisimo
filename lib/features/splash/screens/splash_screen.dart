import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../shared/widgets/backgrounds/main_background.dart';
import '../../../providers/auth_provider.dart';

/// Splash Screen - First screen shown when app launches
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Simulate loading time
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check authentication status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      if (authProvider.isStudentMode) {
        // Student goes to Home (with Cimo)
        context.go(AppRoutes.home);
      } else if (authProvider.needsProfileData) {
        // Wali needs to complete profile first
        context.go(AppRoutes.profileData);
      } else {
        // Wali goes to Dashboard
        context.go(AppRoutes.waliDashboard);
      }
    } else {
      // Not authenticated, go to welcome
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final iconSize = r.img(120);

    return Scaffold(
      body: MainBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon - icon_bisimo.png
                Image.asset(
                  AssetPaths.iconBisimo,
                  width: iconSize,
                  height: iconSize,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA726),
                        borderRadius: BorderRadius.circular(r.radius(24)),
                      ),
                      child: Icon(Icons.emoji_emotions, size: r.img(60), color: Colors.white),
                    );
                  },
                ),
                SizedBox(height: r.h(AppSizes.spaceL)),

                // App Name - Baloo2 Bold
                Text('Bisimo', style: AppTextStyles.appName.copyWith(fontSize: r.sp(48))),
                SizedBox(height: r.h(AppSizes.spaceS)),

                // Tagline - SF Pro Rounded Regular
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.w(AppSizes.paddingXL)),
                  child: Text(
                    'Aplikasi Bahasa Isyarat Deteksi\nEmosional untuk Anak Tunarungu',
                    style: AppTextStyles.appTagline.copyWith(fontSize: r.sp(14)),
                    textAlign: TextAlign.center,
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

