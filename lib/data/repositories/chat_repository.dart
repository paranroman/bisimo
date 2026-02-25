import '../models/chat_message_model.dart';

/// Chat repository (dummy implementation)
class ChatRepository {
  /// Get Cimo response for user message
  Future<ChatMessageModel> getCimoResponse(String userMessage) async {
    // Simulate thinking delay
    await Future.delayed(const Duration(seconds: 1));

    // Simple dummy responses
    String response = _generateDummyResponse(userMessage);

    return ChatMessageModel(
      id: 'cimo_${DateTime.now().millisecondsSinceEpoch}',
      content: response,
      isFromUser: false,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  /// Generate dummy response based on user message
  String _generateDummyResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('halo') ||
        lowerMessage.contains('hai') ||
        lowerMessage.contains('hi')) {
      return 'Hai juga! 👋 Aku Cimo, teman emosi kamu. Ada yang ingin kamu ceritakan hari ini?';
    }

    if (lowerMessage.contains('sedih') || lowerMessage.contains('menangis')) {
      return 'Aku di sini untukmu 💙 Tidak apa-apa untuk merasa sedih. Mau cerita apa yang terjadi?';
    }

    if (lowerMessage.contains('senang') ||
        lowerMessage.contains('bahagia') ||
        lowerMessage.contains('happy')) {
      return 'Wah senangnya! 🎉 Aku ikut bahagia mendengarnya. Apa yang membuatmu senang?';
    }

    if (lowerMessage.contains('marah') || lowerMessage.contains('kesal')) {
      return 'Aku mengerti kamu sedang kesal 😤 Tarik napas dalam-dalam ya. Mau ceritakan apa yang terjadi?';
    }

    if (lowerMessage.contains('takut') ||
        lowerMessage.contains('khawatir') ||
        lowerMessage.contains('cemas')) {
      return 'Jangan khawatir, aku ada di sini 🤗 Kamu tidak sendirian. Apa yang membuatmu takut?';
    }

    if (lowerMessage.contains('terima kasih') || lowerMessage.contains('makasih')) {
      return 'Sama-sama! 😊 Aku selalu senang bisa membantu. Ada yang lain yang ingin kamu ceritakan?';
    }

    if (lowerMessage.contains('?')) {
      return 'Hmm, pertanyaan yang menarik! 🤔 Coba ceritakan lebih detail ya, biar aku bisa membantu.';
    }

    // Default response
    return 'Aku mendengarkan 👂 Terima kasih sudah berbagi. Mau cerita lebih lanjut?';
  }

  /// Get chat history (dummy)
  Future<List<ChatMessageModel>> getChatHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return []; // Empty history for fresh start
  }
}

