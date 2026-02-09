import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../emotion_detection/services/emotion_api_service.dart';

/// Service untuk berkomunikasi dengan backend Mistral Chatbot.
class ChatService {
  ChatService({http.Client? httpClient, String? apiKey})
      : _client = httpClient ?? http.Client(),
        _apiKey = apiKey;

  // ══════════════════════════════════════════════════════════════════════
  //  API Endpoints
  // ══════════════════════════════════════════════════════════════════════

  static const String _baseUrl = 'https://mistral-chatbot-o4xbdy3cxq-et.a.run.app';
  static const String _startSessionPath = '/session/start';
  static const String _chatPath = '/chat';

  final String? _apiKey;
  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 60);

  /// Memulai sesi chat baru dengan backend.
  ///
  /// [useCamera] - `true` jika sesi dimulai dengan konteks visual.
  /// [emotionResult] - Hasil deteksi emosi multimodal jika `useCamera` true.
  Future<String> startSession({
    required bool useCamera,
    MultimodalEmotionResult? emotionResult,
  }) async {
    final body = <String, dynamic>{'use_camera': useCamera};

    if (useCamera && emotionResult != null) {
      if (emotionResult.faceEmotion != null) {
        body['face_emotion'] = {
          'emotion': emotionResult.faceEmotion!.emotion,
          'confidence': emotionResult.faceEmotion!.confidence,
        };
      }
      if (emotionResult.motionEmotion != null) {
        body['motion_emotion'] = {
          'emotion': emotionResult.motionEmotion!.emotion,
          'confidence': emotionResult.motionEmotion!.confidence,
        };
      }
    }

    final responseBody = await _postRaw(
      path: _startSessionPath,
      body: body,
      label: 'StartSession',
    );

    // Backend diharapkan mengembalikan { "session_id": "..." }
    final json = jsonDecode(responseBody);
    return json['session_id'] as String;
  }

  /// Mengirim pesan ke sesi chat yang sedang berjalan.
  ///
  /// [sessionId] - ID sesi yang diperoleh dari `startSession()`.
  /// [message] - Pesan teks dari pengguna.
  Future<String> postMessage({
    required String sessionId,
    required String message,
  }) async {
    final body = {
      'session_id': sessionId,
      'message': message,
    };

    final responseBody = await _postRaw(
      path: _chatPath,
      body: body,
      label: 'PostMessage',
    );

    // Backend diharapkan mengembalikan { "response": "..." }
    final json = jsonDecode(responseBody);
    return json['response'] as String;
  }

  // ────────────────────────────────────────────────────────────────────
  //  HTTP Helper
  // ────────────────────────────────────────────────────────────────────

  Future<String> _postRaw({
    required String path,
    required Map<String, dynamic> body,
    required String label,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
      };
      final encodedBody = jsonEncode(body);

      debugPrint('[$label] 📤 POST $uri');
      debugPrint('[$label] Body: $encodedBody');

      final response = await _client.post(uri, headers: headers, body: encodedBody).timeout(_timeout);

      debugPrint('[$label] 📥 Status: ${response.statusCode}');
      debugPrint('[$label] Response: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      } else {
        throw Exception('Server error: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('[$label] 💥 Error: $e');
      throw Exception('Failed to communicate with chat service: $e');
    }
  }

  void dispose() => _client.close();
}
