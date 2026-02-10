import 'package:flutter/material.dart';
import '../../../data/models/chat_message_model.dart';
import '../features/chat/services/chat_service.dart';
import '../features/emotion_detection/services/emotion_api_service.dart';

/// Manages the chat state and communication with the ChatService.
class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatMessageModel> _messages = [];
  bool _isTyping = false;
  String? _errorMessage;
  String? _sessionId;

  // Getters
  List<ChatMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;
  String? get errorMessage => _errorMessage;

  /// Initializes a new chat session.
  Future<void> startChatSession({CombinedEmotionResult? emotionResult}) async {
    _clearChatInternally();
    _setTyping(true);

    try {
      final bool useCamera = emotionResult != null;
      final response = await _chatService.startSession(
        useCamera: useCamera,
        emotionResult: emotionResult,
      );

      _sessionId = response['session_id'];
      final initialMessage = response['response'] as String?;

      if (initialMessage != null && initialMessage.isNotEmpty) {
        _addCimoMessage(initialMessage);
      }
    } catch (e) {
      final errorMsg = 'Gagal memulai sesi chat. Coba lagi nanti.';
      _setError(errorMsg);
      _addCimoMessage(errorMsg, status: MessageStatus.failed);
    } finally {
      _setTyping(false);
    }
  }

  /// Sends a user message to the active chat session.
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _isTyping) return;
    if (_sessionId == null) {
      const errorMsg = 'Sesi chat tidak ditemukan. Coba kembali ke beranda.';
      _setError(errorMsg);
      _addCimoMessage(errorMsg, status: MessageStatus.failed);
      notifyListeners();
      return;
    }

    _clearError();
    _addMessage(ChatMessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: content.trim(),
      isFromUser: true,
      timestamp: DateTime.now(),
    ));
    _setTyping(true);

    try {
      final cimoResponse = await _chatService.postMessage(
        sessionId: _sessionId!,
        message: content.trim(),
      );
      _addCimoMessage(cimoResponse);
    } catch (e) {
      const errorMsg = 'Maaf, aku sedang tidak bisa merespons. Coba lagi ya.';
      _setError(errorMsg);
      _addCimoMessage(errorMsg, status: MessageStatus.failed);
    } finally {
      _setTyping(false);
    }
  }

  void clearChat() {
    _clearChatInternally();
    notifyListeners();
  }

  void _addCimoMessage(String content, {MessageStatus status = MessageStatus.sent}) {
    if (content.trim().isEmpty) return;
    _addMessage(ChatMessageModel(
      id: 'cimo_${DateTime.now().millisecondsSinceEpoch}',
      content: content.trim(),
      isFromUser: false,
      timestamp: DateTime.now(),
      status: status,
    ));
  }

  void _addMessage(ChatMessageModel message) {
    _messages.add(message);
    notifyListeners(); // Notify listeners whenever a message is added
  }

  void _setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
  }

  void _setError(String message) {
    if (_errorMessage != message) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _clearChatInternally() {
    _messages = [];
    _sessionId = null;
    _errorMessage = null;
    _isTyping = false;
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}
