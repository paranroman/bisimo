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
import '../../features/emotion_detection/screens/detection_error_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/student_profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/wali_kelas/screens/wali_dashboard_screen.dart';
import '../../features/wali_kelas/screens/student_detail_screen.dart';
import '../../features/emotion_detection/services/emotion_api_service.dart';
import '../../data/models/student_model.dart';

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

      // Student Login — redirects to SignIn with Murid tab pre-selected
      GoRoute(
        path: AppRoutes.studentLogin,
        name: 'studentLogin',
        redirect: (context, state) => AppRoutes.signIn,
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

      // Student Detail Screen (Wali views a student profile)
      GoRoute(
        path: AppRoutes.studentDetail,
        name: 'studentDetail',
        builder: (context, state) {
          final student = state.extra as StudentModel;
          return StudentDetailScreen(student: student);
        },
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
      // Menerima CombinedEmotionResult dari EmotionLoadingScreen (dengan kamera)
      // atau null jika langsung dari Home (mode text-only).
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) {
          // extra bisa berupa CombinedEmotionResult (dari kamera)
          // atau null (text-only dari Home)
          final emotionResult = state.extra as CombinedEmotionResult?;
          return ChatScreen(emotionResult: emotionResult);
        },
      ),

      // Detection Error Screen
      GoRoute(
        path: AppRoutes.detectionError,
        name: 'detectionError',
        builder: (context, state) {
          final errorType = state.extra as DetectionErrorType? ?? DetectionErrorType.apiError;
          return DetectionErrorScreen(errorType: errorType);
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
