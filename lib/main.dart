import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Crashlytics for error tracking
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  
  // Capture Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🔴 FLUTTER ERROR: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // Capture Dart errors from PlatformDispatcher
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 PLATFORM ERROR: $error');
    debugPrint('Stack trace: $stack');
    FirebaseCrashlytics.instance.recordError(error, stack);
    return true;
  };

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable immersive mode to hide system bars for a full-screen experience
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const BisimoApp());
}

