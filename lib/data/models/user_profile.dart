/// User Profile Model
class UserProfile {
  final String? uid;
  final String nama;
  final DateTime tanggalLahir;
  final String jenisKelamin; // 'Laki-laki' atau 'Perempuan'
  final String tingkatPendidikan; // 'SD', 'SMP', 'SMA'
  final String namaOrangTua;
  final String kontakOrangTua;
  final String? email;

  UserProfile({
    this.uid,
    required this.nama,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.tingkatPendidikan,
    required this.namaOrangTua,
    required this.kontakOrangTua,
    this.email,
  });

  /// Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'tanggalLahir': tanggalLahir.toIso8601String(),
      'jenisKelamin': jenisKelamin,
      'tingkatPendidikan': tingkatPendidikan,
      'namaOrangTua': namaOrangTua,
      'kontakOrangTua': kontakOrangTua,
      'email': email,
    };
  }

  /// Create from Map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'],
      nama: map['nama'] ?? '',
      tanggalLahir: DateTime.parse(map['tanggalLahir']),
      jenisKelamin: map['jenisKelamin'] ?? '',
      tingkatPendidikan: map['tingkatPendidikan'] ?? '',
      namaOrangTua: map['namaOrangTua'] ?? '',
      kontakOrangTua: map['kontakOrangTua'] ?? '',
      email: map['email'],
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
