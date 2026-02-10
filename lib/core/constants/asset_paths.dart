/// Bisimo Asset Paths
class AssetPaths {
  AssetPaths._();

  // Base Paths
  static const String _screens = 'assets/Screens';
  static const String _auth = 'assets/Screens/Auth';
  static const String _cimo = 'assets/Screens/Cimo';
  static const String _home = 'assets/Screens/Home';
  static const String _splash = 'assets/Screens/Splash';
  static const String _models = 'assets/Models';

  // Background
  static const String mainBackground = '$_screens/main_background.png';
  static const String homeBackground = '$_home/home_background.png';
  static const String navigationBackground = '$_screens/navigation-background.png';
  static const String settingBackground = '$_screens/setting-background.png';
  static const String profilBackground = '$_screens/profil-background.png';

  // App Icon / Splash
  static const String iconBisimo = '$_splash/icon_bisimo.png';

  // Auth Screens
  static const String signInHeader = '$_auth/signin_header.png';
  static const String signUpHeader = '$_auth/signup_header.png';
  static const String welcomeCimo = '$_auth/welcome_cimo.png';

  // Cimo Emotions
  static const String cimoJoy = '$_cimo/CIMO JOY.png';
  static const String cimoSad = '$_cimo/CIMO SAD.png';
  static const String cimoAngry = '$_cimo/CIMO ANGRY.png';
  static const String cimoFear = '$_cimo/CIMO FEAR.png';
  static const String cimoSurprise = '$_cimo/CIMO SURPRISE.png';
  static const String cimoDisgust = '$_cimo/CIMO DISGUST.png';

  // Models
  static const String emotionModel = '$_models/emotion_model.tflite';
  static const String handLandmarkModel = '$_models/hand_landmark_full.tflite';

  /// Get Cimo image path by emotion name
  static String getCimoByEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'senang':
        return cimoJoy;
      case 'sedih':
        return cimoSad;
      case 'marah':
        return cimoAngry;
      case 'takut':
        return cimoFear;
      case 'terkejut':
        return cimoSurprise;
      case 'jijik':
        return cimoDisgust;
      default:
        return cimoJoy;
    }
  }
}
