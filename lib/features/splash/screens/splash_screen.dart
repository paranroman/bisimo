import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/constants/app_sizes.dart';

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
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Navigate to onboarding/welcome/home based on auth state
    // For now, just stay on splash screen
    // if (mounted) {
    //   context.go(AppRoutes.welcome);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cimo Avatar Placeholder
            Container(
              width: AppSizes.cimoLarge,
              height: AppSizes.cimoLarge,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  AssetPaths.cimoJoy,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.emoji_emotions, size: 80, color: AppColors.primary);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spaceL),

            // App Name
            Text(
              AppStrings.appName,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnPrimary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSizes.spaceS),

            // Tagline
            Text(
              AppStrings.appTagline,
              style: TextStyle(fontSize: 16, color: AppColors.textOnPrimary.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: AppSizes.spaceXXL),

            // Loading Indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.textOnPrimary.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
