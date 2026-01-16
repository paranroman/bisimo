import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/emotion_detection/screens/camera_screen.dart';
import '../../features/emotion_detection/screens/emotion_loading_screen.dart';
import '../../features/chat/screens/chat_screen.dart';

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

      // Home Screen
      GoRoute(path: AppRoutes.home, name: 'home', builder: (context, state) => const HomeScreen()),

      // Camera Screen
      GoRoute(
        path: AppRoutes.camera,
        name: 'camera',
        builder: (context, state) => const CameraScreen(),
      ),

      // Emotion Detection Loading Screen
      GoRoute(
        path: AppRoutes.emotionDetection,
        name: 'emotionDetection',
        builder: (context, state) => const EmotionLoadingScreen(),
      ),

      // Chat Screen
      GoRoute(path: AppRoutes.chat, name: 'chat', builder: (context, state) => const ChatScreen()),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route not found: ${state.uri.path}'))),
  );
}
