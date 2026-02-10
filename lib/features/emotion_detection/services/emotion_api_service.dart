import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Service untuk komunikasi dengan Chatbot API Gateway.
///
/// ## Arsitektur (aman):
/// ```
/// Flutter ──Firebase Token──→ Chatbot Gateway (satu-satunya endpoint)
///                                ├──→ IndoBERT       (API key di server)
///                                ├──→ EfficientNetB2 (API key di server)
///                                ├──→ BiLSTM         (API key di server)
///                                └──→ Mistral AI     (API key di server)
/// ```
///
/// **Nol API key di Flutter.** Semua key tersimpan aman di Cloud Run env vars.
///
/// ## Setup:
///
/// ```dart
// / final service = EmotionApiService(
// /   chatbotUrl: 'https://mistral-chatbot-xxxxx.run.app',
/// );
/// ```

class EmotionApiService {
  EmotionApiService({required String chatbotUrl, http.Client? httpClient})
    : _chatbotUrl = chatbotUrl,
      _client = httpClient ?? http.Client();

  /// URL Chatbot API Gateway — satu-satunya endpoint.
  final String _chatbotUrl;

  final http.Client _client;

  /// Session ID aktif.
  String? _sessionId;

  /// Getter untuk session ID saat ini.
  String? get sessionId => _sessionId;

  static const Duration _predictTimeout = Duration(seconds: 15);
  static const Duration _chatTimeout = Duration(seconds: 30);

  // ══════════════════════════════════════════════════════════════════════
  //  Firebase Auth Helper
  // ══════════════════════════════════════════════════════════════════════

