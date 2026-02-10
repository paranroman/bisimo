import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../data/models/student_model.dart';

/// Student Detail Screen — viewed by Wali Kelas
/// Shows locked profile (set by wali) + editable profile (set by student)
/// with a placeholder for future diary/chat history.
class StudentDetailScreen extends StatelessWidget {
  final StudentModel student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: CustomScrollView(
        slivers: [
          // Collapsing header with photo + name
          _buildSliverAppBar(context),
          // Body content
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
    );
  }

  // ──────────────────────── Header ────────────────────────

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    final fullName = student.lockedProfile.fullName;
    final nickname = student.editableProfile.nickname;
    final displayName = (nickname != null && nickname.isNotEmpty) ? nickname : fullName;
    final isMale = student.lockedProfile.gender == Gender.male;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFF41B37E),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF41B37E), Color(0xFF2D8F5E)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40), // space for app bar
                // Avatar
                _AvatarCircle(
                  photoUrl: student.editableProfile.photoUrl,
                  displayName: displayName,
                  isMale: isMale,
                  size: 110,
                ),
                const SizedBox(height: 14),
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
                if (nickname != null && nickname.isNotEmpty && nickname != fullName) ...[
                  const SizedBox(height: 2),
                  Text(
                    fullName,
                    style: TextStyle(
                      fontFamily: AppFonts.sfProRounded,
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // Quick chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (student.schoolId != null)
                      _HeaderChip(icon: Icons.school, label: student.schoolId!),
                    if (student.age > 0) ...[
                      const SizedBox(width: 8),
                      _HeaderChip(icon: Icons.cake, label: '${student.age} tahun'),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────── Body ────────────────────────

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section 1: Data dari Wali Kelas ──
          _SectionHeader(icon: Icons.lock_outline, title: 'Data dari Wali Kelas'),
          const SizedBox(height: 12),
          _InfoCard(
            children: [
              _InfoRow(
                label: 'Nama Lengkap',
                value: student.lockedProfile.fullName.isNotEmpty
                    ? student.lockedProfile.fullName
                    : '-',
                icon: Icons.person_outline,
              ),
              const _CardDivider(),
              _InfoRow(
                label: 'Tanggal Lahir',
                value: student.lockedProfile.birthDate != null
                    ? DateFormat('dd MMMM yyyy', 'id_ID').format(student.lockedProfile.birthDate!)
                    : '-',
                icon: Icons.cake_outlined,
              ),
              const _CardDivider(),
              _InfoRow(
                label: 'Jenis Kelamin',
                value: student.lockedProfile.gender != null
                    ? (student.lockedProfile.gender == Gender.male ? 'Laki-laki' : 'Perempuan')
                    : '-',
                icon: Icons.wc_outlined,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Section 2: Profil Pribadi Murid ──
          _SectionHeader(icon: Icons.emoji_emotions_outlined, title: 'Profil Pribadi Murid'),
          const SizedBox(height: 12),
          _InfoCard(
            children: [
              _InfoRow(
                label: 'Nama Panggilan',
                value: student.editableProfile.nickname ?? '-',
                icon: Icons.badge_outlined,
              ),
              const _CardDivider(),
              _InfoRow(
                label: 'Tentang Saya',
                value: student.editableProfile.bio ?? '-',
                icon: Icons.person_outline,
              ),
              const _CardDivider(),
              _InfoRow(
                label: 'Hobi',
                value: student.editableProfile.hobbies.isNotEmpty
                    ? student.editableProfile.hobbies.join(', ')
                    : '-',
                icon: Icons.sports_esports_outlined,
              ),
              const _CardDivider(),
              _InfoRow(
                label: 'Warna Favorit',
                value: student.editableProfile.favoriteColor ?? '-',
                icon: Icons.palette_outlined,
              ),
              const _CardDivider(),
              _InfoRow(
                label: 'Hewan Kesukaan',
                value: student.editableProfile.favoriteAnimal ?? '-',
                icon: Icons.pets_outlined,
              ),
              const _CardDivider(),
              _InfoRow(
                label: 'Makanan Kesukaan',
                value: student.editableProfile.favoriteFood ?? '-',
                icon: Icons.restaurant_outlined,
              ),
              const _CardDivider(),
              _InfoRow(
                label: 'Cita-cita',
                value: student.editableProfile.dreamJob ?? '-',
                icon: Icons.rocket_launch_outlined,
              ),
              const _CardDivider(),
              _InfoRow(
                label: 'Pelajaran Favorit',
                value: student.editableProfile.favoriteSubject ?? '-',
                icon: Icons.menu_book_outlined,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Section 3: Diary / Riwayat — placeholder ──
          _SectionHeader(icon: Icons.history_outlined, title: 'Riwayat Percakapan'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: AppColors.textHint.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Riwayat percakapan ${student.displayName} dengan Cimo\nakan ditampilkan di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.sfProRounded,
                    fontSize: 14,
                    color: AppColors.textHint,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Segera hadir',
                  style: TextStyle(
                    fontFamily: AppFonts.sfProRounded,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF41B37E).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════ REUSABLE WIDGETS ═══════════════════════

/// Circle avatar that renders base64 / network / initial-letter photo
class _AvatarCircle extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final bool isMale;
  final double size;

  const _AvatarCircle({
    required this.photoUrl,
    required this.displayName,
    required this.isMale,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFD859), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(child: _content()),
    );
  }

  Widget _content() {
    // Base64 photo
    if (photoUrl != null && photoUrl!.startsWith('data:image')) {
      try {
        final bytes = base64Decode(photoUrl!.split(',').last);
        return Image.memory(bytes, fit: BoxFit.cover, width: size, height: size);
      } catch (_) {
        // fall through
      }
    }

    // Network URL
    if (photoUrl != null && photoUrl!.startsWith('http')) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, error, stackTrace) => _initial(),
      );
    }

    return _initial();
  }

  Widget _initial() {
    return Container(
      color: isMale
          ? const Color(0xFF5B9BD5).withValues(alpha: 0.2)
          : const Color(0xFFFFB6C1).withValues(alpha: 0.3),
      alignment: Alignment.center,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: TextStyle(
          fontFamily: AppFonts.sfProRounded,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: isMale ? const Color(0xFF5B9BD5) : const Color(0xFFFF69B4),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
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
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();
  @override
  Widget build(BuildContext context) => Divider(color: Colors.grey.shade200, height: 20);
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == '-';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF41B37E)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isEmpty ? AppColors.textHint : AppColors.textPrimary,
                  fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.sfProRounded,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
