import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';
import '../../../features/auth/services/profile_service.dart';
import '../../../providers/auth_provider.dart';

/// App Drawer - Sidebar Navigation
class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isStudentMode = authProvider.isStudentMode;

    final isHome = currentRoute == AppRoutes.home;
    final isWaliDashboard = currentRoute == AppRoutes.waliDashboard;
    final isSettings = currentRoute == AppRoutes.settings;
    final isStudentProfile = currentRoute == AppRoutes.studentProfile;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AssetPaths.navigationBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and App Info
                _buildHeader(),
                const SizedBox(height: 40),

                // Menu Items - Different for Wali vs Murid
                if (isStudentMode) ...[
                  // STUDENT MENU
                  _buildMenuButton(
                    context: context,
                    label: 'Beranda',
                    backgroundColor: isHome ? const Color(0xFF41B37E) : Colors.white,
                    textColor: isHome ? Colors.white : AppColors.textPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.home);
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildMenuButton(
                    context: context,
                    label: 'Edit Profil',
                    backgroundColor: isStudentProfile ? const Color(0xFF41B37E) : Colors.white,
                    textColor: isStudentProfile ? Colors.white : AppColors.textPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.studentProfile);
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildMenuButton(
                    context: context,
                    label: 'Riwayat Deteksi',
                    subtitle: 'Akan Datang',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Fitur akan segera hadir!',
                            style: TextStyle(fontFamily: AppFonts.sfProRounded),
                          ),
                          backgroundColor: AppColors.textPrimary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    isDisabled: true,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // WALI MENU
                  _buildMenuButton(
                    context: context,
                    label: 'Dashboard',
                    backgroundColor: isWaliDashboard ? const Color(0xFF41B37E) : Colors.white,
                    textColor: isWaliDashboard ? Colors.white : AppColors.textPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.waliDashboard);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Pengaturan - same for both
                _buildMenuButton(
                  context: context,
                  label: 'Pengaturan',
                  backgroundColor: isSettings ? const Color(0xFFE5A82B) : const Color(0xFFFFBD30),
                  textColor: isSettings ? Colors.white : AppColors.textPrimary,
                  borderColor: isSettings ? const Color(0xFFB8860B) : null,
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.settings);
                  },
                ),

                const Spacer(),

                // Logout Button
                _buildLogoutButton(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Icon
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(AssetPaths.iconBisimo, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),

        // App Info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bisimo',
              style: TextStyle(
                fontFamily: AppFonts.baloo2,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Aplikasi Bahasa\nIsyarat Deteksi\nEmosional untuk\nAnak Tunarungu',
              style: TextStyle(
                fontFamily: AppFonts.sfProRounded,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String label,
    String? subtitle,
    Color backgroundColor = Colors.white,
    Color textColor = AppColors.textPrimary,
    Color? borderColor,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: borderColor ?? Colors.grey.shade300,
            width: borderColor != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.sfProRounded,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDisabled ? AppColors.textHint : textColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFFFBD30),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Get references before any async operations
        final navigator = Navigator.of(context);
        final router = GoRouter.of(context);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // Show confirmation dialog first
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(
              'Keluar dari Akun',
              style: TextStyle(fontFamily: AppFonts.sfProRounded, fontWeight: FontWeight.w700),
            ),
            content: const Text(
              'Apakah kamu yakin ingin keluar?',
              style: TextStyle(fontFamily: AppFonts.sfProRounded),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(fontFamily: AppFonts.sfProRounded, color: AppColors.textHint),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  'Keluar',
                  style: TextStyle(fontFamily: AppFonts.sfProRounded, color: Color(0xFFE57373)),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          // Close the drawer first
          navigator.pop();

          // Logout using AuthProvider (handles both Wali and Student)
          await authProvider.signOut();
          await ProfileService().clearProfile();

          // Navigate to welcome
          router.go(AppRoutes.welcome);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE57373),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'Keluar dari Akun',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.sfProRounded,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
