import 'user_model.dart';

/// Cimo state model for mascot emotion state
class CimoStateModel {
  final EmotionType emotion;
  final String message;
  final bool isAnimating;

  const CimoStateModel({required this.emotion, this.message = '', this.isAnimating = false});

  factory CimoStateModel.neutral() => const CimoStateModel(
    emotion: EmotionType.neutral,
    message: 'Hai! Aku Cimo, teman emosi kamu!',
    isAnimating: false,
  );

  factory CimoStateModel.greeting() => const CimoStateModel(
    emotion: EmotionType.senang,
    message: 'Selamat datang! Bagaimana perasaanmu hari ini?',
    isAnimating: false,
  );

  CimoStateModel copyWith({EmotionType? emotion, String? message, bool? isAnimating}) {
    return CimoStateModel(
      emotion: emotion ?? this.emotion,
      message: message ?? this.message,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }

  /// Get Cimo response message based on emotion
  static String getResponseMessage(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.senang:
        return 'Wah, senang sekali melihatmu bahagia! 😊';
      case EmotionType.sedih:
        return 'Aku di sini untukmu. Ceritakan apa yang kamu rasakan ya...';
      case EmotionType.marah:
        return 'Aku mengerti kamu sedang kesal. Tarik napas dalam-dalam ya...';
      case EmotionType.takut:
        return 'Jangan khawatir, aku akan menemanimu. Kamu tidak sendirian.';
      case EmotionType.terkejut:
        return 'Wah, ada yang mengejutkan ya? Ceritakan dong!';
      case EmotionType.jijik:
        return 'Hmm, sepertinya ada yang tidak menyenangkan. Apa yang terjadi?';
      case EmotionType.neutral:
        return 'Hai! Aku Cimo, teman emosi kamu. Ada yang ingin kamu ceritakan?';
    }
  }
}
