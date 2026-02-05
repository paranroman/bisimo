import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/models/student_session.dart';
import '../data/repositories/auth_repository.dart';
import '../features/auth/services/student_auth_service.dart';

/// Auth Provider for managing authentication state
/// Supports both Wali Kelas (Firebase Auth) and Student (Token Auth) authentication
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final StudentAuthService _studentAuthService = StudentAuthService();

  UserModel? _user;
  StudentSession? _studentSession;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  bool _isStudentMode = false;

  // Getters
  UserModel? get user => _user;
  StudentSession? get studentSession => _studentSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isStudentMode => _isStudentMode;

  /// Get display name (works for both user and student)
  String get displayName {
    if (_isStudentMode && _studentSession != null) {
      return _studentSession!.displayName;
    }
    return _user?.name ?? '';
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signIn(email, password);
      if (user != null) {
        _user = user;
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _setError('Email atau password salah');
        return false;
      }
    } catch (e) {
      _setError('Terjadi kesalahan. Silakan coba lagi.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with name, email, and password
  Future<bool> signUp(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signUp(name, email, password);
      if (user != null) {
        _user = user;
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _setError('Gagal membuat akun. Silakan coba lagi.');
        return false;
      }
    } catch (e) {
      _setError('Terjadi kesalahan. Silakan coba lagi.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
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

  /// Check if user is already logged in
  Future<void> checkAuthStatus() async {
    _setLoading(true);

    try {
      // First check for student session
      final studentSession = await _studentAuthService.getStudentSession();
      if (studentSession != null && studentSession.isValid) {
        _studentSession = studentSession;
        _isAuthenticated = true;
        _isStudentMode = true;
        notifyListeners();
        _setLoading(false);
        return;
      }

      // Then check for Wali Kelas session
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _user = user;
        _isAuthenticated = true;
        _isStudentMode = false;
      }
      notifyListeners();
    } catch (e) {
      // User not logged in
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
