import 'package:flutter/material.dart';
import '../data/models/emotion_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/emotion_repository.dart';

/// Emotion Provider for managing emotion detection state
class EmotionProvider extends ChangeNotifier {
  final EmotionRepository _emotionRepository = EmotionRepository();

  EmotionModel? _currentEmotion;
  List<EmotionModel> _emotionHistory = [];
  bool _isDetecting = false;
  String? _errorMessage;

  // Getters
  EmotionModel? get currentEmotion => _currentEmotion;
  List<EmotionModel> get emotionHistory => _emotionHistory;
  bool get isDetecting => _isDetecting;
  String? get errorMessage => _errorMessage;

  /// Set emotion manually (from mood selector)
  void setEmotion(EmotionType type) {
    _currentEmotion = EmotionModel(type: type, confidence: 1.0, detectedAt: DateTime.now());
    _addToHistory(_currentEmotion!);
    notifyListeners();
  }

  /// Detect emotion from camera
  Future<void> detectFromCamera() async {
    _setDetecting(true);
    _clearError();

    try {
      final emotion = await _emotionRepository.detectEmotionFromCamera();
      _currentEmotion = emotion;
      _addToHistory(emotion);
      notifyListeners();
    } catch (e) {
      _setError('Gagal mendeteksi emosi. Silakan coba lagi.');
    } finally {
      _setDetecting(false);
    }
  }

  /// Detect emotion from sign language
  Future<void> detectFromSignLanguage() async {
    _setDetecting(true);
    _clearError();

    try {
      final emotion = await _emotionRepository.detectEmotionFromSignLanguage();
      _currentEmotion = emotion;
      _addToHistory(emotion);
      notifyListeners();
    } catch (e) {
      _setError('Gagal mendeteksi bahasa isyarat. Silakan coba lagi.');
    } finally {
      _setDetecting(false);
    }
  }

  /// Analyze emotion from text
  Future<void> analyzeFromText(String text) async {
    _setDetecting(true);
    _clearError();

    try {
      final emotion = await _emotionRepository.analyzeTextEmotion(text);
      _currentEmotion = emotion;
      notifyListeners();
    } catch (e) {
      _setError('Gagal menganalisis teks. Silakan coba lagi.');
    } finally {
      _setDetecting(false);
    }
  }

  /// Load emotion history
  Future<void> loadHistory() async {
    try {
      _emotionHistory = await _emotionRepository.getEmotionHistory();
      notifyListeners();
    } catch (e) {
      // Silent fail for history
    }
  }

  /// Clear current emotion
  void clearCurrentEmotion() {
    _currentEmotion = null;
    notifyListeners();
  }

  // Private helper methods
  void _setDetecting(bool detecting) {
    _isDetecting = detecting;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _addToHistory(EmotionModel emotion) {
    _emotionHistory.insert(0, emotion);
    // Keep only last 50 entries
    if (_emotionHistory.length > 50) {
      _emotionHistory = _emotionHistory.take(50).toList();
    }
  }
}
