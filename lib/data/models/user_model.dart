import 'package:cloud_firestore/cloud_firestore.dart';

/// Emotion type enum for Cimo and emotion detection
enum EmotionType { senang, sedih, marah, takut, terkejut, jijik, neutral }

/// User role enum for multi-role authentication
enum UserRole { wali, murid }

/// User model - represents authenticated users (Wali Kelas)
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final UserRole role;
  final String? schoolId;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.role = UserRole.wali,
    this.schoolId,
    this.createdAt,
  });

  factory UserModel.empty() => const UserModel(id: '', name: '', email: '', role: UserRole.wali);

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      role: UserRole.values.firstWhere((e) => e.name == data['role'], orElse: () => UserRole.wali),
      schoolId: data['schoolId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create UserModel from Map (for use with queries)
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      role: UserRole.values.firstWhere((e) => e.name == data['role'], orElse: () => UserRole.wali),
      schoolId: data['schoolId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'schoolId': schoolId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    UserRole? role,
    String? schoolId,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: ${role.name}, schoolId: $schoolId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

