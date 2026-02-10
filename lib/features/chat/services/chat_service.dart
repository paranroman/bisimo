import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../emotion_detection/services/emotion_api_service.dart';

/// Service untuk berkomunikasi dengan backend Mistral Chatbot.
///
/// ## Arsitektur (aman):
/// ```
/// Flutter ──Firebase Token──→ Chatbot Gateway (satu-satunya endpoint)
///                                ├──→ /session/start  (mulai sesi tanpa kamera)
///                                ├──→ /chat           (kirim pesan + terima balasan)
///                                └──→ /session/{id}   DELETE (akhiri sesi)
/// ```
///
/// **Nol API key di Flutter.** Semua key tersimpan aman di Cloud Run env vars.
class ChatService {
  ChatService({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  // ══════════════════════════════════════════════════════════════════════
  //  API Endpoints - menggunakan gateway yang sama dengan EmotionApiService
  // ══════════════════════════════════════════════════════════════════════

  static const String _baseUrl = 'https://mistral-chatbot-o4xbdy3cxq-et.a.run.app';
  static const String _startSessionPath = '/session/start';
  static const String _chatPath = '/chat';

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 60);

  // ══════════════════════════════════════════════════════════════════════
  //  Firebase Auth Helper
  // ══════════════════════════════════════════════════════════════════════

  /// Dapatkan Firebase ID Token dari user yang sedang login.
  Future<String> _getFirebaseToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ChatServiceException('User belum login. Silakan login terlebih dulu.');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw ChatServiceException('Gagal mendapatkan Firebase token.');
    }
    return token;
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Start Session
  // ══════════════════════════════════════════════════════════════════════

  /// Memulai sesi chat baru dengan backend.
  ///
  /// [useCamera] - `true` jika sesi dimulai dengan konteks visual (via /predict-combined).
  /// [emotionResult] - Hasil deteksi emosi gabungan jika `useCamera` true.
  ///
  /// Jika [useCamera] = true dan [emotionResult] != null, greeting sudah ada di
  /// emotionResult.greeting (dari /predict-combined), langsung gunakan itu.
  ///
  /// Jika [useCamera] = false, panggil /session/start untuk mulai sesi baru.
  ///
  /// Returns: Map dengan 'session_id' dan 'response' (greeting).
  Future<Map<String, dynamic>> startSession({
    required bool useCamera,
    CombinedEmotionResult? emotionResult,
  }) async {
    // ── Skenario 1: Dengan kamera ─────────────────────────────────────
    // Session sudah dimulai oleh /predict-combined di EmotionLoadingScreen.
    // Gunakan data yang sudah ada.
    if (useCamera && emotionResult != null) {
      return {
        'session_id': emotionResult.sessionId,
        'response': emotionResult.greeting,
      };
    }

    // ── Skenario 2: Tanpa kamera (text-only) ──────────────────────────
    // Panggil /session/start untuk mulai sesi baru.
    final responseBody = await _postRaw(
      path: _startSessionPath,
      body: {},
      label: 'StartSession',
    );

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    return {
      'session_id': json['session_id'] as String,
      'response': json['greeting'] as String? ?? 'Halo! Ada yang ingin kamu ceritakan?',
    };
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Send Message
  // ══════════════════════════════════════════════════════════════════════

  /// Mengirim pesan ke sesi chat yang sedang berjalan.
  ///
  /// [sessionId] - ID sesi yang diperoleh dari `startSession()` atau
  ///               `CombinedEmotionResult.sessionId`.
  /// [message] - Pesan teks dari pengguna.
  ///
  /// Returns: Balasan dari Cimo (assistant_reply).
  Future<String> postMessage({
    required String sessionId,
    required String message,
  }) async {
    final responseBody = await _postRaw(
      path: _chatPath,
      body: {
        'session_id': sessionId,
        'message': message,
      },
      label: 'PostMessage',
    );

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    // Backend mengembalikan: { "assistant_reply": "...", "text_prediction": {...}, ... }
    return json['assistant_reply'] as String? ?? 
           json['response'] as String? ?? 
           'Maaf, aku tidak bisa merespons saat ini.';
  }

  // ════════════════════════════════════════════════════════════════════════
  //  HTTP Helper - Menggunakan Firebase Token
  // ════════════════════════════════════════════════════════════════════════

  Future<String> _postRaw({
    required String path,
    required Map<String, dynamic> body,
    required String label,
  }) async {
    try {
      final token = await _getFirebaseToken();
      final uri = Uri.parse('$_baseUrl$path');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final encodedBody = jsonEncode(body);

      debugPrint('[$label] 📤 POST $uri');
      if (encodedBody.length < 500) {
        debugPrint('[$label] Body: $encodedBody');
      } else {
        debugPrint('[$label] Body: ${encodedBody.substring(0, 200)}... (${encodedBody.length} chars)');
      }

      final response = await _client
          .post(uri, headers: headers, body: encodedBody)
          .timeout(_timeout);

      debugPrint('[$label] 📥 Status: ${response.statusCode}');
      debugPrint('[$label] Response: ${response.body}');

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 401) {
        throw ChatServiceException(
          'Unauthorized. Silakan login ulang.',
          statusCode: 401,
          responseBody: response.body,
        );
      } else if (response.statusCode == 404) {
        throw ChatServiceException(
          'Session not found. Mulai session baru.',
          statusCode: 404,
          responseBody: response.body,
        );
      } else {
        throw ChatServiceException(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } on ChatServiceException {
      rethrow;
    } catch (e) {
      debugPrint('[$label] 💥 Error: $e');
      throw ChatServiceException('Network error: $e');
    }
  }

  void dispose() => _client.close();
}

// ══════════════════════════════════════════════════════════════════════════════
//  Exception Class
// ══════════════════════════════════════════════════════════════════════════════

class ChatServiceException implements Exception {
  ChatServiceException(this.message, {this.statusCode, this.responseBody});
  
  final String message;
  final int? statusCode;
  final String? responseBody;

  @override
  String toString() => 'ChatServiceException: $message';
}
