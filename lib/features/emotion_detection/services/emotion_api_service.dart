import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service untuk mengirim data emosi ke Google Cloud dan menerima label emosi.
class EmotionApiService {
  EmotionApiService({http.Client? httpClient, String? apiKey})
      : _client = httpClient ?? http.Client(),
        _apiKey = apiKey;

  // ══════════════════════════════════════════════════════════════════════
  //  API Endpoints
  // ══════════════════════════════════════════════════════════════════════

  static const String _faceEmotionUrl =
      'https://face-emotion-api-845897442315.asia-southeast2.run.app/predict-face';

  static const String _motionEmotionUrl =
      'https://bisindo-model-845897442315.asia-southeast2.run.app/predict-motion';

  static const String _textEmotionUrl =
      'https://indobert-model-845897442315.asia-southeast2.run.app/predict-text';

  static const String _combinedEmotionUrl =
      'https://mistral-chatbot-845897442315.asia-southeast2.run.app/'; // Opsional

  final String? _apiKey;
  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 45);

  // ────────────────────────────────────────────────────────────────────
  //  API Methods
  // ────────────────────────────────────────────────────────────────────

  Future<EmotionResult> detectTextEmotion(String text) async {
    if (text.trim().isEmpty) {
      return EmotionResult(emotion: 'Neutral', confidence: 0.0);
    }
    return _postJson(url: _textEmotionUrl, body: {'text': text}, label: 'TextEmotion');
  }

  Future<EmotionResult> detectFaceEmotion(Uint8List faceImageBytes) async {
    final base64Image = base64Encode(faceImageBytes);
    return _postJson(
        url: _faceEmotionUrl, body: {'image_base64': base64Image}, label: 'FaceEmotion');
  }

  Future<EmotionResult> detectMotionEmotion(List<List<double>> motionSequence) async {
    return _postJson(
      url: _motionEmotionUrl,
      body: {'data': motionSequence},
      label: 'MotionEmotion',
    );
  }

  Future<MultimodalEmotionResult> detectCombinedEmotion({
    Uint8List? faceImageBytes,
    List<List<double>>? motionSequence,
  }) async {
    final body = <String, dynamic>{};
    if (faceImageBytes != null) {
      body['image_base64'] = base64Encode(faceImageBytes);
    }
    if (motionSequence != null) {
      body['data'] = motionSequence;
    }

    final responseBody = await _postRaw(url: _combinedEmotionUrl, body: body, label: 'CombinedEmotion');
    return _parseCombinedResponse(responseBody);
  }

  // ────────────────────────────────────────────────────────────────────
  //  HTTP Helpers
  // ────────────────────────────────────────────────────────────────────

  Future<EmotionResult> _postJson({
    required String url,
    required Map<String, dynamic> body,
    required String label,
  }) async {
    final responseBody = await _postRaw(url: url, body: body, label: label);
    return _parseSingleResponse(responseBody);
  }

  Future<String> _postRaw({
    required String url,
    required Map<String, dynamic> body,
    required String label,
  }) async {
    try {
      final uri = Uri.parse(url);
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
      };
      final encodedBody = jsonEncode(body);

      debugPrint('[$label] 📤 POST $uri');
      if (encodedBody.length < 500) {
        debugPrint('[$label] Body: $encodedBody');
      } else {
        debugPrint('[$label] Body: ${encodedBody.substring(0, 200)}... (${encodedBody.length} chars)');
      }

      final response = await _client.post(uri, headers: headers, body: encodedBody).timeout(_timeout);

      debugPrint('[$label] 📥 Status: ${response.statusCode}');
      debugPrint('[$label] Response: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
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
      debugPrint('[$label] 💥 Error: $e');
      throw EmotionApiException('Network or timeout error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────
  //  Response Parsers
  // ────────────────────────────────────────────────────────────────────

  EmotionResult _parseSingleResponse(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final emotion = json['emotion'] as String? ?? 'Neutral';
      final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;

      return EmotionResult(emotion: emotion, confidence: confidence);
    } catch (e) {
      throw EmotionApiException('Failed to parse response: $e', responseBody: responseBody);
    }
  }

  MultimodalEmotionResult _parseCombinedResponse(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      EmotionResult? parseOptional(String key) {
        if (!json.containsKey(key) || json[key] == null) return null;
        final sub = json[key] as Map<String, dynamic>;
        return EmotionResult(
          emotion: sub['emotion'] as String? ?? 'Neutral',
          confidence: (sub['confidence'] as num?)?.toDouble() ?? 0.0,
        );
      }

      final finalEmotion = parseOptional('final_emotion') ??
                           parseOptional('face_emotion') ??
                           EmotionResult(emotion: 'Neutral', confidence: 0.0);

      return MultimodalEmotionResult(
        faceEmotion: parseOptional('face_emotion'),
        motionEmotion: parseOptional('motion_emotion'),
        finalEmotion: finalEmotion,
      );
    } catch (e) {
      throw EmotionApiException('Failed to parse combined response: $e', responseBody: responseBody);
    }
  }

  void dispose() => _client.close();
}

// ══════════════════════════════════════════════════════════════════════════
//  Data Classes & Exceptions
// ══════════════════════════════════════════════════════════════════════════

class EmotionResult {
  final String emotion;
  final double confidence;
  EmotionResult({required this.emotion, required this.confidence});

  @override
  String toString() => 'EmotionResult(emotion: $emotion, confidence: ${confidence.toStringAsFixed(3)})';
}

class MultimodalEmotionResult {
  final EmotionResult? faceEmotion;
  final EmotionResult? motionEmotion;
  final EmotionResult finalEmotion;

  MultimodalEmotionResult({
    this.faceEmotion,
    this.motionEmotion,
    required this.finalEmotion,
  });

  static MultimodalEmotionResult fusionLocal({
    EmotionResult? faceEmotion,
    EmotionResult? motionEmotion,
  }) {
    if (faceEmotion == null && motionEmotion == null) {
      return MultimodalEmotionResult(finalEmotion: EmotionResult(emotion: 'Neutral', confidence: 0.0));
    }
    if (faceEmotion != null && motionEmotion == null) {
      return MultimodalEmotionResult(faceEmotion: faceEmotion, finalEmotion: faceEmotion);
    }
    if (faceEmotion == null && motionEmotion != null) {
      return MultimodalEmotionResult(motionEmotion: motionEmotion, finalEmotion: motionEmotion);
    }

    const double faceWeight = 0.7;
    const double motionWeight = 0.3;
    final faceScore = faceEmotion!.confidence * faceWeight;
    final motionScore = motionEmotion!.confidence * motionWeight;
    final finalResult = faceScore >= motionScore ? faceEmotion : motionEmotion;

    return MultimodalEmotionResult(
      faceEmotion: faceEmotion,
      motionEmotion: motionEmotion,
      finalEmotion: EmotionResult(
        emotion: finalResult.emotion,
        confidence: faceScore + motionScore, // This might exceed 1.0, consider clamping or normalizing
      ),
    );
  }

  @override
  String toString() => 'MultimodalEmotionResult(face: $faceEmotion, motion: $motionEmotion, final: $finalEmotion)';
}

class EmotionApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  EmotionApiException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() => 'EmotionApiException: $message (Status: $statusCode)';
}
