import 'package:flutter/material.dart';
import '../data/models/chat_message_model.dart';
import '../data/repositories/chat_repository.dart';

/// Chat Provider for managing chat with Cimo
class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();

  List<ChatMessageModel> _messages = [];
  bool _isTyping = false;
  String? _errorMessage;

  // Getters
  List<ChatMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;
  String? get errorMessage => _errorMessage;
  bool get hasMessages => _messages.isNotEmpty;

  /// Send message to Cimo
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: content.trim(),
      isFromUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    _messages.add(userMessage);
    notifyListeners();

    // Get Cimo response
    _setTyping(true);

    try {
      final cimoResponse = await _chatRepository.getCimoResponse(content);
      _messages.add(cimoResponse);
      notifyListeners();
    } catch (e) {
      _setError('Gagal mendapat respons dari Cimo');
      // Add error message as Cimo response
      _messages.add(
        ChatMessageModel(
          id: 'cimo_error_${DateTime.now().millisecondsSinceEpoch}',
          content: 'Maaf, aku sedang tidak bisa merespons. Coba lagi ya! 🙏',
          isFromUser: false,
          timestamp: DateTime.now(),
          status: MessageStatus.failed,
        ),
      );
      notifyListeners();
    } finally {
      _setTyping(false);
    }
  }

  /// Load chat history
  Future<void> loadHistory() async {
    try {
      _messages = await _chatRepository.getChatHistory();
      notifyListeners();
    } catch (e) {
      // Silent fail for history
    }
  }

  /// Clear chat history
  void clearChat() {
    _messages.clear();
    _clearError();
    notifyListeners();
  }

  /// Add initial greeting from Cimo
  void addCimoGreeting(String message) {
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessageModel(
          id: 'cimo_greeting_${DateTime.now().millisecondsSinceEpoch}',
          content: message,
          isFromUser: false,
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
        ),
      );
      notifyListeners();
    }
  }

  // Private helper methods
  void _setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
