import 'user_model.dart';

/// Emotion model for detected/selected emotion
class EmotionModel {
  final EmotionType type;
  final double confidence; // 0.0 - 1.0
  final DateTime detectedAt;
  final String? note;

  const EmotionModel({
    required this.type,
    this.confidence = 1.0,
    required this.detectedAt,
    this.note,
  });

  factory EmotionModel.neutral() =>
      EmotionModel(type: EmotionType.neutral, confidence: 1.0, detectedAt: DateTime.now());

  String get emotionName {
    switch (type) {
      case EmotionType.joy:
        return 'Senang';
      case EmotionType.sad:
        return 'Sedih';
      case EmotionType.angry:
        return 'Marah';
      case EmotionType.fear:
        return 'Takut';
      case EmotionType.surprise:
        return 'Terkejut';
      case EmotionType.disgust:
        return 'Jijik';
      case EmotionType.neutral:
        return 'Netral';
    }
  }

  EmotionModel copyWith({
    EmotionType? type,
    double? confidence,
    DateTime? detectedAt,
    String? note,
  }) {
    return EmotionModel(
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      detectedAt: detectedAt ?? this.detectedAt,
      note: note ?? this.note,
    );
  }
}
