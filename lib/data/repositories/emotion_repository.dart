import '../models/emotion_model.dart';
import '../models/user_model.dart';

/// Emotion repository (dummy implementation)
class EmotionRepository {
  /// Simulate emotion detection from camera
  Future<EmotionModel> detectEmotionFromCamera() async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Return random dummy emotion
    final emotions = EmotionType.values;
    final randomIndex = DateTime.now().millisecond % emotions.length;

    return EmotionModel(
      type: emotions[randomIndex],
      confidence: 0.7 + (DateTime.now().millisecond % 30) / 100,
      detectedAt: DateTime.now(),
    );
  }

  /// Simulate emotion detection from sign language
  Future<EmotionModel> detectEmotionFromSignLanguage() async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    return EmotionModel(type: EmotionType.joy, confidence: 0.85, detectedAt: DateTime.now());
  }

  /// Simulate emotion analysis from text
  Future<EmotionModel> analyzeTextEmotion(String text) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 1));

    // Simple dummy logic based on keywords
    EmotionType type = EmotionType.neutral;

    final lowerText = text.toLowerCase();
    if (lowerText.contains('senang') ||
        lowerText.contains('happy') ||
        lowerText.contains('bahagia')) {
      type = EmotionType.joy;
    } else if (lowerText.contains('sedih') || lowerText.contains('sad')) {
      type = EmotionType.sad;
    } else if (lowerText.contains('marah') || lowerText.contains('kesal')) {
      type = EmotionType.angry;
    } else if (lowerText.contains('takut') || lowerText.contains('khawatir')) {
      type = EmotionType.fear;
    }

    return EmotionModel(type: type, confidence: 0.75, detectedAt: DateTime.now());
  }

  /// Get emotion history (dummy)
  Future<List<EmotionModel>> getEmotionHistory() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      EmotionModel(
        type: EmotionType.joy,
        confidence: 0.9,
        detectedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      EmotionModel(
        type: EmotionType.neutral,
        confidence: 0.8,
        detectedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      EmotionModel(
        type: EmotionType.sad,
        confidence: 0.75,
        detectedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}
