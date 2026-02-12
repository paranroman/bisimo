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

  // Cimo Emotions (lowercase filenames)
  static const String cimoJoy = '$_cimo/cimo_joy.png';
  static const String cimoSad = '$_cimo/cimo_sad.png';
  static const String cimoAngry = '$_cimo/cimo_angry.png';
  static const String cimoFear = '$_cimo/cimo_fear.png';
  static const String cimoSurprise = '$_cimo/cimo_surprise.png';
  static const String cimoDisgust = '$_cimo/cimo_disgust.png';

  // Models
  static const String emotionModel = '$_models/emotion_model.tflite';
  static const String handLandmarkModel = '$_models/hand_landmark_full.tflite';

  /// Get Cimo image path by emotion name
  static String getCimoByEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'senang':
      case 'happy': // Added for mapping
      case 'joy':   // Added for mapping
        return cimoJoy;
      case 'sedih':
      case 'sad':   // Added for mapping
        return cimoSad;
      case 'marah':
      case 'angry': // Added for mapping
        return cimoAngry;
      case 'takut':
      case 'fear':  // Added for mapping
        return cimoFear;
      case 'terkejut':
      case 'surprise': // Added for mapping
        return cimoSurprise;
      case 'jijik':
      case 'disgust': // Added for mapping
        return cimoDisgust;
      default:
        return cimoJoy; // Default to Joy
    }
  }
}
