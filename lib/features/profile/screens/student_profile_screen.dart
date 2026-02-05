import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/student_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/navigation/app_drawer.dart';
import '../../../data/repositories/student_repository.dart';

/// Student Profile Screen - Same style as teacher profile
class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _studentRepository = StudentRepository();
  final _imagePicker = ImagePicker();
  
  bool _isLoading = true;
  bool _isSaving = false;
  StudentModel? _student;
  File? _selectedImage;
  
  // Editable fields controllers
  late TextEditingController _nicknameController;
  late TextEditingController _hobbiesController;
  late TextEditingController _favoriteColorController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _hobbiesController = TextEditingController();
    _favoriteColorController = TextEditingController();
    _loadStudentData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _hobbiesController.dispose();
    _favoriteColorController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final session = authProvider.studentSession;

    if (session?.studentData != null) {
      setState(() {
        _student = session!.studentData;
        _populateFields();
        _isLoading = false;
      });
    } else {
      // No student data available
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFields() {
    if (_student != null) {
      _nicknameController.text = _student!.editableProfile.nickname ?? '';
      _hobbiesController.text = _student!.editableProfile.hobbies.join(', ');
      _favoriteColorController.text = _student!.editableProfile.favoriteColor ?? '';
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Foto Profil',
              style: TextStyle(
                fontFamily: AppFonts.sfProRounded,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF41B37E)),
              title: const Text(
                'Kamera',
                style: TextStyle(fontFamily: AppFonts.sfProRounded),
              ),
              onTap: () async {
                Navigator.pop(context);
                final image = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 75,
                );
                if (image != null) {
                  setState(() => _selectedImage = File(image.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF41B37E)),
              title: const Text(
                'Galeri',
                style: TextStyle(fontFamily: AppFonts.sfProRounded),
              ),
              onTap: () async {
                Navigator.pop(context);
                final image = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 75,
                );
                if (image != null) {
                  setState(() => _selectedImage = File(image.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_student == null) return;

    setState(() => _isSaving = true);

    try {
      // Parse hobbies from comma-separated string
      final hobbies = _hobbiesController.text
          .split(',')
          .map((h) => h.trim())
          .where((h) => h.isNotEmpty)
          .toList();

      // Create updated editable profile
      final updatedEditableProfile = EditableProfile(
        nickname: _nicknameController.text.trim().isNotEmpty 
            ? _nicknameController.text.trim() 
            : null,
        hobbies: hobbies,
        favoriteColor: _favoriteColorController.text.trim().isNotEmpty 
            ? _favoriteColorController.text.trim() 
            : null,
      );

      // Create updated student model
      final updatedStudent = _student!.copyWith(
        editableProfile: updatedEditableProfile,
      );

      // Save to Firestore
      final success = await _studentRepository.updateStudentEditableProfile(
        _student!.id,
        updatedEditableProfile,
      );

      if (mounted) {
        if (success) {
          setState(() {
            _student = updatedStudent;
          });
          _showSnackBar('Profil berhasil disimpan!', isSuccess: true);
        } else {
          _showSnackBar('Gagal menyimpan profil. Coba lagi.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: AppFonts.sfProRounded)),
        backgroundColor: isSuccess ? const Color(0xFF41B37E) : AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      drawer: const AppDrawer(currentRoute: AppRoutes.studentProfile),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF41B37E)))
          : _student == null
              ? _buildNoData()
              : _buildBody(),
    );
  }

  Widget _buildNoData() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'Data profil tidak ditemukan',
              style: TextStyle(
                fontFamily: AppFonts.sfProRounded,
                fontSize: 16,
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        Image.asset(
          AssetPaths.profilBackground,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.bottomCenter,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: const Color(0xFFFFF8E7));
          },
        ),

        // Content
        SingleChildScrollView(
          child: Column(
            children: [
              // Green Header
              _buildHeader(),

              // Profile Fields
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Locked Fields Section
                    _buildSectionTitle('Data dari Wali Kelas', Icons.lock_outline),
                    const SizedBox(height: 12),
                    _buildLockedField(
                      label: 'Nama Lengkap',
                      value: _student!.lockedProfile.fullName.isNotEmpty 
                          ? _student!.lockedProfile.fullName 
                          : '-',
                    ),
                    _buildLockedField(
                      label: 'Tanggal Lahir',
                      value: _student!.lockedProfile.birthDate != null
                          ? DateFormat('dd MMMM yyyy', 'id_ID').format(_student!.lockedProfile.birthDate!)
                          : '-',
                    ),
                    _buildLockedField(
                      label: 'Jenis Kelamin',
                      value: _student!.lockedProfile.gender != null
                          ? (_student!.lockedProfile.gender == Gender.male ? 'Laki-laki' : 'Perempuan')
                          : '-',
                      showDivider: false,
                    ),

                    const SizedBox(height: 32),

                    // Editable Fields Section
                    _buildSectionTitle('Data Pribadi', Icons.edit_outlined),
                    const SizedBox(height: 12),
                    _buildEditableField(
                      label: 'Nama Panggilan',
                      value: _nicknameController.text.isNotEmpty 
                          ? _nicknameController.text 
                          : 'Belum diisi',
                      onTap: _editNickname,
                    ),
                    _buildEditableField(
                      label: 'Hobi',
                      value: _hobbiesController.text.isNotEmpty 
                          ? _hobbiesController.text 
                          : 'Belum diisi',
                      onTap: _editHobbies,
                    ),
                    _buildEditableField(
                      label: 'Warna Favorit',
                      value: _favoriteColorController.text.isNotEmpty 
                          ? _favoriteColorController.text 
                          : 'Belum diisi',
                      onTap: _editFavoriteColor,
                      showDivider: false,
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    _buildSaveButton(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final fullName = _student?.lockedProfile.fullName ?? 'Murid';
    final nickname = _student?.editableProfile.nickname;
    final displayName = (nickname != null && nickname.isNotEmpty) ? nickname : fullName;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF41B37E), Color(0xFF2D8F5E)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Profil Saya',
                      style: TextStyle(
                        fontFamily: AppFonts.sfProRounded,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Avatar with photo picker
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFFFD859), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontFamily: AppFonts.baloo2,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF41B37E),
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Camera icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF41B37E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              displayName,
              style: const TextStyle(
                fontFamily: AppFonts.sfProRounded,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),

            if (nickname != null && nickname.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                fullName,
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF41B37E)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppFonts.sfProRounded,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLockedField({
    required String label,
    required String value,
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
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: value == '-' ? AppColors.textHint : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.lock_outline, color: AppColors.textHint, size: 18),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required VoidCallback onTap,
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
              Icon(Icons.edit_outlined, color: AppColors.textHint, size: 20),
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

  void _editNickname() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _nicknameController.text);
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
                setState(() => _nicknameController.text = controller.text);
                Navigator.pop(context);
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

  void _editHobbies() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _hobbiesController.text);
        return AlertDialog(
          title: const Text(
            'Edit Hobi',
            style: TextStyle(fontFamily: AppFonts.sfProRounded, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(fontFamily: AppFonts.sfProRounded),
                decoration: InputDecoration(
                  hintText: 'Contoh: Membaca, Bermain, Menggambar',
                  hintStyle: TextStyle(fontFamily: AppFonts.sfProRounded, color: AppColors.textHint),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF41B37E), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pisahkan dengan koma',
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
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
                setState(() => _hobbiesController.text = controller.text);
                Navigator.pop(context);
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

  void _editFavoriteColor() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _favoriteColorController.text);
        return AlertDialog(
          title: const Text(
            'Edit Warna Favorit',
            style: TextStyle(fontFamily: AppFonts.sfProRounded, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(fontFamily: AppFonts.sfProRounded),
            decoration: InputDecoration(
              hintText: 'Contoh: Biru, Hijau, Merah',
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
                setState(() => _favoriteColorController.text = controller.text);
                Navigator.pop(context);
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF41B37E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Simpan Perubahan',
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
