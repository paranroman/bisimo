import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../data/models/student_model.dart';

/// Card widget displaying student information
class StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onRegenerateToken;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const StudentCard({
    super.key,
    required this.student,
    required this.onRegenerateToken,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMale = student.lockedProfile.gender == Gender.male;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar — shows photo if student uploaded one
                _buildAvatar(isMale),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.lockedProfile.fullName,
                        style: const TextStyle(
                          fontFamily: AppFonts.sfProRounded,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (student.schoolId != null) ...[
                            _buildInfoChip(icon: Icons.school, text: student.schoolId!),
                            const SizedBox(width: 8),
                          ],
                          if (student.age > 0)
                            _buildInfoChip(icon: Icons.cake, text: '${student.age} tahun'),
                        ],
                      ),
                      if (student.updatedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Terakhir login: ${_formatLastLogin(student.updatedAt!)}',
                          style: const TextStyle(
                            fontFamily: AppFonts.sfProRounded,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textHint),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    switch (value) {
                      case 'regenerate':
                        onRegenerateToken();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'regenerate',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 20, color: Color(0xFF41B37E)),
                          SizedBox(width: 8),
                          Text(
                            'Buat Token Baru',
                            style: TextStyle(fontFamily: AppFonts.sfProRounded),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Color(0xFFE57373)),
                          SizedBox(width: 8),
                          Text(
                            'Hapus Murid',
                            style: TextStyle(
                              fontFamily: AppFonts.sfProRounded,
                              color: Color(0xFFE57373),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Avatar that shows student photo (base64/network) or initial letter
  Widget _buildAvatar(bool isMale) {
    final photoUrl = student.editableProfile.photoUrl;
    const double avatarSize = 56;

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: isMale
            ? const Color(0xFF5B9BD5).withValues(alpha: 0.2)
            : const Color(0xFFFFB6C1).withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: ClipOval(child: _avatarContent(photoUrl, isMale, avatarSize)),
    );
  }

  Widget _avatarContent(String? photoUrl, bool isMale, double size) {
    // Base64 photo
    if (photoUrl != null && photoUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(photoUrl.split(',').last);
        return Image.memory(bytes, fit: BoxFit.cover, width: size, height: size);
      } catch (_) {
        // fall through
      }
    }

    // Network URL
    if (photoUrl != null && photoUrl.startsWith('http')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, error, stackTrace) => _initialAvatar(isMale),
      );
    }

    return _initialAvatar(isMale);
  }

  Widget _initialAvatar(bool isMale) {
    return Center(
      child: Text(
        student.displayName.isNotEmpty ? student.displayName[0].toUpperCase() : '?',
        style: TextStyle(
          fontFamily: AppFonts.sfProRounded,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: isMale ? const Color(0xFF5B9BD5) : const Color(0xFFFF69B4),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontFamily: AppFonts.sfProRounded,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastLogin(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