  /// Dapatkan Firebase ID Token dari user yang sedang login.
  Future<String> _getFirebaseToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw EmotionApiException('User belum login. Silakan login terlebih dulu.');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw EmotionApiException('Gagal mendapatkan Firebase token.');
    }
    return token;
  }

  // ══════════════════════════════════════════════════════════════════════
  //  1. TEKS → IndoBERT (via Chatbot proxy)
  // ══════════════════════════════════════════════════════════════════════

  /// Kirim teks ke IndoBERT melalui Chatbot gateway.
  Future<EmotionResult> detectTextEmotion(String text) async {
    if (text.trim().isEmpty) {
      return EmotionResult(emotion: 'Neutral', confidence: 0.0);
    }
    return _postAndParse(path: '/predict-text', body: {'text': text}, label: 'TextEmotion');
  }

  /// Alias — backward compatibility.
  Future<EmotionResult> detectEmotion(String text) => detectTextEmotion(text);

  // ══════════════════════════════════════════════════════════════════════
  //  2. WAJAH → EfficientNetB2 (via Chatbot proxy)
  // ══════════════════════════════════════════════════════════════════════

  /// Kirim foto wajah (JPEG bytes 224×224) melalui Chatbot gateway.
  Future<EmotionResult> detectFaceEmotion(Uint8List faceImageBytes) async {
    final base64Image = base64Encode(faceImageBytes);
    return _postAndParse(
      path: '/predict-face',
      body: {'image_base64': base64Image},
      label: 'FaceEmotion',
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  3. ISYARAT BISINDO → BiLSTM (via Chatbot proxy)
  // ══════════════════════════════════════════════════════════════════════

  /// Kirim motion sequence (60 frames × 154 features) melalui Chatbot gateway.
  Future<EmotionResult> detectMotionEmotion(List<List<double>> motionSequence) async {
    return _postAndParse(
      path: '/predict-motion',
      body: {'data': motionSequence},
      label: 'MotionEmotion',
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  4. SKENARIO 1 — COMBINED (kamera) → /predict-combined
  // ══════════════════════════════════════════════════════════════════════

  /// Kirim face + motion untuk prediksi gabungan + mulai session chatbot.
  Future<CombinedEmotionResult> detectCombinedEmotion({
    required Uint8List faceImageBytes,
    required List<List<double>> motionSequence,
  }) async {
    final base64Image = base64Encode(faceImageBytes);

    final responseBody = await _postRaw(
      path: '/predict-combined',
      body: {'face_image': base64Image, 'motion_landmarks': motionSequence},
      label: 'CombinedEmotion',
      timeout: _chatTimeout,
    );

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final facePred = json['face_prediction'] as Map<String, dynamic>;
    final motionPred = json['motion_prediction'] as Map<String, dynamic>;

    final result = CombinedEmotionResult(
      sessionId: json['session_id'] as String,
      faceEmotion: EmotionResult(
        emotion: facePred['label'] as String,
        confidence: (facePred['confidence'] as num).toDouble(),
      ),
      motionEmotion: EmotionResult(
        emotion: motionPred['label'] as String,
        confidence: (motionPred['confidence'] as num).toDouble(),
      ),
      finalEmotion: EmotionResult(
        emotion: json['combined_label'] as String,
        confidence: (json['final_confidence'] as num).toDouble(),
      ),
      weightFace: (json['weight_face'] as num).toDouble(),
      weightMotion: (json['weight_motion'] as num).toDouble(),
      greeting: json['greeting'] as String,
    );

    _sessionId = result.sessionId;
    return result;
  }

  // ══════════════════════════════════════════════════════════════════════
  //  5. SKENARIO 2 — START SESSION (tanpa kamera)
  // ══════════════════════════════════════════════════════════════════════

  /// Mulai session chatbot tanpa kamera.
  Future<SessionStartResult> startSession() async {
    final responseBody = await _postRaw(
      path: '/session/start',
      body: {},
      label: 'StartSession',
      timeout: _predictTimeout,
    );

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final result = SessionStartResult(
      sessionId: json['session_id'] as String,
      greeting: json['greeting'] as String,
    );

    _sessionId = result.sessionId;
    return result;
  }

  // ══════════════════════════════════════════════════════════════════════
  //  6. CHAT
  // ══════════════════════════════════════════════════════════════════════

  /// Kirim pesan chat ke Mistral.
  /// Harus panggil [detectCombinedEmotion] atau [startSession] dulu.
  Future<ChatResult> chat(String message) async {
    if (_sessionId == null) {
      throw EmotionApiException(
        'Belum ada session aktif. '
        'Panggil detectCombinedEmotion() atau startSession() terlebih dulu.',
      );
    }

    final responseBody = await _postRaw(
      path: '/chat',
      body: {'session_id': _sessionId, 'message': message},
      label: 'Chat',
      timeout: _chatTimeout,
    );

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final textPred = json['text_prediction'] as Map<String, dynamic>;

    return ChatResult(
      sessionId: json['session_id'] as String,
      userMessage: json['user_message'] as String,
      textPrediction: EmotionResult(
        emotion: textPred['label'] as String,
        confidence: (textPred['confidence'] as num).toDouble(),
      ),
      assistantReply: json['assistant_reply'] as String,
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  7. END SESSION
  // ══════════════════════════════════════════════════════════════════════

  Future<void> endSession() async {
    if (_sessionId == null) return;
    try {
      final token = await _getFirebaseToken();
      final uri = Uri.parse('$_chatbotUrl/session/$_sessionId');
      await _client
          .delete(
            uri,
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          )
          .timeout(_predictTimeout);
    } catch (e) {
      debugPrint('[EndSession] ⚠️ Failed: $e');
    } finally {
      _sessionId = null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  HTTP Helpers
  // ══════════════════════════════════════════════════════════════════════

  Future<EmotionResult> _postAndParse({
    required String path,
    required Map<String, dynamic> body,
    required String label,
    Duration? timeout,
  }) async {
    final responseBody = await _postRaw(path: path, body: body, label: label, timeout: timeout);
    final json = jsonDecode(responseBody) as Map<String, dynamic>;

    return EmotionResult(
      emotion: json['label'] as String? ?? 'Neutral',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      allPredictions: json.containsKey('all_scores')
          ? (json['all_scores'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            )
          : null,
    );
  }

  /// Semua request → satu URL (chatbot) + Firebase token.
  /// Retry 1x otomatis untuk network errors.
  Future<String> _postRaw({
    required String path,
    required Map<String, dynamic> body,
    required String label,
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? _predictTimeout;

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final token = await _getFirebaseToken();
        final uri = Uri.parse('$_chatbotUrl$path');

        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        final encodedBody = jsonEncode(body);

        debugPrint('[$label] 📤 POST $uri (attempt ${attempt + 1})');
        if (encodedBody.length < 500) {
          debugPrint('[$label] Body: $encodedBody');
        } else {
          debugPrint(
            '[$label] Body: ${encodedBody.substring(0, 200)}... '
            '(${encodedBody.length} chars)',
          );
        }

        final response = await _client
            .post(uri, headers: headers, body: encodedBody)
            .timeout(effectiveTimeout);

        debugPrint('[$label] 📥 Status: ${response.statusCode}');
        debugPrint('[$label] Response: ${response.body}');

        if (response.statusCode == 200) {
          return response.body;
        } else if (response.statusCode == 401) {
          throw EmotionApiException(
            'Unauthorized. Silakan login ulang.',
            statusCode: 401,
            responseBody: response.body,
          );
        } else if (response.statusCode == 404) {
          throw EmotionApiException(
            'Session not found. Mulai session baru.',
            statusCode: 404,
            responseBody: response.body,
          );
        } else {
          throw EmotionApiException(
            'Server error: ${response.statusCode}',
            statusCode: response.statusCode,
            responseBody: response.body,
          );
        }
      } on EmotionApiException {
        rethrow;
      } catch (e) {
        if (attempt == 0) {
          debugPrint('[$label] ⚠️ Retry after error: $e');
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        throw EmotionApiException('Network error: $e');
      }
    }
    throw EmotionApiException('Request failed after retries');
  }

  void dispose() {
    _client.close();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Data Classes
// ══════════════════════════════════════════════════════════════════════════════

class EmotionResult {
  EmotionResult({required this.emotion, required this.confidence, this.allPredictions});
  final String emotion;
  final double confidence;
  final Map<String, double>? allPredictions;

  @override
  String toString() => 'EmotionResult($emotion, ${confidence.toStringAsFixed(3)})';
}

class CombinedEmotionResult {
  CombinedEmotionResult({
    required this.sessionId,
    required this.faceEmotion,
    required this.motionEmotion,
    required this.finalEmotion,
    required this.weightFace,
    required this.weightMotion,
    required this.greeting,
  });
  final String sessionId;
  final EmotionResult faceEmotion;
  final EmotionResult motionEmotion;
  final EmotionResult finalEmotion;
  final double weightFace;
  final double weightMotion;
  final String greeting;
}

class SessionStartResult {
  SessionStartResult({required this.sessionId, required this.greeting});
  final String sessionId;
  final String greeting;
}

class ChatResult {
  ChatResult({
    required this.sessionId,
    required this.userMessage,
    required this.textPrediction,
    required this.assistantReply,
  });
  final String sessionId;
  final String userMessage;
  final EmotionResult textPrediction;
  final String assistantReply;
}

class EmotionApiException implements Exception {
  EmotionApiException(this.message, {this.statusCode, this.responseBody});
  final String message;
  final int? statusCode;
  final String? responseBody;

  @override
  String toString() => 'EmotionApiException: $message';
}
