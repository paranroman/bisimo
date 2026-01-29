import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../services/auth_service.dart';

/// Sign In Screen - User login page
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    // Validate form
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Email tidak boleh kosong');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showSnackBar('Password tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } else {
      _showSnackBar(result.message ?? 'Login gagal');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: AppFonts.sfProRounded)),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Image with Cimo - fit width, natural aspect ratio
            Image.asset(
              AssetPaths.signInHeader,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  child: const Center(
                    child: Icon(Icons.image, size: 80, color: AppColors.textHint),
                  ),
                );
              },
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizes.spaceL),

                  // Title
                  const Text(
                    'Masuk ke dalam Akun',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProRounded,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spaceXL),

                  // Email Field
                  _buildLabel('Email'),
                  const SizedBox(height: AppSizes.spaceS),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Masukkan email...',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSizes.spaceM),

                  // Password Field
                  _buildLabel('Password'),
                  const SizedBox(height: AppSizes.spaceS),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Masukkan password...',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textHint,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceXL),

                  // Masuk Button
                  Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF41B37E))
                        : PrimaryButton.masuk(
                            onPressed: _handleSignIn,
                            width: MediaQuery.of(context).size.width - (AppSizes.paddingL * 2),
                            height: 52,
                          ),
                  ),
                  const SizedBox(height: AppSizes.spaceL),

                  // Sign Up Link
                  Center(
                    child: GestureDetector(
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
                              text: 'Daftar akun baru.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceXL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppFonts.sfProRounded,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(
        fontFamily: AppFonts.sfProRounded,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: AppFonts.sfProRounded,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textHint,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingM,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          borderSide: const BorderSide(color: Color(0xFF41B37E), width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
