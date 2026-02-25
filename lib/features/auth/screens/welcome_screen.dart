import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/backgrounds/main_background.dart';

/// Welcome Screen - Entry point for authentication
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: MainBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Cimo Welcome Image
                SizedBox(
                  height: screenHeight * 0.28,
                  child: Image.asset(
                    AssetPaths.welcomeCimo,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_emotions,
                          size: 100,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSizes.spaceM),

                // Title
                const Text(
                  'Ekspresikan dirimu bersama Cimo',
                  style: AppTextStyles.welcomeTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spaceL),

                // Button Masuk - Large and prominent
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(AppRoutes.signIn);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF41B37E),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0xFF2D7D58).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Masuk',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

