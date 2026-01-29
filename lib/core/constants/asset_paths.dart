/// Bisimo Asset Paths
class AssetPaths {
  AssetPaths._();

  // Base Paths
  static const String _screens = 'assets/Screens';
  static const String _auth = 'assets/Screens/Auth';
  static const String _cimo = 'assets/Screens/Cimo';
  static const String _home = 'assets/Screens/Home';
  static const String _splash = 'assets/Screens/Splash';
  static const String _uiux = 'assets/UIUX';

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

  // UI/UX Reference (untuk development reference)
  static const String uiCamera = '$_uiux/Camera.png';
  static const String uiChatFromCamera = '$_uiux/Chat from Camera option.png';
  static const String uiChatLoading = '$_uiux/Chat Loading.png';
  static const String uiHome = '$_uiux/Home.png';
  static const String uiSignIn = '$_uiux/Sign In.png';
  static const String uiSignUp = '$_uiux/Sign up.png';
  static const String uiSplashScreen = '$_uiux/Splash Screen.png';
  static const String uiWelcome = '$_uiux/Welcome.png';

  /// Get Cimo image path by emotion name
  static String getCimoByEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
      case 'happy':
      case 'senang':
        return cimoJoy;
      case 'sad':
      case 'sedih':
        return cimoSad;
      case 'angry':
      case 'marah':
        return cimoAngry;
      case 'fear':
      case 'takut':
        return cimoFear;
      case 'surprise':
      case 'terkejut':
        return cimoSurprise;
      case 'disgust':
      case 'jijik':
        return cimoDisgust;
      default:
        return cimoJoy; // Default to joy
    }
  }
}
