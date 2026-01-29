import 'package:firebase_auth/firebase_auth.dart';

/// Authentication Service - Handles all Firebase Auth operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Sign Up with Email and Password
  Future<AuthResult> signUp({required String email, required String password}) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success(user: userCredential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(message: 'Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  /// Sign In with Email and Password
  Future<AuthResult> signIn({required String email, required String password}) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success(user: userCredential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(message: 'Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reset Password
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(message: 'Email reset password telah dikirim ke $email');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(message: 'Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  /// Get user-friendly error messages in Indonesian
  String _getErrorMessage(String code) {
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
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}

/// Result class for auth operations
class AuthResult {
  final bool isSuccess;
  final String? message;
  final User? user;

  AuthResult._({required this.isSuccess, this.message, this.user});

  factory AuthResult.success({User? user, String? message}) {
    return AuthResult._(isSuccess: true, user: user, message: message);
  }

  factory AuthResult.failure({required String message}) {
    return AuthResult._(isSuccess: false, message: message);
  }
}
