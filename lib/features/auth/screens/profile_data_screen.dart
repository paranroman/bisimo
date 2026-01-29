import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../data/models/user_profile.dart';
import '../services/profile_service.dart';

/// Profile Data Screen - User fills personal information after registration
class ProfileDataScreen extends StatefulWidget {
  const ProfileDataScreen({super.key});

  @override
  State<ProfileDataScreen> createState() => _ProfileDataScreenState();
}

class _ProfileDataScreenState extends State<ProfileDataScreen> {
  final _namaController = TextEditingController();
  final _namaOrangTuaController = TextEditingController();
  final _kontakOrangTuaController = TextEditingController();
  final _profileService = ProfileService();

  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedEducation;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _educationOptions = ['SD', 'SMP', 'SMA'];

  @override
  void dispose() {
    _namaController.dispose();
    _namaOrangTuaController.dispose();
    _kontakOrangTuaController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF41B37E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF41B37E)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleSubmit() async {
    // Validate form
    if (_namaController.text.trim().isEmpty) {
      _showSnackBar('Nama tidak boleh kosong');
      return;
    }
    if (_selectedDate == null) {
      _showSnackBar('Tanggal lahir harus diisi');
      return;
    }
    if (_selectedGender == null) {
      _showSnackBar('Jenis kelamin harus dipilih');
      return;
    }
    if (_selectedEducation == null) {
      _showSnackBar('Tingkat pendidikan harus dipilih');
      return;
    }
    if (_namaOrangTuaController.text.trim().isEmpty) {
      _showSnackBar('Nama orang tua/wali tidak boleh kosong');
      return;
    }
    if (_kontakOrangTuaController.text.trim().isEmpty) {
      _showSnackBar('Kontak orang tua/wali tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);

    // Create profile
    final profile = UserProfile(
      nama: _namaController.text.trim(),
      tanggalLahir: _selectedDate!,
      jenisKelamin: _selectedGender!,
      tingkatPendidikan: _selectedEducation!,
      namaOrangTua: _namaOrangTuaController.text.trim(),
      kontakOrangTua: _kontakOrangTuaController.text.trim(),
    );

    // Save profile locally
    await _profileService.saveProfile(profile);

    setState(() => _isLoading = false);

    if (mounted) {
      _showSnackBar('Data berhasil disimpan!');
      context.go(AppRoutes.home);
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
                    'Lengkapi Data Diri',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProRounded,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Data ini akan digunakan untuk profil anak',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProRounded,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textHint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spaceXL),

                  // Nama Field
                  _buildLabel('Nama Anak'),
                  const SizedBox(height: AppSizes.spaceS),
                  _buildTextField(
                    controller: _namaController,
                    hintText: 'Masukkan nama lengkap...',
                  ),
                  const SizedBox(height: AppSizes.spaceM),

                  // Tanggal Lahir Field
                  _buildLabel('Tanggal Lahir'),
                  const SizedBox(height: AppSizes.spaceS),
                  _buildDatePicker(),
                  const SizedBox(height: AppSizes.spaceM),

                  // Jenis Kelamin Field
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
                  const SizedBox(height: AppSizes.spaceM),

                  // Tingkat Pendidikan Field
                  _buildLabel('Tingkat Pendidikan'),
                  const SizedBox(height: AppSizes.spaceS),
                  _buildDropdown(
                    value: _selectedEducation,
                    items: _educationOptions,
                    hint: 'Pilih tingkat pendidikan',
                    onChanged: (value) {
                      setState(() => _selectedEducation = value);
                    },
                  ),
                  const SizedBox(height: AppSizes.spaceL),

                  // Divider with title
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.textHint)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Data Orang Tua/Wali',
                          style: TextStyle(
                            fontFamily: AppFonts.sfProRounded,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.textHint)),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spaceM),

                  // Nama Orang Tua/Wali Field
                  _buildLabel('Nama Orang Tua/Wali'),
                  const SizedBox(height: AppSizes.spaceS),
                  _buildTextField(
                    controller: _namaOrangTuaController,
                    hintText: 'Masukkan nama orang tua/wali...',
                  ),
                  const SizedBox(height: AppSizes.spaceM),

                  // Kontak Orang Tua/Wali Field
                  _buildLabel('Kontak Orang Tua/Wali'),
                  const SizedBox(height: AppSizes.spaceS),
                  _buildTextField(
                    controller: _kontakOrangTuaController,
                    hintText: 'Masukkan nomor telepon...',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSizes.spaceXL),

                  // Submit Button
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingM,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedDate != null
                    ? DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate!)
                    : 'Pilih tanggal lahir...',
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _selectedDate != null ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ),
            Icon(Icons.calendar_today, color: AppColors.textHint, size: 20),
          ],
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
              fontFamily: AppFonts.sfProRounded,
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
                  fontFamily: AppFonts.sfProRounded,
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
