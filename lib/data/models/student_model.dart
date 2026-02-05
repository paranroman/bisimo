import 'package:cloud_firestore/cloud_firestore.dart';

/// Gender enum for student profile
enum Gender { male, female }

/// Editable profile - can be edited by student themselves
class EditableProfile {
  final String? nickname;
  final List<String> hobbies;
  final String? favoriteColor;

  const EditableProfile({
    this.nickname,
    this.hobbies = const [],
    this.favoriteColor,
  });

  factory EditableProfile.empty() => const EditableProfile();

  factory EditableProfile.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const EditableProfile();
    return EditableProfile(
      nickname: data['nickname'] as String?,
      hobbies: (data['hobbies'] as List<dynamic>?)?.cast<String>() ?? [],
      favoriteColor: data['favoriteColor'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'hobbies': hobbies,
      'favoriteColor': favoriteColor,
    };
  }

  EditableProfile copyWith({
    String? nickname,
    List<String>? hobbies,
    String? favoriteColor,
  }) {
    return EditableProfile(
      nickname: nickname ?? this.nickname,
      hobbies: hobbies ?? this.hobbies,
      favoriteColor: favoriteColor ?? this.favoriteColor,
    );
  }
}

/// Locked profile - can only be edited by Wali Kelas
class LockedProfile {
  final String fullName;
  final DateTime? birthDate;
  final Gender? gender;

  const LockedProfile({
    required this.fullName,
    this.birthDate,
    this.gender,
  });

  factory LockedProfile.empty() => const LockedProfile(fullName: '');

  factory LockedProfile.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const LockedProfile(fullName: '');
    return LockedProfile(
      fullName: data['fullName'] as String? ?? '',
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      gender: data['gender'] != null
          ? Gender.values.firstWhere(
              (e) => e.name == data['gender'],
              orElse: () => Gender.male,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'gender': gender?.name,
    };
  }

  LockedProfile copyWith({
    String? fullName,
    DateTime? birthDate,
    Gender? gender,
  }) {
    return LockedProfile(
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
    );
  }
}

/// Student settings
class StudentSettings {
  /// Allow Wali to access chat/emotion history
  final bool allowHistoryAccess;

  const StudentSettings({
    this.allowHistoryAccess = true,
  });

  factory StudentSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const StudentSettings();
    return StudentSettings(
      allowHistoryAccess: data['allowHistoryAccess'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowHistoryAccess': allowHistoryAccess,
    };
  }

  StudentSettings copyWith({
    bool? allowHistoryAccess,
  }) {
    return StudentSettings(
      allowHistoryAccess: allowHistoryAccess ?? this.allowHistoryAccess,
    );
  }
}

/// Student model - represents students (murid) linked to a Wali Kelas
class StudentModel {
  /// Document ID in Firestore
  final String id;

  /// Reference to the Wali's user document ID
  final String waliId;

  /// Hashed login token for student authentication
  final String? loginTokenHash;

  /// Profile fields editable by student
  final EditableProfile editableProfile;

  /// Profile fields only editable by Wali
  final LockedProfile lockedProfile;

  /// Student settings
  final StudentSettings settings;

  /// School ID for multi-tenancy
  final String? schoolId;

  /// Creation timestamp
  final DateTime? createdAt;

  /// Last updated timestamp
  final DateTime? updatedAt;

  const StudentModel({
    required this.id,
    required this.waliId,
    this.loginTokenHash,
    this.editableProfile = const EditableProfile(),
    required this.lockedProfile,
    this.settings = const StudentSettings(),
    this.schoolId,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentModel.empty() => StudentModel(
        id: '',
        waliId: '',
        lockedProfile: const LockedProfile(fullName: ''),
      );

  /// Create StudentModel from Firestore document
  factory StudentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return StudentModel(
      id: doc.id,
      waliId: data['waliId'] as String? ?? '',
      loginTokenHash: data['loginTokenHash'] as String?,
      editableProfile: EditableProfile.fromMap(data['editableProfile'] as Map<String, dynamic>?),
      lockedProfile: LockedProfile.fromMap(data['lockedProfile'] as Map<String, dynamic>?),
      settings: StudentSettings.fromMap(data['settings'] as Map<String, dynamic>?),
      schoolId: data['schoolId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create StudentModel from Map
  factory StudentModel.fromMap(Map<String, dynamic> data, String id) {
    return StudentModel(
      id: id,
      waliId: data['waliId'] as String? ?? '',
      loginTokenHash: data['loginTokenHash'] as String?,
      editableProfile: EditableProfile.fromMap(data['editableProfile'] as Map<String, dynamic>?),
      lockedProfile: LockedProfile.fromMap(data['lockedProfile'] as Map<String, dynamic>?),
      settings: StudentSettings.fromMap(data['settings'] as Map<String, dynamic>?),
      schoolId: data['schoolId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore data (full document)
  Map<String, dynamic> toFirestore() {
    return {
      'waliId': waliId,
      'loginTokenHash': loginTokenHash,
      'editableProfile': editableProfile.toMap(),
      'lockedProfile': lockedProfile.toMap(),
      'settings': settings.toMap(),
      'schoolId': schoolId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Convert only editable profile to Firestore (for student updates)
  Map<String, dynamic> editableProfileToFirestore() {
    return {
      'editableProfile': editableProfile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Convert only locked profile to Firestore (for wali updates)
  Map<String, dynamic> lockedProfileToFirestore() {
    return {
      'lockedProfile': lockedProfile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  StudentModel copyWith({
    String? id,
    String? waliId,
    String? loginTokenHash,
    EditableProfile? editableProfile,
    LockedProfile? lockedProfile,
    StudentSettings? settings,
    String? schoolId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      waliId: waliId ?? this.waliId,
      loginTokenHash: loginTokenHash ?? this.loginTokenHash,
      editableProfile: editableProfile ?? this.editableProfile,
      lockedProfile: lockedProfile ?? this.lockedProfile,
      settings: settings ?? this.settings,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name (nickname if available, otherwise fullName)
  String get displayName => editableProfile.nickname ?? lockedProfile.fullName;

  @override
  String toString() {
    return 'StudentModel(id: $id, waliId: $waliId, name: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Calculate age from birth date
  int get age {
    final birthDate = lockedProfile.birthDate;
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

/// Data class for creating new student (used in forms)
class CreateStudentData {
  final String nama;
  final String namaPanggilan;
  final String kelas;
  final String jenisKelamin;
  final DateTime tanggalLahir;
  final String? tingkatPendidikan;

  const CreateStudentData({
    required this.nama,
    required this.namaPanggilan,
    required this.kelas,
    required this.jenisKelamin,
    required this.tanggalLahir,
    this.tingkatPendidikan,
  });
}

/// Result class for student creation
class CreateStudentResult {
  final bool isSuccess;
  final String? message;
  final StudentModel? student;
  final String? plainToken; // Plain token to show to Wali Kelas (NEVER store this)

  CreateStudentResult._({
    required this.isSuccess,
    this.message,
    this.student,
    this.plainToken,
  });

  factory CreateStudentResult.success({
    required StudentModel student,
    required String plainToken,
  }) {
    return CreateStudentResult._(
      isSuccess: true,
      student: student,
      plainToken: plainToken,
    );
  }

  factory CreateStudentResult.failure({required String message}) {
    return CreateStudentResult._(
      isSuccess: false,
      message: message,
    );
  }
}
