import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/student_model.dart';
import '../../../providers/student_provider.dart';
import '../../../shared/widgets/navigation/app_drawer.dart';
import '../widgets/add_student_dialog.dart';
import '../widgets/student_token_dialog.dart';
import '../widgets/student_card.dart';

/// Wali Kelas Dashboard Screen
class WaliDashboardScreen extends StatefulWidget {
  const WaliDashboardScreen({super.key});

  @override
  State<WaliDashboardScreen> createState() => _WaliDashboardScreenState();
}

class _WaliDashboardScreenState extends State<WaliDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load students when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadStudents();
    });
  }

  void _showAddStudentDialog() async {
    final result = await showDialog<CreateStudentResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddStudentDialog(),
    );

    if (result != null && result.isSuccess && mounted) {
      // Show token dialog with the generated token
      _showTokenDialog(result.student!, result.plainToken!);
    }
  }

  void _showTokenDialog(StudentModel student, String plainToken) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StudentTokenDialog(
        student: student,
        plainToken: plainToken,
      ),
    );
  }

  void _handleRegenerateToken(StudentModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Buat Token Baru?',
          style: TextStyle(
            fontFamily: AppFonts.sfProRounded,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Token lama untuk ${student.displayName} akan tidak berlaku lagi. Lanjutkan?',
          style: const TextStyle(fontFamily: AppFonts.sfProRounded),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: AppFonts.sfProRounded,
                color: AppColors.textHint,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Ya, Buat Baru',
              style: TextStyle(
                fontFamily: AppFonts.sfProRounded,
                color: Color(0xFF41B37E),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final result = await context.read<StudentProvider>().regenerateToken(student.id);
      if (result.isSuccess && mounted) {
        _showTokenDialog(result.student!, result.plainToken!);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Gagal membuat token baru'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleDeleteStudent(StudentModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Hapus Murid?',
          style: TextStyle(
            fontFamily: AppFonts.sfProRounded,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${student.displayName} dari daftar murid?',
          style: const TextStyle(fontFamily: AppFonts.sfProRounded),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: AppFonts.sfProRounded,
                color: AppColors.textHint,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(
                fontFamily: AppFonts.sfProRounded,
                color: Color(0xFFE57373),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<StudentProvider>().deleteStudent(student.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Murid berhasil dihapus' : 'Gagal menghapus murid',
            ),
            backgroundColor: success ? const Color(0xFF41B37E) : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          'Dashboard Wali Kelas',
          style: TextStyle(
            fontFamily: AppFonts.sfProRounded,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.waliDashboard),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              AssetPaths.homeBackground,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFFFFF8E7));
              },
            ),
          ),
          // Content
          Consumer<StudentProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.students.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF41B37E)),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadStudents(),
                color: const Color(0xFF41B37E),
                child: CustomScrollView(
                  slivers: [
                    // Header Section
                    SliverToBoxAdapter(
                      child: _buildHeader(provider.studentCount),
                    ),
                    // Students List
                    if (provider.students.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final student = provider.students[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: StudentCard(
                                  student: student,
                                  onRegenerateToken: () => _handleRegenerateToken(student),
                                  onDelete: () => _handleDeleteStudent(student),
                                ),
                              );
                            },
                            childCount: provider.students.length,
                          ),
                        ),
                      ),
                    // Bottom padding
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        backgroundColor: const Color(0xFF41B37E),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Tambah Murid',
          style: TextStyle(
            fontFamily: AppFonts.sfProRounded,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int studentCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF41B37E), Color(0xFF2D7D58)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D7D58).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Cimo Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFBD30),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      AssetPaths.cimoJoy,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.emoji_emotions,
                          size: 40,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat Datang,',
                        style: TextStyle(
                          fontFamily: AppFonts.sfProRounded,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                      const Text(
                        'Wali Kelas!',
                        style: TextStyle(
                          fontFamily: AppFonts.sfProRounded,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$studentCount murid terdaftar',
                        style: const TextStyle(
                          fontFamily: AppFonts.sfProRounded,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Section Title
          const Text(
            'Daftar Murid',
            style: TextStyle(
              fontFamily: AppFonts.sfProRounded,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFFBD30).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 60,
              color: Color(0xFFFFBD30),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Murid',
            style: TextStyle(
              fontFamily: AppFonts.sfProRounded,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tekan tombol "Tambah Murid" untuk menambahkan murid baru ke kelas Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.sfProRounded,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
