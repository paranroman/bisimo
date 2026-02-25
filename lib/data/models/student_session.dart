import 'dart:convert';
import 'student_model.dart';

/// Represents an authenticated student session
/// This is stored locally in SharedPreferences for session persistence
class StudentSession {
  /// Student's unique ID from Firestore
  final String studentId;

  /// Student's display name (nickname or full name)
  final String displayName;

  /// Student's full name from locked profile
  final String fullName;

  /// Student's Wali Kelas ID
  final String waliId;

  /// School/class ID
  final String? schoolId;

  /// Profile avatar URL (if any)
  final String? avatarUrl;

  /// When the session was created
  final DateTime sessionCreatedAt;

  /// Full student data (for offline access)
  final StudentModel? studentData;

  const StudentSession({
    required this.studentId,
    required this.displayName,
    required this.fullName,
    required this.waliId,
    this.schoolId,
    this.avatarUrl,
    required this.sessionCreatedAt,
    this.studentData,
  });

  /// Create session from StudentModel
  factory StudentSession.fromStudent(StudentModel student) {
    return StudentSession(
      studentId: student.id,
      displayName: student.displayName,
      fullName: student.lockedProfile.fullName,
      waliId: student.waliId,
      schoolId: student.schoolId,
      avatarUrl: null, // Can be extended later
      sessionCreatedAt: DateTime.now(),
      studentData: student,
    );
  }

  /// Create from JSON string (from SharedPreferences)
  factory StudentSession.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return StudentSession(
      studentId: map['studentId'] as String,
      displayName: map['displayName'] as String,
      fullName: map['fullName'] as String,
      waliId: map['waliId'] as String,
      schoolId: map['schoolId'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      sessionCreatedAt: DateTime.parse(map['sessionCreatedAt'] as String),
      studentData: map['studentData'] != null
          ? StudentModel.fromJsonMap(map['studentData'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON string (for SharedPreferences)
  String toJson() {
    return jsonEncode({
      'studentId': studentId,
      'displayName': displayName,
      'fullName': fullName,
      'waliId': waliId,
      'schoolId': schoolId,
      'avatarUrl': avatarUrl,
      'sessionCreatedAt': sessionCreatedAt.toIso8601String(),
      'studentData': studentData?.toJsonMap(),
    });
  }

  /// Check if session is valid
  /// Sessions are permanent until wali kelas regenerates the token.
  /// Validation against Firestore token hash is done on session restore.
  bool get isValid {
    // Session is always valid locally — server-side token hash check
    // in StudentAuthService.getStudentSession() handles invalidation
    // when wali kelas regenerates the token.
    return true;
  }

  /// Get session age in days
  int get sessionAgeDays {
    return DateTime.now().difference(sessionCreatedAt).inDays;
  }

  @override
  String toString() {
    return 'StudentSession(studentId: $studentId, displayName: $displayName, valid: $isValid)';
  }
}

