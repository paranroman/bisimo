import 'package:flutter/material.dart';
import '../features/emotion_detection/services/emotion_api_service.dart';
import '../features/chat/services/chat_service.dart';

/// Provider untuk mengelola instance API services.
///
/// Menggantikan global variable `service` agar lebih testable dan
/// URL bisa diganti saat pindah environment (staging/production).
class ApiProvider extends ChangeNotifier {
  // Ganti URL ini saat pindah environment (staging/production)
  static const String _chatbotUrl = 'https://mistral-chatbot-o4xbdy3cxq-et.a.run.app';

  late final EmotionApiService emotionApi;
  late final ChatService chatService;

  ApiProvider() {
    emotionApi = EmotionApiService(chatbotUrl: _chatbotUrl);
    chatService = ChatService(chatbotUrl: _chatbotUrl);
  }

  @override
  void dispose() {
    emotionApi.dispose();
    chatService.dispose();
    super.dispose();
  }
}

