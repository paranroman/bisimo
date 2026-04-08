import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../data/models/user_profile.dart';
import '../../../providers/auth_provider.dart';
import '../services/profile_service.dart';

/// Profile Data Screen - Wali fills basic profile data after registration
class ProfileDataScreen extends StatefulWidget {
  const ProfileDataScreen({super.key});

  @override
  State<ProfileDataScreen> createState() => _ProfileDataScreenState();
}

class _ProfileDataScreenState extends State<ProfileDataScreen> {
  final _namaController = TextEditingController();
  final _profileService = ProfileService();

  String? _selectedGender;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_namaController.text.trim().isEmpty) {
      _showSnackBar('Nama tidak boleh kosong');
      return;
    }
    if (_selectedGender == null) {
      _showSnackBar('Jenis kelamin harus dipilih');
      return;
    }

    setState(() => _isLoading = true);

    final nama = _namaController.text.trim();

    // Keep legacy required fields filled for backward compatibility.
    final profile = UserProfile(
      nama: nama,
      namaPanggilan: nama,
      tanggalLahir: DateTime(2000, 1, 1),
      jenisKelamin: _selectedGender!,
      tingkatPendidikan: '',
      namaOrangTua: '',
      kontakOrangTua: '',
    );

    await _profileService.saveProfile(profile);

    setState(() => _isLoading = false);

    if (mounted) {
      context.read<AuthProvider>().markProfileDataCompleted();
      _showSnackBar('Data berhasil disimpan!');
      context.go(AppRoutes.waliDashboard);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: AppFonts.nunito)),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Image
                Image.asset(
                  AssetPaths.signUpHeader,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
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
                        'Lengkapi Data Wali',
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Data ini akan digunakan untuk profil wali di dashboard',
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textHint,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.spaceXL),

                      _buildLabel('Nama'),
                      const SizedBox(height: AppSizes.spaceS),
                      _buildTextField(
                        controller: _namaController,
                        hintText: 'Masukkan nama Anda...',
                      ),
                      const SizedBox(height: AppSizes.spaceM),

                      _buildLabel('Jenis Kelamin'),
                      const SizedBox(height: AppSizes.spaceS),
                      _buildDropdown(
                        value: _selectedGender,
                        items: _genderOptions,
                        hint: 'Pilih jenis kelamin',
                        onChanged: (value) {
                          setState(() => _selectedGender = value);
                        },
                      ),
                      const SizedBox(height: AppSizes.spaceXL),

                      Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Color(0xFF41B37E))
                            : PrimaryButton(
                                text: 'Simpan',
                                onPressed: _handleSubmit,
                                backgroundColor: const Color(0xFF41B37E),
                                textColor: Colors.black,
                                shadowColor: const Color(0xFF2D7D58),
                                width: MediaQuery.of(context).size.width - (AppSizes.paddingL * 2),
                                height: 52,
                              ),
                      ),
                      const SizedBox(height: AppSizes.spaceXL),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppFonts.nunito,
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: AppFonts.nunito,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: AppFonts.nunito,
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
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textHint,
            ),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
