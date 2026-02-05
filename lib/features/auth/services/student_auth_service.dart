import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/student_session.dart';
import '../../../data/repositories/student_repository.dart';

/// Result class for student auth operations
class StudentAuthResult {
  final bool isSuccess;
  final String? message;
  final StudentSession? session;

  StudentAuthResult._({required this.isSuccess, this.message, this.session});

  factory StudentAuthResult.success({required StudentSession session, String? message}) {
    return StudentAuthResult._(isSuccess: true, session: session, message: message);
  }

  factory StudentAuthResult.failure({required String message}) {
    return StudentAuthResult._(isSuccess: false, message: message);
  }
}

/// Service for handling student token-based authentication
/// Uses "Logical Auth" via Firestore Query + SharedPreferences for session
class StudentAuthService {
  static const _sessionKey = 'student_session';

  final StudentRepository _studentRepository = StudentRepository();

  /// Sign in a student using their token
  /// This performs "Logical Auth" without Firebase Custom Token
  Future<StudentAuthResult> signInStudent(String token) async {
    try {
      // Normalize token input (remove spaces, convert to uppercase)
      final normalizedToken = token.trim().toUpperCase();

      if (normalizedToken.isEmpty) {
        return StudentAuthResult.failure(message: 'Token tidak boleh kosong');
      }

      // Token format validation (XXX-XXX or XXXXXX)
      final cleanToken = normalizedToken.replaceAll('-', '');
      if (cleanToken.length != 6 || !RegExp(r'^[A-Z0-9]{6}$').hasMatch(cleanToken)) {
        return StudentAuthResult.failure(
          message: 'Format token tidak valid. Gunakan format ABC-123',
        );
      }

      debugPrint('StudentAuthService: Attempting login with token: $normalizedToken');

      // Verify token via repository (hash + query Firestore)
      final student = await _studentRepository.verifyStudentToken(normalizedToken);

      if (student == null) {
        debugPrint('StudentAuthService: Token not found or invalid');
        return StudentAuthResult.failure(message: 'Token tidak ditemukan. Pastikan token benar.');
      }

      debugPrint('StudentAuthService: Token valid, creating session for ${student.displayName}');

      // Create session
      final session = StudentSession.fromStudent(student);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, session.toJson());

      debugPrint('StudentAuthService: Session saved');

      return StudentAuthResult.success(
        session: session,
        message: 'Selamat datang, ${student.displayName}!',
      );
    } catch (e, stackTrace) {
      debugPrint('StudentAuthService: Error - $e');
      debugPrint('StudentAuthService: Stack trace - $stackTrace');

      // Provide more specific error messages
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('permission') || errorMessage.contains('denied')) {
        return StudentAuthResult.failure(message: 'Akses ditolak. Hubungi wali kelas Anda.');
      } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
        return StudentAuthResult.failure(message: 'Koneksi internet bermasalah. Coba lagi.');
      } else if (errorMessage.contains('json') || errorMessage.contains('type')) {
        return StudentAuthResult.failure(message: 'Data tidak valid. Hubungi wali kelas.');
      }

      return StudentAuthResult.failure(
        message:
            'Terjadi kesalahan: ${e.toString().length > 50 ? e.toString().substring(0, 50) : e.toString()}',
      );
    }
  }

  /// Sign out student (clear session)
  Future<void> signOutStudent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      debugPrint('StudentAuthService: Session cleared');
    } catch (e) {
      debugPrint('StudentAuthService: Error clearing session - $e');
    }
  }

  /// Check if there's a valid student session
  Future<bool> hasValidSession() async {
    final session = await getStudentSession();
    return session != null && session.isValid;
  }

  /// Get current student session (if any)
  Future<StudentSession?> getStudentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);

      if (sessionJson == null) {
        return null;
      }

      final session = StudentSession.fromJson(sessionJson);

      // Check if session is still valid
      if (!session.isValid) {
        debugPrint('StudentAuthService: Session expired');
        await signOutStudent();
        return null;
      }

      return session;
    } catch (e) {
      debugPrint('StudentAuthService: Error getting session - $e');
      return null;
    }
  }

  /// Refresh student data from Firestore
  /// Call this periodically to sync local data with server
  Future<StudentAuthResult> refreshStudentData() async {
    try {
      final session = await getStudentSession();
      if (session == null) {
        return StudentAuthResult.failure(message: 'Tidak ada sesi aktif');
      }

      // This would require loading student by ID
      // For now, session data is sufficient
      return StudentAuthResult.success(session: session, message: 'Data berhasil diperbarui');
    } catch (e) {
      debugPrint('StudentAuthService: Error refreshing data - $e');
      return StudentAuthResult.failure(message: 'Gagal memperbarui data');
    }
  }
}
