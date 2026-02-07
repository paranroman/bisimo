import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../features/auth/screens/profile_data_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/emotion_detection/screens/camera_screen.dart';
import '../../features/emotion_detection/screens/emotion_loading_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/student_profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/wali_kelas/screens/wali_dashboard_screen.dart';

/// Bisimo App Router Configuration
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Welcome Screen
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Sign In Screen
      GoRoute(
        path: AppRoutes.signIn,
        name: 'signIn',
        builder: (context, state) => const SignInScreen(),
      ),

      // Sign Up Screen
      GoRoute(
        path: AppRoutes.signUp,
        name: 'signUp',
        builder: (context, state) => const SignUpScreen(),
      ),

      // Profile Data Screen
      GoRoute(
        path: AppRoutes.profileData,
        name: 'profileData',
        builder: (context, state) => const ProfileDataScreen(),
      ),

      // Home Screen
      GoRoute(path: AppRoutes.home, name: 'home', builder: (context, state) => const HomeScreen()),

      // Wali Kelas Dashboard
      GoRoute(
        path: AppRoutes.waliDashboard,
        name: 'waliDashboard',
        builder: (context, state) => const WaliDashboardScreen(),
      ),

      // Camera Screen
      GoRoute(
        path: AppRoutes.camera,
        name: 'camera',
        builder: (context, state) => const CameraScreen(),
      ),

      // Emotion Detection Loading Screen
      // Menerima face image bytes + motion sequence dari CameraScreen
      // dan memanggil cloud API selama animasi loading.
      GoRoute(
        path: AppRoutes.emotionDetection,
        name: 'emotionDetection',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EmotionLoadingScreen(
            faceImageBytes: extra?['faceImageBytes'] as Uint8List?,
            motionSequence: extra?['motionSequence'] as List<List<double>>?,
          );
        },
      ),

      // Chat Screen
      // Menerima hasil deteksi emosi dari EmotionLoadingScreen.
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            faceEmotion: extra?['faceEmotion'] as String?,
            faceConfidence: extra?['faceConfidence'] as double?,
            motionEmotion: extra?['motionEmotion'] as String?,
            motionConfidence: extra?['motionConfidence'] as double?,
            finalEmotion: extra?['finalEmotion'] as String? ?? 'Neutral',
            finalConfidence: extra?['finalConfidence'] as double? ?? 0.0,
          );
        },
      ),

      // Edit Profile Screen
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // Student Profile Screen
      GoRoute(
        path: AppRoutes.studentProfile,
        name: 'studentProfile',
        builder: (context, state) => const StudentProfileScreen(),
      ),

      // Settings Screen
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route not found: ${state.uri.path}'))),
  );
}
