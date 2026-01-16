import '../models/user_model.dart';

/// Auth repository (dummy implementation)
class AuthRepository {
  // Dummy user for testing
  static final UserModel _dummyUser = UserModel(
    id: 'user_001',
    name: 'Siswa Bisimo',
    email: 'siswa@bisimo.app',
    createdAt: DateTime.now(),
  );

  /// Simulate sign in
  Future<UserModel?> signIn(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Dummy validation
    if (email.isNotEmpty && password.length >= 6) {
      return _dummyUser.copyWith(email: email);
    }
    return null;
  }

  /// Simulate sign up
  Future<UserModel?> signUp(String name, String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Dummy validation
    if (name.isNotEmpty && email.isNotEmpty && password.length >= 6) {
      return _dummyUser.copyWith(name: name, email: email, createdAt: DateTime.now());
    }
    return null;
  }

  /// Simulate sign out
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Get current user (dummy)
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return null; // Return null to simulate not logged in
  }
}
