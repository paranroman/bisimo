import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/student_model.dart';
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

      debugPrint('🔵 StudentAuthService: Attempting login with token: $normalizedToken');

      // Verify token via repository (hash + query Firestore)
      final student = await _studentRepository.verifyStudentToken(normalizedToken);

      if (student == null) {
        debugPrint('🔴 StudentAuthService: Token not found or invalid');
        return StudentAuthResult.failure(message: 'Token tidak ditemukan. Pastikan token benar.');
      }

      debugPrint('🟢 StudentAuthService: Token valid, creating session for ${student.displayName}');
      // Sign in anonymously to Firebase Auth so student has a Firebase token for API calls
      // This is needed because backend requires Firebase ID Token in Authorization header
      await _ensureFirebaseAuth();
      // Create session
      final session = StudentSession.fromStudent(student);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, session.toJson());

      debugPrint('🟢 StudentAuthService: Session saved successfully');

      return StudentAuthResult.success(
        session: session,
        message: 'Selamat datang, ${student.displayName}!',
      );
    } catch (e, stackTrace) {
      debugPrint('🔴 StudentAuthService ERROR: ${e.runtimeType}');
      debugPrint('🔴 Message: $e');
      debugPrint('🔴 Stack trace:\n$stackTrace');
      
      // Record error to Firebase Crashlytics
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'StudentAuthService.signInStudent failed',
        fatal: false,
      );

      // Provide more specific error messages based on error type
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('permission') || errorMessage.contains('denied')) {
        return StudentAuthResult.failure(
          message: 'Akses ditolak. Pastikan Firestore rules sudah benar.',
        );
      } else if (errorMessage.contains('network') || 
                 errorMessage.contains('connection') || 
                 errorMessage.contains('timeout')) {
        return StudentAuthResult.failure(
          message: 'Koneksi internet bermasalah atau server lambat. Coba lagi.',
        );
      } else if (errorMessage.contains('json') || errorMessage.contains('type')) {
        return StudentAuthResult.failure(
          message: 'Format data tidak valid. Hubungi wali kelas Anda.',
        );
      } else if (errorMessage.contains('firebaseexception')) {
        return StudentAuthResult.failure(
          message: 'Gagal menghubungi Firebase. Periksa internet Anda.',
        );
      } else if (errorMessage.contains('no matching documents')) {
        return StudentAuthResult.failure(
          message: 'Token tidak terdaftar di sistem.',
        );
      }

      return StudentAuthResult.failure(
        message: 'Kesalahan login: ${e.toString().length > 60 ? e.toString().substring(0, 60) : e.toString()}',
      );
    }
  }

  /// Ensure student has a Firebase Auth session (anonymous) for API token
  Future<void> _ensureFirebaseAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        debugPrint('StudentAuthService: Signing in anonymously for API token...');
        await auth.signInAnonymously();
        debugPrint('StudentAuthService: ✅ Anonymous auth success, uid: ${auth.currentUser?.uid}');
      } else {
        debugPrint('StudentAuthService: ✅ Firebase Auth already active, uid: ${auth.currentUser?.uid}');
      }
    } catch (e) {
      debugPrint('StudentAuthService: ⚠️ Anonymous auth failed: $e');
      // Don't rethrow - student can still use the app, but API calls may fail
    }
  }

  /// Sign out student (clear session + Firebase anonymous auth)
  Future<void> signOutStudent() async {
    try {
      // Sign out Firebase anonymous auth
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null && auth.currentUser!.isAnonymous) {
        await auth.signOut();
        debugPrint('StudentAuthService: Firebase anonymous auth signed out');
      }
      
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
  /// Verifies that the token hasn't been regenerated by wali kelas
  /// and refreshes student data from Firestore.
  Future<StudentSession?> getStudentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);

      if (sessionJson == null) {
        return null;
      }

      final session = StudentSession.fromJson(sessionJson);

      // Ensure Firebase anonymous auth is active for API calls
      await _ensureFirebaseAuth();

      // Verify the student still exists and token hash hasn't changed
      // This handles the case where wali kelas regenerated the token
      try {
        final doc = await FirebaseFirestore.instance
            .collection('students')
            .doc(session.studentId)
            .get();

        if (!doc.exists) {
          debugPrint('StudentAuthService: Student document no longer exists');
          await signOutStudent();
          return null;
        }

        final data = doc.data()!;
        final currentTokenHash = data['loginTokenHash'] as String?;
        final sessionTokenHash = session.studentData?.loginTokenHash;

        // If wali regenerated token, the hash will differ → invalidate session
        if (sessionTokenHash != null &&
            currentTokenHash != null &&
            sessionTokenHash != currentTokenHash) {
          debugPrint('StudentAuthService: Token was regenerated by wali, invalidating session');
          await signOutStudent();
          return null;
        }

        // Refresh student data from Firestore (picks up editable profile changes, etc.)
        final refreshedStudent = StudentModel.fromMap(data, doc.id);
        final refreshedSession = StudentSession(
          studentId: session.studentId,
          displayName: refreshedStudent.displayName,
          fullName: refreshedStudent.lockedProfile.fullName,
          waliId: refreshedStudent.waliId,
          schoolId: refreshedStudent.schoolId,
          avatarUrl: refreshedStudent.editableProfile.photoUrl,
          sessionCreatedAt: session.sessionCreatedAt,
          studentData: refreshedStudent,
        );

        // Update local cache with refreshed data
        await prefs.setString(_sessionKey, refreshedSession.toJson());

        return refreshedSession;
      } catch (e) {
        // If Firestore check fails (offline), return cached session
        debugPrint('StudentAuthService: Could not verify session online, using cached: $e');
        return session;
      }
    } catch (e) {
      debugPrint('StudentAuthService: Error getting session - $e');
      return null;
    }
  }

  /// Refresh student data from Firestore and update local session
  Future<StudentAuthResult> refreshStudentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);
      if (sessionJson == null) {
        return StudentAuthResult.failure(message: 'Tidak ada sesi aktif');
      }

      final session = StudentSession.fromJson(sessionJson);

      // Fetch latest data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(session.studentId)
          .get();

      if (!doc.exists) {
        await signOutStudent();
        return StudentAuthResult.failure(message: 'Data murid tidak ditemukan');
      }

      final student = StudentModel.fromMap(doc.data()!, doc.id);
      final refreshedSession = StudentSession(
        studentId: session.studentId,
        displayName: student.displayName,
        fullName: student.lockedProfile.fullName,
        waliId: student.waliId,
        schoolId: student.schoolId,
        avatarUrl: student.editableProfile.photoUrl,
        sessionCreatedAt: session.sessionCreatedAt,
        studentData: student,
      );

      await prefs.setString(_sessionKey, refreshedSession.toJson());
      return StudentAuthResult.success(
        session: refreshedSession,
        message: 'Data berhasil diperbarui',
      );
    } catch (e) {
      debugPrint('StudentAuthService: Error refreshing data - $e');
      return StudentAuthResult.failure(message: 'Gagal memperbarui data');
    }
  }
}

