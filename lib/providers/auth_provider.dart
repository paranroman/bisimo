import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/models/student_session.dart';
import '../data/repositories/auth_repository.dart';
import '../features/auth/services/student_auth_service.dart';
import '../features/auth/services/profile_service.dart';

/// Auth Provider for managing authentication state
/// Supports both Wali Kelas (Firebase Auth) and Student (Token Auth) authentication
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final StudentAuthService _studentAuthService = StudentAuthService();
  final ProfileService _profileService = ProfileService();

  UserModel? _user;
  StudentSession? _studentSession;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  bool _isStudentMode = false;
  bool _needsProfileData = false;

  // Getters
  UserModel? get user => _user;
  StudentSession? get studentSession => _studentSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isStudentMode => _isStudentMode;
  bool get needsProfileData => _needsProfileData;

  /// Get display name (works for both user and student)
  String get displayName {
    if (_isStudentMode && _studentSession != null) {
      return _studentSession!.displayName;
    }
    return _user?.name ?? '';
  }

  /// Sign in with email and password (Firebase Auth)
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signIn(email, password);
      _user = user;
      _isAuthenticated = true;
      _isStudentMode = false;
      _needsProfileData = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthRepository.getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Terjadi kesalahan. Silakan coba lagi.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with email and password (Firebase Auth)
  /// After success, check if profile data is needed.
  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signUp(email, password);
      _user = user;
      _isAuthenticated = true;
      _isStudentMode = false;
      // New accounts always need profile data
      _needsProfileData = true;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthRepository.getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Terjadi kesalahan. Silakan coba lagi.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in / sign up with Google (Firebase Auth)
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authRepository.signInWithGoogle();
      _user = result.user;
      _isAuthenticated = true;
      _isStudentMode = false;

      // Check if this Google user already has profile data
      if (result.isNewUser) {
        _needsProfileData = true;
      } else {
        final hasProfile = await _profileService.hasProfile();
        _needsProfileData = !hasProfile;
      }

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthRepository.getErrorMessage(e.code));
      return false;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('dibatalkan')) {
        _setError('Login dibatalkan');
      } else {
        _setError('Gagal masuk dengan Google. Silakan coba lagi.');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mark that profile data has been completed
  void markProfileDataCompleted() {
    _needsProfileData = false;
    notifyListeners();
  }

  /// Update the student session with refreshed data (after profile edit, etc.)
  Future<void> refreshStudentSession() async {
    if (!_isStudentMode || _studentSession == null) return;
    try {
      final result = await _studentAuthService.refreshStudentData();
      if (result.isSuccess && result.session != null) {
        _studentSession = result.session;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthProvider: Error refreshing student session - $e');
    }
  }

  /// Sign out (handles both Wali and Student modes)
  Future<void> signOut() async {
    _setLoading(true);

    try {
      if (_isStudentMode) {
        await _studentAuthService.signOutStudent();
        _studentSession = null;
        _isStudentMode = false;
      } else {
        await _authRepository.signOut();
        _user = null;
      }
      _isAuthenticated = false;
      _needsProfileData = false;
      notifyListeners();
    } catch (e) {
      _setError('Gagal keluar. Silakan coba lagi.');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in as student using token
  Future<bool> signInAsStudent(String token) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _studentAuthService.signInStudent(token);
      if (result.isSuccess && result.session != null) {
        _studentSession = result.session;
        _isAuthenticated = true;
        _isStudentMode = true;
        _needsProfileData = false;
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Token tidak valid');
        return false;
      }
    } catch (e) {
      _setError('Terjadi kesalahan. Silakan coba lagi.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user is already logged in (called on app start)
  Future<void> checkAuthStatus() async {
    _setLoading(true);

    try {
      // First check for student session (stored in SharedPreferences)
      final studentSession = await _studentAuthService.getStudentSession();
      if (studentSession != null && studentSession.isValid) {
        _studentSession = studentSession;
        _isAuthenticated = true;
        _isStudentMode = true;
        _needsProfileData = false;
        notifyListeners();
        _setLoading(false);
        return;
      }

      // Then check for Wali Kelas session (Firebase Auth persists automatically)
      final user = _authRepository.getCurrentUser();
      if (user != null) {
        _user = user;
        _isAuthenticated = true;
        _isStudentMode = false;

        // Check if they still need to fill profile data
        final hasProfile = await _profileService.hasProfile();
        _needsProfileData = !hasProfile;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: Error checking auth status - $e');
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
