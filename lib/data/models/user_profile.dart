import 'package:cloud_firestore/cloud_firestore.dart';

/// User Profile Model
class UserProfile {
  final String? uid;
  final String nama;
  final String namaPanggilan; // Nama panggilan untuk sapaan dari Cimo
  final DateTime tanggalLahir;
  final String jenisKelamin; // 'Laki-laki' atau 'Perempuan'
  final String tingkatPendidikan; // 'SD', 'SMP', 'SMA'
  final String namaOrangTua;
  final String kontakOrangTua;
  final String? email;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    this.uid,
    required this.nama,
    required this.namaPanggilan,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.tingkatPendidikan,
    required this.namaOrangTua,
    required this.kontakOrangTua,
    this.email,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'namaPanggilan': namaPanggilan,
      'tanggalLahir': Timestamp.fromDate(tanggalLahir),
      'jenisKelamin': jenisKelamin,
      'tingkatPendidikan': tingkatPendidikan,
      'namaOrangTua': namaOrangTua,
      'kontakOrangTua': kontakOrangTua,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Convert to Map for local storage (SharedPreferences)
  Map<String, dynamic> toLocalMap() {
    return {
      'uid': uid,
      'nama': nama,
      'namaPanggilan': namaPanggilan,
      'tanggalLahir': tanggalLahir.toIso8601String(),
      'jenisKelamin': jenisKelamin,
      'tingkatPendidikan': tingkatPendidikan,
      'namaOrangTua': namaOrangTua,
      'kontakOrangTua': kontakOrangTua,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      nama: map['nama'] ?? '',
      namaPanggilan: map['namaPanggilan'] ?? '',
      tanggalLahir: (map['tanggalLahir'] as Timestamp).toDate(),
      jenisKelamin: map['jenisKelamin'] ?? '',
      tingkatPendidikan: map['tingkatPendidikan'] ?? '',
      namaOrangTua: map['namaOrangTua'] ?? '',
      kontakOrangTua: map['kontakOrangTua'] ?? '',
      email: map['email'],
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  /// Create from Map (local storage)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'],
      nama: map['nama'] ?? '',
      namaPanggilan: map['namaPanggilan'] ?? '',
      tanggalLahir: DateTime.parse(map['tanggalLahir']),
      jenisKelamin: map['jenisKelamin'] ?? '',
      tingkatPendidikan: map['tingkatPendidikan'] ?? '',
      namaOrangTua: map['namaOrangTua'] ?? '',
      kontakOrangTua: map['kontakOrangTua'] ?? '',
      email: map['email'],
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  /// Copy with method for updating fields
  UserProfile copyWith({
    String? uid,
    String? nama,
    String? namaPanggilan,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    String? tingkatPendidikan,
    String? namaOrangTua,
    String? kontakOrangTua,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      namaPanggilan: namaPanggilan ?? this.namaPanggilan,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      tingkatPendidikan: tingkatPendidikan ?? this.tingkatPendidikan,
      namaOrangTua: namaOrangTua ?? this.namaOrangTua,
      kontakOrangTua: kontakOrangTua ?? this.kontakOrangTua,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted birth date
  String get formattedBirthDate {
    return '${tanggalLahir.day}/${tanggalLahir.month}/${tanggalLahir.year}';
  }

  /// Get age
  int get age {
    final now = DateTime.now();
    int age = now.year - tanggalLahir.year;
    if (now.month < tanggalLahir.month ||
        (now.month == tanggalLahir.month && now.day < tanggalLahir.day)) {
      age--;
    }
    return age;
  }
}
