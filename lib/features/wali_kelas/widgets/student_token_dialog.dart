import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../data/models/student_model.dart';

/// Dialog showing the generated token for a student
/// Used for both new student creation and token regeneration
class StudentTokenDialog extends StatelessWidget {
  final StudentModel student;
  final String plainToken;
  final bool isRegeneration;

  const StudentTokenDialog({
    super.key,
    required this.student,
    required this.plainToken,
    this.isRegeneration = false,
  });

  void _copyToken(BuildContext context) {
    Clipboard.setData(ClipboardData(text: plainToken));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token disalin ke clipboard'),
        backgroundColor: Color(0xFF41B37E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(color: Color(0xFF41B37E), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isRegeneration ? 'Token Baru Berhasil Dibuat!' : 'Murid Berhasil Ditambahkan!',
                style: const TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Student Name
              Text(
                student.displayName,
                style: const TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 24),

              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QrImageView(
                  data: plainToken,
                  version: QrVersions.auto,
                  size: 150,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 16),

              // Token Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFBD30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plainToken,
                      style: const TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Color(0xFF41B37E)),
                      onPressed: () => _copyToken(context),
                      tooltip: 'Salin Token',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Simpan token ini! Token tidak akan ditampilkan lagi.',
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Info
              const Text(
                'Berikan token atau scan QR Code ini kepada murid untuk login ke aplikasi.',
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF41B37E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontFamily: AppFonts.nunito,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

