import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/user_profile.dart';

/// Profile Service - Handles profile data storage in Firebase Firestore and local cache
class ProfileService {
  static const String _profileKey = 'user_profile';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the profiles collection reference
  CollectionReference<Map<String, dynamic>> get _profilesCollection =>
      _firestore.collection('profiles');

  /// Save profile to Firestore and local storage
  Future<void> saveProfile(UserProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Create profile with user's UID
    final profileWithUid = UserProfile(
      uid: user.uid,
      nama: profile.nama,
      namaPanggilan: profile.namaPanggilan,
      tanggalLahir: profile.tanggalLahir,
      jenisKelamin: profile.jenisKelamin,
      tingkatPendidikan: profile.tingkatPendidikan,
      namaOrangTua: profile.namaOrangTua,
      kontakOrangTua: profile.kontakOrangTua,
      email: user.email ?? profile.email,
      photoUrl: user.photoURL ?? profile.photoUrl,
      createdAt: profile.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Firestore
    await _profilesCollection.doc(user.uid).set(profileWithUid.toMap(), SetOptions(merge: true));

    // Save to local cache
    await _saveToLocal(profileWithUid);
  }

  /// Get profile - first try Firestore, fallback to local
  Future<UserProfile?> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return _getFromLocal();
    }

    try {
      // Try to get from Firestore
      final doc = await _profilesCollection.doc(user.uid).get();
      if (doc.exists) {
        final profile = UserProfile.fromFirestore(doc);
        // Update local cache
        await _saveToLocal(profile);
        return profile;
      }
    } catch (e) {
      // If Firestore fails, try local cache
      debugPrint('Error fetching from Firestore: $e');
    }

    // Fallback to local storage
    return _getFromLocal();
  }

  /// Check if profile exists in Firestore
  Future<bool> hasProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return _hasLocalProfile();
    }

    try {
      final doc = await _profilesCollection.doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      return _hasLocalProfile();
    }
  }

  /// Clear profile data (local and optionally Firestore)
  Future<void> clearProfile({bool deleteFromFirestore = false}) async {
    final user = _auth.currentUser;

    // Clear local
    await _clearLocal();

    // Optionally delete from Firestore
    if (deleteFromFirestore && user != null) {
      try {
        await _profilesCollection.doc(user.uid).delete();
      } catch (e) {
        debugPrint('Error deleting from Firestore: $e');
      }
    }
  }

  /// Update profile
  Future<void> updateProfile(UserProfile profile) async {
    await saveProfile(profile);
  }

  /// Sync local profile to Firestore (useful after Google Sign-In)
  Future<void> syncToFirestore() async {
    final localProfile = await _getFromLocal();
    if (localProfile != null) {
      await saveProfile(localProfile);
    }
  }

  // ============ Local Storage Methods ============

  Future<void> _saveToLocal(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = jsonEncode(profile.toLocalMap());
    await prefs.setString(_profileKey, profileJson);
  }

  Future<UserProfile?> _getFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);
    if (profileJson != null) {
      final map = jsonDecode(profileJson) as Map<String, dynamic>;
      return UserProfile.fromMap(map);
    }
    return null;
  }

  Future<bool> _hasLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_profileKey);
  }

  Future<void> _clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }
}
