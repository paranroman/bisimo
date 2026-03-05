import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../shared/widgets/backgrounds/main_background.dart';

/// Welcome Screen - Entry point for authentication
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final r = ResponsiveHelper.of(context);

    return Scaffold(
      body: MainBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: r.w(AppSizes.paddingL)),
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
                      final fallbackSize = r.img(200);
                      return Container(
                        width: fallbackSize,
                        height: fallbackSize,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_emotions,
                          size: r.img(100),
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: r.h(AppSizes.spaceM)),

                // Title
                Text(
                  'Ekspresikan dirimu bersama Cimo',
                  style: AppTextStyles.welcomeTitle.copyWith(fontSize: r.sp(18)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: r.h(AppSizes.spaceL)),

                // Button Masuk - Large and prominent
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: r.h(64),
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(AppRoutes.signIn);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF41B37E),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0xFF2D7D58).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(20))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, size: r.img(28)),
                        SizedBox(width: r.w(12)),
                        Text(
                          'Masuk',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: r.sp(22),
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

