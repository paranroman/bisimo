import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

/// Auth Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

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
      await _authRepository.signOut();
      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      _setError('Gagal keluar. Silakan coba lagi.');
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user is already logged in
  Future<void> checkAuthStatus() async {
    _setLoading(true);

    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _user = user;
        _isAuthenticated = true;
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
