import '../models/user_model.dart';
import '../models/emotion_model.dart';
import '../models/chat_message_model.dart';

/// Dummy data for development and testing
class DummyData {
  DummyData._();

  /// Dummy user
  static final UserModel user = UserModel(
    id: 'user_001',
    name: 'Siswa Bisimo',
    email: 'siswa@bisimo.app',
    createdAt: DateTime(2025, 1, 1),
  );

  /// Dummy emotion history
  static final List<EmotionModel> emotionHistory = [
    EmotionModel(
      type: EmotionType.joy,
      confidence: 0.92,
      detectedAt: DateTime.now().subtract(const Duration(hours: 1)),
      note: 'Setelah bermain dengan teman',
    ),
    EmotionModel(
      type: EmotionType.neutral,
      confidence: 0.85,
      detectedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    EmotionModel(
      type: EmotionType.sad,
      confidence: 0.78,
      detectedAt: DateTime.now().subtract(const Duration(days: 1)),
      note: 'PR yang sulit',
    ),
    EmotionModel(
      type: EmotionType.joy,
      confidence: 0.88,
      detectedAt: DateTime.now().subtract(const Duration(days: 2)),
      note: 'Dapat nilai bagus',
    ),
  ];

  /// Dummy chat messages
  static final List<ChatMessageModel> chatMessages = [
    ChatMessageModel(
      id: 'msg_001',
      content: 'Hai Cimo!',
      isFromUser: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ChatMessageModel(
      id: 'msg_002',
      content: 'Hai juga! 👋 Aku Cimo, teman emosi kamu. Bagaimana perasaanmu hari ini?',
      isFromUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    ChatMessageModel(
      id: 'msg_003',
      content: 'Aku sedang senang!',
      isFromUser: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    ChatMessageModel(
      id: 'msg_004',
      content: 'Wah senangnya! 🎉 Aku ikut bahagia mendengarnya. Apa yang membuatmu senang?',
      isFromUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  /// Cimo greeting messages
  static const List<String> cimoGreetings = [
    'Hai! Aku Cimo, teman emosi kamu! 👋',
    'Selamat datang! Bagaimana perasaanmu hari ini?',
    'Hai teman! Aku siap mendengarkan ceritamu 💙',
    'Halo! Senang bertemu denganmu! 😊',
  ];

  /// Get random Cimo greeting
  static String getRandomGreeting() {
    final index = DateTime.now().millisecond % cimoGreetings.length;
    return cimoGreetings[index];
  }
}
