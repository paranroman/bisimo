import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../models/student_model.dart';

/// Repository for managing student data
/// Handles CRUD operations and token-based authentication for students
class StudentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get students collection reference
  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection('students');

  /// Generate a random 6-character alphanumeric token
  /// Format: XXX-XXX (e.g., "A7X-92B")
  String _generatePlainToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluded I, O, 0, 1 to avoid confusion
    final random = Random.secure();

    String generatePart(int length) {
      return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
    }

    return '${generatePart(3)}-${generatePart(3)}';
  }

  /// Hash a token using SHA-256
  String _hashToken(String plainToken) {
    // Normalize token: remove dashes and convert to uppercase
    final normalizedToken = plainToken.replaceAll('-', '').toUpperCase();
    final bytes = utf8.encode(normalizedToken);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Create a new student account
  /// Returns the plain token (to show to Wali Kelas) - NEVER store this in database
  Future<CreateStudentResult> createStudentAccount(CreateStudentData data) async {
    try {
      // Verify current user is authenticated (Wali Kelas)
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return CreateStudentResult.failure(
          message: 'Anda harus login sebagai Wali Kelas untuk menambah murid.',
        );
      }

      // Generate token
      final plainToken = _generatePlainToken();
      final hashedToken = _hashToken(plainToken);

      // Check if token hash already exists (very unlikely but good to check)
      final existingToken = await _studentsCollection
          .where('loginTokenHash', isEqualTo: hashedToken)
          .limit(1)
          .get();

      if (existingToken.docs.isNotEmpty) {
        // Regenerate token if collision (extremely rare)
        return createStudentAccount(data);
      }

      // Create student document
      final docRef = _studentsCollection.doc();
      final now = DateTime.now();

      // Create locked profile from form data
      final lockedProfile = LockedProfile(
        fullName: data.nama,
        birthDate: data.tanggalLahir,
        gender: data.jenisKelamin == 'Laki-laki' ? Gender.male : Gender.female,
      );

      // Create editable profile with nickname
      final editableProfile = EditableProfile(nickname: data.namaPanggilan);

      final student = StudentModel(
        id: docRef.id,
        waliId: currentUser.uid,
        loginTokenHash: hashedToken,
        editableProfile: editableProfile,
        lockedProfile: lockedProfile,
        settings: const StudentSettings(),
        schoolId: data.tingkatPendidikan,
        createdAt: now,
      );

      // Save to Firestore
      await docRef.set(student.toFirestore());

      debugPrint('StudentRepository: Created student ${student.id} for wali ${currentUser.uid}');

      return CreateStudentResult.success(
        student: student,
        plainToken: plainToken, // Return plain token to show to Wali Kelas
      );
    } on FirebaseException catch (e) {
      debugPrint('StudentRepository: Firebase error - ${e.message}');
      return CreateStudentResult.failure(message: 'Gagal menambah murid: ${e.message}');
    } catch (e) {
      debugPrint('StudentRepository: Error - $e');
      return CreateStudentResult.failure(message: 'Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  /// Get all students for current Wali Kelas
  Future<List<StudentModel>> getStudentsByWaliKelas() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('StudentRepository: No authenticated user');
        return [];
      }

      debugPrint('StudentRepository: Fetching students for wali ${currentUser.uid}');

      final snapshot = await _studentsCollection
          .where('waliId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('StudentRepository: Found ${snapshot.docs.length} students');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return StudentModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('StudentRepository: Error getting students - $e');
      return [];
    }
  }

  /// Get students stream for real-time updates
  Stream<List<StudentModel>> getStudentsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _studentsCollection
        .where('waliId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return StudentModel.fromMap(data, doc.id);
          }).toList(),
        );
  }

  /// Verify student login token
  /// Returns the student if token is valid, null otherwise
  Future<StudentModel?> verifyStudentToken(String plainToken) async {
    try {
      final hashedToken = _hashToken(plainToken);
      debugPrint('🔵 StudentRepository: Starting token verification');
      debugPrint('🔵 Token hash (first 10 chars): ${hashedToken.substring(0, 10)}...');

      final startTime = DateTime.now();
      
      final snapshot = await _studentsCollection
          .where('loginTokenHash', isEqualTo: hashedToken)
          .limit(1)
          .get()
          .timeout(
            Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Firestore query timeout after 15s'),
          );

      final queryDuration = DateTime.now().difference(startTime);
      debugPrint('🟢 StudentRepository: Query completed in ${queryDuration.inMilliseconds}ms');
      debugPrint('🟢 StudentRepository: Query returned ${snapshot.docs.length} documents');

      if (snapshot.docs.isEmpty) {
        debugPrint('🔴 StudentRepository: No student found with this token');
        return null;
      }

      final doc = snapshot.docs.first;
      debugPrint('🟢 StudentRepository: Found student with ID: ${doc.id}');

      // Try to update last login time, but don't fail if it doesn't work
      // (student might not be authenticated yet for Logical Auth)
      try {
        await doc.reference.update({'updatedAt': FieldValue.serverTimestamp()});
        debugPrint('🟢 StudentRepository: Updated last login time');
      } catch (updateError) {
        // Ignore update errors - the student document was found, that's what matters
        debugPrint(
          '⚠️ StudentRepository: Could not update last login time (expected for Logical Auth): $updateError',
        );
      }

      final data = doc.data();
      debugPrint('🟢 StudentRepository: Successfully retrieved student data');
      
      return StudentModel.fromMap(data, doc.id);
    } on TimeoutException catch (e) {
      debugPrint('🔴 StudentRepository: Timeout error - $e');
      await FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'StudentRepository.verifyStudentToken timeout',
      );
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('🔴 StudentRepository: Firebase error - Code: ${e.code}, Message: ${e.message}');
      await FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'StudentRepository Firebase error: ${e.code}',
      );
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('🔴 StudentRepository: Unexpected error - ${e.runtimeType}: $e');
      debugPrint('Stack trace: $stackTrace');
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'StudentRepository.verifyStudentToken failed',
      );
      rethrow;
    }
  }

  /// Update student data
  Future<bool> updateStudent(StudentModel student) async {
    try {
      await _studentsCollection.doc(student.id).update(student.toFirestore());
      return true;
    } catch (e) {
      debugPrint('StudentRepository: Error updating student - $e');
      return false;
    }
  }

  /// Update only the editable profile fields (for student self-updates)
  /// This doesn't require Firebase Auth - uses studentId directly
  Future<bool> updateStudentEditableProfile(
    String studentId,
    EditableProfile editableProfile,
  ) async {
    try {
      await _studentsCollection.doc(studentId).update({
        'editableProfile': editableProfile.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('StudentRepository: Updated editable profile for student $studentId');
      return true;
    } catch (e) {
      debugPrint('StudentRepository: Error updating editable profile - $e');
      return false;
    }
  }

  /// Delete student (hard delete)
  Future<bool> deleteStudent(String studentId) async {
    try {
      await _studentsCollection.doc(studentId).delete();
      debugPrint('StudentRepository: Deleted student $studentId');
      return true;
    } catch (e) {
      debugPrint('StudentRepository: Error deleting student - $e');
      return false;
    }
  }

  /// Regenerate token for a student
  /// Returns new plain token
  Future<CreateStudentResult> regenerateToken(String studentId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return CreateStudentResult.failure(message: 'Anda harus login sebagai Wali Kelas.');
      }

      // Get student document
      final doc = await _studentsCollection.doc(studentId).get();
      if (!doc.exists) {
        return CreateStudentResult.failure(message: 'Murid tidak ditemukan.');
      }

      final data = doc.data()!;
      final student = StudentModel.fromMap(data, doc.id);

      // Verify ownership
      if (student.waliId != currentUser.uid) {
        return CreateStudentResult.failure(message: 'Anda tidak memiliki akses ke murid ini.');
      }

      // Generate new token with collision check
      String plainToken = _generatePlainToken();
      String hashedToken = _hashToken(plainToken);

      // Check for collision (extremely rare but consistent with createStudentAccount)
      final existingToken = await _studentsCollection
          .where('loginTokenHash', isEqualTo: hashedToken)
          .limit(1)
          .get();

      if (existingToken.docs.isNotEmpty) {
        // Regenerate if collision
        plainToken = _generatePlainToken();
        hashedToken = _hashToken(plainToken);
      }

      // Update ONLY the token hash in Firestore — all profile data stays intact
      await _studentsCollection.doc(studentId).update({
        'loginTokenHash': hashedToken,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('StudentRepository: Regenerated token for student $studentId');

      return CreateStudentResult.success(
        student: student.copyWith(loginTokenHash: hashedToken),
        plainToken: plainToken,
      );
    } catch (e) {
      debugPrint('StudentRepository: Error regenerating token - $e');
      return CreateStudentResult.failure(message: 'Gagal memperbarui token. Silakan coba lagi.');
    }
  }

  /// Get student count for current Wali Kelas
  Future<int> getStudentCount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return 0;

      final snapshot = await _studentsCollection
          .where('waliId', isEqualTo: currentUser.uid)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('StudentRepository: Error getting student count - $e');
      return 0;
    }
  }
}
