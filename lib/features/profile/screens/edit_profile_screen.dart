import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String? _selectedGender;

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getProfile();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (mounted) {
      setState(() {
        _profile = profile;
        if (profile != null) {
          // Use existing profile data
          _namaController.text = profile.nama;
          _selectedGender = profile.jenisKelamin;
        } else if (currentUser != null) {
          // Pre-fill from Google/Firebase Auth data if no profile exists
          final displayName = currentUser.displayName;
          if (displayName != null && displayName.isNotEmpty) {
            _namaController.text = displayName;
          }
        }
        _isLoading = false;
      });
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

  Future<void> _saveProfile() async {
    // Allow saving with just the name OR just the gender
    final nama = _namaController.text.trim();
    if (nama.isEmpty && _selectedGender == null) return;

    try {
      final updatedProfile = UserProfile(
        uid: _profile?.uid,
        nama: nama.isNotEmpty ? nama : (_profile?.nama ?? ''),
        namaPanggilan: nama.isNotEmpty ? nama : (_profile?.namaPanggilan ?? ''),
        tanggalLahir: _profile?.tanggalLahir ?? DateTime(2000, 1, 1),
        jenisKelamin: _selectedGender ?? _profile?.jenisKelamin ?? '',
        tingkatPendidikan: _profile?.tingkatPendidikan ?? '',
        namaOrangTua: _profile?.namaOrangTua ?? '',
        kontakOrangTua: _profile?.kontakOrangTua ?? '',
        email: _profile?.email,
        photoUrl: _profile?.photoUrl,
      );
      await _profileService.saveProfile(updatedProfile);
      if (mounted) {
        setState(() => _profile = updatedProfile);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Profil berhasil disimpan!',
              style: TextStyle(fontFamily: AppFonts.sfProRounded),
            ),
            backgroundColor: const Color(0xFF41B37E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan: $e',
              style: const TextStyle(fontFamily: AppFonts.sfProRounded),
            ),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
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

                      // Profile Avatar - show Google photo or Cimo
                      _buildProfileAvatar(),
                      const SizedBox(height: 40),

                      // Profile Fields - Only Nama and Jenis Kelamin
                      _buildProfileField(
                        label: 'Nama',
                        value: _namaController.text.isNotEmpty
                            ? _namaController.text
                            : 'Belum diisi',
                        icon: Icons.edit_outlined,
                        onTap: _editNama,
                      ),
                      _buildProfileField(
                        label: 'Jenis Kelamin',
                        value: _selectedGender ?? 'Belum dipilih',
                        icon: Icons.keyboard_arrow_down,
                        onTap: _showGenderPicker,
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

  Widget _buildProfileAvatar() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final photoUrl = _profile?.photoUrl ?? currentUser?.photoURL;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      // Show Google/Firebase profile photo
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD859), width: 6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: const Color(0xFF41B37E),
                      strokeWidth: 2,
                    ),
                  );
                },
              ),
            ),
          ),
          // Edit avatar badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF41B37E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ],
      );
    }

    // Default Cimo avatar when no photo
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
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
    );
  }
}
