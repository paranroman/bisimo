import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import 'qr_scanner_screen.dart';

/// Sign In Screen - User login page with tabs for Guru/Wali and Murid
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tokenController = TextEditingController();

  // State
  late TabController _tabController;
  bool _obscurePassword = true;
  bool _isLoading = false;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleTeacherSignIn() async {
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signIn(_emailController.text, _passwordController.text);

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        if (authProvider.needsProfileData) {
          context.go(AppRoutes.profileData);
        } else {
          context.go(AppRoutes.waliDashboard);
        }
      }
    } else {
      _showSnackBar(authProvider.errorMessage ?? 'Login gagal');
    }
  }

  void _handleStudentSignIn() async {
    final token = _tokenController.text.trim();

    if (token.isEmpty) {
      _showSnackBar('Masukkan kode token terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    // Use AuthProvider for proper state management
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInAsStudent(token);

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        _showSnackBar('Selamat datang, ${authProvider.displayName}!');
        // Student goes to Home
        context.go(AppRoutes.home);
      }
    } else {
      _showSnackBar(authProvider.errorMessage ?? 'Token tidak valid');
    }
  }

  void _openQRScanner() async {
    final scannedToken = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QRScannerScreen()));

    if (scannedToken != null && scannedToken.isNotEmpty) {
      _tokenController.text = scannedToken;
      // Auto-login after scan
      _handleStudentSignIn();
    }
  }

  /// Pick a QR code image from gallery and decode the token
  void _pickQRFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final controller = MobileScannerController();
      try {
        final result = await controller.analyzeImage(pickedFile.path);

        final barcodes = result?.barcodes ?? [];
        if (barcodes.isEmpty) {
          if (mounted) _showSnackBar('QR Code tidak ditemukan pada gambar');
          return;
        }

        for (final barcode in barcodes) {
          final code = barcode.rawValue;
          if (code != null) {
            final normalized = code.trim().toUpperCase().replaceAll('-', '');
            if (normalized.length == 6 && RegExp(r'^[A-Z0-9]{6}$').hasMatch(normalized)) {
              final formattedCode = '${normalized.substring(0, 3)}-${normalized.substring(3)}';
              _tokenController.text = formattedCode;
              _handleStudentSignIn();
              return;
            }
          }
        }
        if (mounted) _showSnackBar('QR Code tidak berisi token yang valid');
      } finally {
        controller.dispose();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Gagal membaca gambar QR. Coba lagi.');
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: AppFonts.sfProRounded)),
        backgroundColor: isSuccess ? AppColors.primary : AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Image with Cimo
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
                      const SizedBox(height: AppSizes.spaceL),

                      // Tab Bar
                      _buildTabBar(),
                      const SizedBox(height: AppSizes.spaceL),

                      // Tab Content
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _currentTabIndex == 0
                            ? _buildTeacherLoginForm()
                            : _buildStudentLoginForm(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24),
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: _currentTabIndex == 0 ? AppColors.primary : const Color(0xFF41B37E),
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontFamily: AppFonts.sfProRounded,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: AppFonts.sfProRounded,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.school, size: 18), SizedBox(width: 8), Text('Guru/Wali')],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.child_care, size: 18), SizedBox(width: 8), Text('Murid')],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherLoginForm() {
    return Column(
      key: const ValueKey('teacher'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              ? const CircularProgressIndicator(color: AppColors.primary)
              : PrimaryButton.masuk(
                  onPressed: _handleTeacherSignIn,
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
    );
  }

  Widget _buildStudentLoginForm() {
    return Column(
      key: const ValueKey('student'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Friendly instruction
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          decoration: BoxDecoration(
            color: const Color(0xFF41B37E).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: const Row(
            children: [
              Text('👋', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hai! Minta kode token dari guru atau wali kelasmu ya!',
                  style: TextStyle(
                    fontFamily: AppFonts.sfProRounded,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.spaceL),

        // Token Input
        _buildLabel('Kode Token'),
        const SizedBox(height: AppSizes.spaceS),
        _buildTokenField(),
        const SizedBox(height: AppSizes.spaceL),

        // OR divider
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.textHint)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
              child: Text(
                'atau',
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.textHint)),
          ],
        ),
        const SizedBox(height: AppSizes.spaceL),

        // QR Scan Button (child-friendly, big button)
        _buildScanQRButton(),
        const SizedBox(height: AppSizes.spaceM),

        // Upload QR from Gallery button
        _buildGalleryQRButton(),
        const SizedBox(height: AppSizes.spaceXL),

        // Masuk Button
        Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Color(0xFF41B37E))
              : _buildStudentSignInButton(),
        ),
        const SizedBox(height: AppSizes.spaceXL),
      ],
    );
  }

  Widget _buildTokenField() {
    return TextField(
      controller: _tokenController,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        UpperCaseTextFormatter(),
        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-]')),
        LengthLimitingTextInputFormatter(7), // XXX-XXX
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: AppFonts.sfProRounded,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 4,
      ),
      decoration: InputDecoration(
        hintText: 'ABC-123',
        hintStyle: TextStyle(
          fontFamily: AppFonts.sfProRounded,
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: AppColors.textHint.withValues(alpha: 0.5),
          letterSpacing: 4,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL,
          vertical: AppSizes.paddingL,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: BorderSide(color: const Color(0xFF41B37E).withValues(alpha: 0.3), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: Color(0xFF41B37E), width: 3),
        ),
        filled: true,
        fillColor: const Color(0xFF41B37E).withValues(alpha: 0.06),
      ),
    );
  }

  Widget _buildScanQRButton() {
    return InkWell(
      onTap: _openQRScanner,
      borderRadius: BorderRadius.circular(AppSizes.radiusL),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL,
          vertical: AppSizes.paddingL,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(color: const Color(0xFF41B37E), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF41B37E).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF41B37E).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, size: 32, color: Color(0xFF41B37E)),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan QR Code',
                  style: TextStyle(
                    fontFamily: AppFonts.sfProRounded,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF41B37E),
                  ),
                ),
                Text(
                  'Arahkan kamera ke kode QR',
                  style: TextStyle(
                    fontFamily: AppFonts.sfProRounded,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF41B37E), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryQRButton() {
    return InkWell(
      onTap: _pickQRFromGallery,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingM,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_rounded, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              'Upload QR dari Galeri',
              style: TextStyle(
                fontFamily: AppFonts.sfProRounded,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSignInButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width - (AppSizes.paddingL * 2),
      height: 60,
      child: Stack(
        children: [
          // Shadow layer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF2D7D58),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          // Main button
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _handleStudentSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF41B37E),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded, size: 24, color: Colors.black),
                    SizedBox(width: 12),
                    Text(
                      'Masuk',
                      style: TextStyle(
                        fontFamily: AppFonts.sfProRounded,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Text input formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}
