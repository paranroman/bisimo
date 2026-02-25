import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

/// Auth repository — wraps Firebase Auth for Wali Kelas authentication
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current Firebase user (nullable)
  User? get firebaseUser => _auth.currentUser;

  /// Sign in with email and password
  /// Returns [UserModel] on success, null on failure.
  /// Throws [String] with a user-friendly error message on Firebase errors.
  Future<UserModel> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _userModelFromCredential(credential);
  }

  /// Sign up with email and password
  Future<UserModel> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _userModelFromCredential(credential);
  }

  /// Sign in with Google
  /// Returns [UserModel] on success.
  /// [isNewUser] flag available via [additionalUserInfo].
  Future<({UserModel user, bool isNewUser})> signInWithGoogle() async {
    await GoogleSignIn.instance.initialize();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;
    return (user: _userModelFromCredential(userCredential), isNewUser: isNew);
  }

  /// Sign out (both Firebase + Google)
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Google sign-out may fail if user didn't sign in with Google — that's OK
    }
    await _auth.signOut();
  }

  /// Get current authenticated user as [UserModel], or null if not logged in.
  UserModel? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      avatarUrl: user.photoURL,
      role: UserRole.wali,
      createdAt: user.metadata.creationTime,
    );
  }

  /// Convert [UserCredential] → [UserModel]
  UserModel _userModelFromCredential(UserCredential credential) {
    final user = credential.user!;
    return UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      avatarUrl: user.photoURL,
      role: UserRole.wali,
      createdAt: user.metadata.creationTime,
    );
  }

  /// User-friendly error message from FirebaseAuthException code
  static String getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan gunakan email lain.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'user-not-found':
        return 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa koneksi Anda.';
      case 'account-exists-with-different-credential':
        return 'Akun sudah ada dengan metode login berbeda.';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}

