import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/user_profile.dart';
import '../../auth/services/profile_service.dart';
import '../../../shared/widgets/navigation/app_drawer.dart';

/// Edit Profile Screen
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profileService = ProfileService();
  UserProfile? _profile;
  bool _isLoading = true;

  // Editable fields
  late TextEditingController _namaController;
  late TextEditingController _namaPanggilanController;
  DateTime? _selectedDate;
  String? _selectedGender;

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController();
    _namaPanggilanController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _namaPanggilanController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        if (profile != null) {
          _namaController.text = profile.nama;
          _namaPanggilanController.text = profile.namaPanggilan;
          _selectedDate = profile.tanggalLahir;
          _selectedGender = profile.jenisKelamin;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 10)),
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
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _saveProfile();
    }
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Jenis Kelamin',
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ..._genderOptions.map(
                (gender) => ListTile(
                  title: Text(
                    gender,
                    style: const TextStyle(fontFamily: AppFonts.sfProRounded, fontSize: 16),
                  ),
                  trailing: _selectedGender == gender
                      ? const Icon(Icons.check, color: Color(0xFF41B37E))
                      : null,
                  onTap: () {
                    setState(() => _selectedGender = gender);
                    Navigator.pop(context);
                    _saveProfile();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editNama() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _namaController.text);
        return AlertDialog(
          title: const Text(
            'Edit Nama',
            style: TextStyle(fontFamily: AppFonts.sfProRounded, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(fontFamily: AppFonts.sfProRounded),
            decoration: InputDecoration(
              hintText: 'Masukkan nama...',
              hintStyle: TextStyle(fontFamily: AppFonts.sfProRounded, color: AppColors.textHint),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF41B37E), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(fontFamily: AppFonts.sfProRounded, color: AppColors.textHint),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _namaController.text = controller.text);
                Navigator.pop(context);
                _saveProfile();
              },
              child: const Text(
                'Simpan',
                style: TextStyle(fontFamily: AppFonts.sfProRounded, color: Color(0xFF41B37E)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editNamaPanggilan() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _namaPanggilanController.text);
        return AlertDialog(
          title: const Text(
            'Edit Nama Panggilan',
            style: TextStyle(fontFamily: AppFonts.sfProRounded, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(fontFamily: AppFonts.sfProRounded),
            decoration: InputDecoration(
              hintText: 'Masukkan nama panggilan...',
              hintStyle: TextStyle(fontFamily: AppFonts.sfProRounded, color: AppColors.textHint),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF41B37E), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(fontFamily: AppFonts.sfProRounded, color: AppColors.textHint),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _namaPanggilanController.text = controller.text);
                Navigator.pop(context);
                _saveProfile();
              },
              child: const Text(
                'Simpan',
                style: TextStyle(fontFamily: AppFonts.sfProRounded, color: Color(0xFF41B37E)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_profile != null && _selectedDate != null && _selectedGender != null) {
      final updatedProfile = UserProfile(
        uid: _profile!.uid,
        nama: _namaController.text,
        namaPanggilan: _namaPanggilanController.text,
        tanggalLahir: _selectedDate!,
        jenisKelamin: _selectedGender!,
        tingkatPendidikan: _profile!.tingkatPendidikan,
        namaOrangTua: _profile!.namaOrangTua,
        kontakOrangTua: _profile!.kontakOrangTua,
        email: _profile!.email,
      );
      await _profileService.saveProfile(updatedProfile);
      setState(() => _profile = updatedProfile);
    }
  }

  int _calculateAge() {
    if (_selectedDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    if (now.month < _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            fontFamily: AppFonts.sfProRounded,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.editProfile),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image - fill entire screen
          Image.asset(
            AssetPaths.profilBackground,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.bottomCenter,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: Colors.white);
            },
          ),

          // Content
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF41B37E)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      // Cimo Avatar
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFBD30),
                          border: Border.all(color: const Color(0xFFFFD859), width: 8),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.asset(AssetPaths.cimoJoy, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Profile Fields
                      _buildProfileField(
                        label: 'Nama',
                        value: _namaController.text.isNotEmpty
                            ? _namaController.text
                            : 'Belum diisi',
                        icon: Icons.edit_outlined,
                        onTap: _editNama,
                      ),
                      _buildProfileField(
                        label: 'Nama Panggilan',
                        value: _namaPanggilanController.text.isNotEmpty
                            ? _namaPanggilanController.text
                            : 'Belum diisi',
                        icon: Icons.edit_outlined,
                        onTap: _editNamaPanggilan,
                      ),
                      _buildProfileField(
                        label: 'Tanggal Lahir',
                        value: _selectedDate != null
                            ? DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate!)
                            : 'Belum memasukkan Tanggal',
                        icon: Icons.calendar_today_outlined,
                        onTap: _selectDate,
                      ),
                      _buildProfileField(
                        label: 'Jenis Kelamin',
                        value: _selectedGender ?? 'Belum dipilih',
                        icon: Icons.keyboard_arrow_down,
                        onTap: _showGenderPicker,
                      ),
                      _buildProfileField(
                        label: 'Usia',
                        value: _selectedDate != null ? '${_calculateAge()} Tahun' : '-',
                        showDivider: false,
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    IconData? icon,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.sfProRounded,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppFonts.sfProRounded,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: value.contains('Belum') ? AppColors.textHint : AppColors.textPrimary,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
