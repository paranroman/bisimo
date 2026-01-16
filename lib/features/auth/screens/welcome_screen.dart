import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/backgrounds/main_background.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/icons/google_icon.dart';

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

                // Title - Lexend Regular
                const Text(
                  'Ekspresikan dirimu bersama Cimo',
                  style: AppTextStyles.welcomeTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spaceL),

                // Masuk Button with 3D effect
                PrimaryButton.masuk(
                  onPressed: () {
                    context.push(AppRoutes.signIn);
                  },
                  width: 200,
                  height: 52,
                ),
                const SizedBox(height: AppSizes.spaceM),

                // Lanjut dengan Google Button with 3D effect
                PrimaryButton.google(
                  onPressed: () {
                    // TODO: Implement Google Sign In
                  },
                  prefixIcon: const GoogleIcon(size: 20),
                  width: 240,
                  height: 48,
                ),
                const SizedBox(height: AppSizes.spaceL),

                // Sign Up Link - SF Pro Rounded Bold
                GestureDetector(
                  onTap: () {
                    context.push(AppRoutes.signUp);
                  },
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: AppFonts.sfProRounded,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        TextSpan(text: 'Belum memiliki akun? '),
                        TextSpan(
                          text: 'Buat akun disini.',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
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
