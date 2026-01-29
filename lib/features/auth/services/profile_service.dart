import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/user_profile.dart';

/// Profile Service - Handles profile data storage and retrieval
class ProfileService {
  static const String _profileKey = 'user_profile';

  /// Save profile to local storage
  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = jsonEncode(profile.toMap());
    await prefs.setString(_profileKey, profileJson);
  }

  /// Get profile from local storage
  Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);
    if (profileJson != null) {
      final map = jsonDecode(profileJson) as Map<String, dynamic>;
      return UserProfile.fromMap(map);
    }
    return null;
  }

  /// Check if profile exists
  Future<bool> hasProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_profileKey);
  }

  /// Clear profile data
  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }

  /// Update profile
  Future<void> updateProfile(UserProfile profile) async {
    await saveProfile(profile);
  }
}
