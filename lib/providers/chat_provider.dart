import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/chat_message_model.dart';
import '../features/chat/services/chat_service.dart';
import '../features/emotion_detection/services/emotion_api_service.dart';
import 'auth_provider.dart' as auth;

/// Manages the chat state and communication with the ChatService.
class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required ChatService chatService,
    required auth.AuthProvider authProvider,
  })  : _chatService = chatService,
        _authProvider = authProvider;

  final ChatService _chatService;
  final auth.AuthProvider _authProvider;

  List<ChatMessageModel> _messages = [];
  bool _isTyping = false;
  String? _errorMessage;
  String? _sessionId;

  /// Latest detected emotion label (updated from camera or text prediction)
  String? _latestEmotion;
  double? _latestEmotionConfidence;

  // Getters
  List<ChatMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;
  String? get errorMessage => _errorMessage;
  String? get latestEmotion => _latestEmotion;
  double? get latestEmotionConfidence => _latestEmotionConfidence;

  /// Initializes a new chat session.
  Future<void> startChatSession({CombinedEmotionResult? emotionResult}) async {
    _clearChatInternally();
    _setTyping(true);

    try {
      // Initialize latestEmotion from camera result if available
      if (emotionResult != null) {
        _latestEmotion = emotionResult.finalEmotion.emotion;
        _latestEmotionConfidence = emotionResult.finalEmotion.confidence;
      }

      // Check BOTH auth methods: Firebase Auth (teacher) OR Student Session
      bool hasValidAuth = false;

      // Method 1: Check Student Session (Logical Auth - token-based)
      if (_authProvider.isStudentMode && _authProvider.studentSession != null) {
        hasValidAuth = true;
        debugPrint('[ChatProvider] ✅ Student session valid: ${_authProvider.displayName}');
      }
      // Method 2: Check Firebase Auth (Teacher/Wali)
      else if (FirebaseAuth.instance.currentUser != null) {
        hasValidAuth = true;
        debugPrint('[ChatProvider] ✅ Firebase Auth valid: ${FirebaseAuth.instance.currentUser?.email}');
      } else {
        // Try waiting for Firebase Auth to restore (max 5 seconds)
        debugPrint('[ChatProvider] ⏳ Menunggu authentication...');
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Re-check both methods
          if (_authProvider.isStudentMode && _authProvider.studentSession != null) {
            hasValidAuth = true;
            debugPrint('[ChatProvider] ✅ Student session restored');
            break;
          } else if (FirebaseAuth.instance.currentUser != null) {
            hasValidAuth = true;
            debugPrint('[ChatProvider] ✅ Firebase Auth restored');
            break;
          }
        }
      }

      if (!hasValidAuth) {
        debugPrint('[ChatProvider] ❌ No valid authentication found');
        throw Exception('Sesi login tidak valid. Silakan login ulang.');
      }

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
      debugPrint('[ChatProvider] ❌ startChatSession error: $e');
      final errorMsg = e.toString().contains('login')
          ? 'Sesi login habis. Silakan login ulang.'
          : 'Gagal memulai sesi chat. Coba lagi nanti.';
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
    _addMessage(
      ChatMessageModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        content: content.trim(),
        isFromUser: true,
        timestamp: DateTime.now(),
      ),
    );
    _setTyping(true);

    try {
      final response = await _chatService.postMessage(
        sessionId: _sessionId!,
        message: content.trim(),
      );

      final reply = response['reply'] as String;
      final textPrediction = response['text_prediction'] as Map<String, dynamic>?;

      // Update last user message with detected emotion from IndoBERT
      if (textPrediction != null && _messages.isNotEmpty) {
        final lastUserIdx = _messages.lastIndexWhere((m) => m.isFromUser);
        if (lastUserIdx >= 0) {
          final label = textPrediction['label'] as String?;
          final confidence = (textPrediction['confidence'] as num?)?.toDouble();
          _messages[lastUserIdx] = _messages[lastUserIdx].copyWith(
            detectedEmotion: label,
            emotionConfidence: confidence,
          );

          // Update the Cimo card emotion with the latest text prediction
          if (label != null && label.isNotEmpty) {
            _latestEmotion = label;
            _latestEmotionConfidence = confidence;
          }
        }
      }

      _addCimoMessage(reply);
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
    _addMessage(
      ChatMessageModel(
        id: 'cimo_${DateTime.now().millisecondsSinceEpoch}',
        content: content.trim(),
        isFromUser: false,
        timestamp: DateTime.now(),
        status: status,
      ),
    );
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
    _latestEmotion = null;
    _latestEmotionConfidence = null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
