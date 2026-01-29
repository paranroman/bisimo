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
import '../services/auth_service.dart';
import '../services/profile_service.dart';

/// Welcome Screen - Entry point for authentication
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _authService = AuthService();
  final _profileService = ProfileService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (result.isSuccess) {
        // Check if user has profile
        final hasProfile = await _profileService.hasProfile();

        if (!mounted) return;

        if (result.isNewUser || !hasProfile) {
          // New user - go to profile data screen
          context.go(AppRoutes.profileData);
        } else {
          // Existing user with profile - go to home
          context.go(AppRoutes.home);
        }
      } else {
        _showError(result.message ?? 'Gagal masuk dengan Google');
      }
    } catch (e) {
      if (mounted) {
        _showError('Terjadi kesalahan. Silakan coba lagi.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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

                // Button Masuk
                PrimaryButton.masuk(
                  onPressed: () {
                    context.push(AppRoutes.signIn);
                  },
                  width: 200,
                  height: 52,
                ),
                const SizedBox(height: AppSizes.spaceM),

                // Button Google Sign-In
                _isLoading
                    ? const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      )
                    : PrimaryButton.google(
                        onPressed: _handleGoogleSignIn,
                        prefixIcon: const GoogleIcon(size: 20),
                        width: 240,
                        height: 48,
                      ),
                const SizedBox(height: AppSizes.spaceL),

                // Sign Up Link
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