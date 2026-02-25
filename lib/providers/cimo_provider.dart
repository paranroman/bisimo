import 'package:flutter/material.dart';
import '../data/models/cimo_state_model.dart';
import '../data/models/user_model.dart';

/// Cimo Provider for managing Cimo mascot state
class CimoProvider extends ChangeNotifier {
  CimoStateModel _state = CimoStateModel.neutral();

  // Getters
  CimoStateModel get state => _state;
  EmotionType get currentEmotion => _state.emotion;
  String get currentMessage => _state.message;
  bool get isAnimating => _state.isAnimating;

  /// Set Cimo emotion
  void setEmotion(EmotionType emotion, {String? customMessage}) {
    _state = _state.copyWith(
      emotion: emotion,
      message: customMessage ?? CimoStateModel.getResponseMessage(emotion),
    );
    notifyListeners();
  }

  /// Set Cimo to neutral state
  void setNeutral() {
    _state = CimoStateModel.neutral();
    notifyListeners();
  }

  /// Set Cimo to greeting state
  void setGreeting() {
    _state = CimoStateModel.greeting();
    notifyListeners();
  }

  /// Set custom message
  void setMessage(String message) {
    _state = _state.copyWith(message: message);
    notifyListeners();
  }

  /// Set animation state
  void setAnimating(bool animating) {
    _state = _state.copyWith(isAnimating: animating);
    notifyListeners();
  }

  /// React to user emotion (Cimo mirrors or responds to user's emotion)
  void reactToUserEmotion(EmotionType userEmotion) {
    // Cimo responds empathetically to user's emotion
    switch (userEmotion) {
      case EmotionType.senang:
        setEmotion(EmotionType.senang, customMessage: 'Wah, senang sekali melihatmu bahagia! 😊');
        break;
      case EmotionType.sedih:
        setEmotion(
          EmotionType.sedih,
          customMessage: 'Aku di sini untukmu 💙 Ceritakan apa yang kamu rasakan ya...',
        );
        break;
      case EmotionType.marah:
        setEmotion(
          EmotionType.neutral,
          customMessage: 'Aku mengerti kamu sedang kesal. Tarik napas dalam-dalam ya...',
        );
        break;
      case EmotionType.takut:
        setEmotion(
          EmotionType.neutral,
          customMessage: 'Jangan khawatir, aku akan menemanimu. Kamu tidak sendirian 🤗',
        );
        break;
      case EmotionType.terkejut:
        setEmotion(
          EmotionType.terkejut,
          customMessage: 'Wah, ada yang mengejutkan ya? Ceritakan dong!',
        );
        break;
      case EmotionType.jijik:
        setEmotion(
          EmotionType.neutral,
          customMessage: 'Hmm, sepertinya ada yang tidak menyenangkan. Apa yang terjadi?',
        );
        break;
      case EmotionType.neutral:
        setNeutral();
        break;
    }
  }
}

