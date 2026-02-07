import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service untuk mengirim data emosi ke Google Cloud dan menerima label emosi.
///
/// Mendukung 3 modalitas:
/// 1. **Teks** → IndoBERT (deteksi emosi dari chat)
/// 2. **Wajah** → EfficientNetB2 (deteksi emosi dari foto wajah 224×224)
/// 3. **Isyarat tangan** → BiLSTM (deteksi emosi dari BISINDO sign language)
///
/// ## Setup yang diperlukan:
///
/// 1. **Deploy model-model** di Google Cloud (Cloud Run / Cloud Functions /
///    Vertex AI) yang menerima POST request dan mengembalikan label emosi.
///
/// 2. **Ganti URL endpoint** di bagian `_defaultBaseUrl` di bawah.
///
/// 3. **Ganti `_apiKey`** jika endpoint memerlukan autentikasi.
///
/// 4. **Sesuaikan `_parse*Response()`** jika format response JSON berbeda.
///
/// ## Label emosi yang diharapkan (7 kelas):
/// `Senang`, `Sedih`, `Marah`, `Takut`, `Jijik`, `Terkejut`, `Neutral`
class EmotionApiService {
  EmotionApiService({String? baseUrl, String? apiKey, http.Client? httpClient})
    : _baseUrl = baseUrl ?? _defaultBaseUrl,
      _apiKey = apiKey,
      _client = httpClient ?? http.Client();

  // ══════════════════════════════════════════════════════════════════════
  //  ⬇️  GANTI NILAI-NILAI DI BAWAH INI DENGAN MILIKMU  ⬇️
  // ══════════════════════════════════════════════════════════════════════

  /// URL dasar endpoint Google Cloud.
  ///
  /// **TODO: Ganti dengan URL endpoint kamu.**
  ///
  /// Contoh:
  /// - Cloud Run: `https://bisimo-api-xxxxx-uc.a.run.app`
  /// - Cloud Functions: `https://us-central1-project-id.cloudfunctions.net`
  static const String _defaultBaseUrl = 'https://YOUR-CLOUD-ENDPOINT.run.app'; // ← GANTI INI

  // ── Endpoint paths ─────────────────────────────────────────────────

  /// Endpoint untuk deteksi emosi dari **teks** (IndoBERT).
  ///
  /// **TODO: Sesuaikan path jika berbeda.**
  ///
  /// Request body:  `{ "text": "..." }`
  /// Response body: `{ "emotion": "Sedih", "confidence": 0.92 }`
  static const String _textEmotionPath = '/predict-text'; // ← GANTI JIKA PERLU

  /// Endpoint untuk deteksi emosi dari **wajah** (EfficientNetB2).
  ///
  /// **TODO: Sesuaikan path jika berbeda.**
  ///
  /// Request body:  `{ "face_image": "<base64 JPEG 224×224>" }`
  /// Response body: `{ "emotion": "Senang", "confidence": 0.87 }`
  static const String _faceEmotionPath = '/predict-face'; // ← GANTI JIKA PERLU

  /// Endpoint untuk deteksi emosi dari **isyarat BISINDO** (BiLSTM).
  ///
  /// **TODO: Sesuaikan path jika berbeda.**
  ///
  /// Request body:  `{ "motion_sequence": [[154 floats], ...60 frames] }`
  /// Response body: `{ "emotion": "Marah", "confidence": 0.78 }`
  static const String _motionEmotionPath = '/predict-motion'; // ← GANTI JIKA PERLU

  /// Endpoint gabungan (opsional) — jika server kamu menerima semua
  /// data sekaligus dalam satu request.
  ///
  /// **TODO: Gunakan ini jika backend kamu punya satu endpoint gabungan.**
  ///
  /// Request body:
  /// ```json
  /// {
  ///   "face_image": "<base64 JPEG>",
  ///   "motion_sequence": [[...], ...],
  ///   "text": "aku sedih"
  /// }
  /// ```
  /// Response body:
  /// ```json
  /// {
  ///   "face_emotion":   { "emotion": "Senang", "confidence": 0.87 },
  ///   "motion_emotion": { "emotion": "Marah",  "confidence": 0.78 },
  ///   "text_emotion":   { "emotion": "Sedih",  "confidence": 0.92 },
  ///   "final_emotion":  { "emotion": "Sedih",  "confidence": 0.85 }
  /// }
  /// ```
  static const String _combinedEmotionPath = '/predict-combined'; // ← OPSIONAL

  /// API key atau token untuk autentikasi (opsional).
  ///
  /// **TODO: Isi jika endpoint butuh autentikasi.**
  ///
  /// Contoh dinamis:
  /// ```dart
  /// final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
  /// final service = EmotionApiService(apiKey: idToken);
  /// ```
  final String? _apiKey; // ← OPSIONAL

  // ══════════════════════════════════════════════════════════════════════

  final String _baseUrl;
  final http.Client _client;

  /// Timeout untuk request HTTP.
  static const Duration _timeout = Duration(seconds: 30);

  // ────────────────────────────────────────────────────────────────────
  //  1. TEKS → IndoBERT
  // ────────────────────────────────────────────────────────────────────

  /// Kirim teks chat ke IndoBERT dan dapatkan label emosi.
  ///
  /// ```dart
  /// final result = await service.detectTextEmotion('Aku sedih hari ini');
  /// print(result.emotion); // "Sedih"
  /// ```
  Future<EmotionResult> detectTextEmotion(String text) async {
    if (text.trim().isEmpty) {
      return EmotionResult(emotion: 'Neutral', confidence: 0.0);
    }

    return _postJson(path: _textEmotionPath, body: {'text': text}, label: 'TextEmotion');
  }

  /// Alias — backward compatibility.
  Future<EmotionResult> detectEmotion(String text) => detectTextEmotion(text);

  // ────────────────────────────────────────────────────────────────────
  //  2. WAJAH → EfficientNetB2
  // ────────────────────────────────────────────────────────────────────

  /// Kirim foto wajah (JPEG bytes 224×224) ke cloud EfficientNetB2.
  ///
  /// [faceImageBytes] — JPEG bytes dari hasil crop & resize 224×224
  ///                     (sudah diproses di CameraScreen `_processedFaceBytes`).
  ///
  /// ```dart
  /// final result = await service.detectFaceEmotion(processedFaceBytes!);
  /// print(result.emotion); // "Senang"
  /// ```
  ///
  /// **TODO: Jika backend menerima format lain (PNG, raw pixels, file upload),
  ///         sesuaikan body di bawah.**
  Future<EmotionResult> detectFaceEmotion(Uint8List faceImageBytes) async {
    final base64Image = base64Encode(faceImageBytes);

    return _postJson(
      path: _faceEmotionPath,
      // TODO: Sesuaikan key jika backend menggunakan nama field berbeda
      //       (misal "image", "file", "input_image").
      body: {'face_image': base64Image},
      label: 'FaceEmotion',
    );
  }

  // ────────────────────────────────────────────────────────────────────
  //  3. ISYARAT BISINDO → BiLSTM
  // ────────────────────────────────────────────────────────────────────

  /// Kirim motion sequence (60 frames × 154 features) ke cloud BiLSTM.
  ///
  /// [motionSequence] — hasil dari `BisindoFeatureExtractor.interpolateSequence()`,
  ///                    yaitu `List<List<double>>` dengan shape (60, 154).
  ///
  /// ```dart
  /// final interpolated = BisindoFeatureExtractor.interpolateSequence(rawFrames);
  /// final result = await service.detectMotionEmotion(interpolated);
  /// print(result.emotion); // "Marah"
  /// ```
  ///
  /// **TODO: Jika backend menerima format lain (numpy file, flattened array),
  ///         sesuaikan body di bawah.**
  Future<EmotionResult> detectMotionEmotion(List<List<double>> motionSequence) async {
    return _postJson(
      path: _motionEmotionPath,
      // TODO: Sesuaikan key jika backend menggunakan nama field berbeda
      //       (misal "sequence", "landmarks", "input").
      body: {'motion_sequence': motionSequence},
      label: 'MotionEmotion',
    );
  }

  // ────────────────────────────────────────────────────────────────────
  //  4. GABUNGAN — Kirim semua sekaligus (opsional)
  // ────────────────────────────────────────────────────────────────────

  /// Kirim face + motion + teks ke satu endpoint gabungan.
  ///
  /// Gunakan ini jika backend kamu punya endpoint yang menerima semua
  /// modalitas sekaligus dan mengembalikan hasil gabungan (weighted fusion).
  ///
  /// **TODO: Aktifkan jika backend mendukung. Jika tidak, gunakan
  ///         `detectFaceEmotion` + `detectMotionEmotion` secara terpisah
  ///         lalu gabungkan di sisi Flutter.**
  Future<MultimodalEmotionResult> detectCombinedEmotion({
    Uint8List? faceImageBytes,
    List<List<double>>? motionSequence,
  }) async {
    final body = <String, dynamic>{};

    if (faceImageBytes != null) {
      body['face_image'] = base64Encode(faceImageBytes);
    }
    if (motionSequence != null) {
      body['motion_sequence'] = motionSequence;
    }

    final responseBody = await _postRaw(
      path: _combinedEmotionPath,
      body: body,
      label: 'CombinedEmotion',
    );

    return _parseCombinedResponse(responseBody);
  }

  // ────────────────────────────────────────────────────────────────────
  //  HTTP Helpers
  // ────────────────────────────────────────────────────────────────────

  /// Generic JSON POST → parse ke [EmotionResult].
  Future<EmotionResult> _postJson({
    required String path,
    required Map<String, dynamic> body,
    required String label,
  }) async {
    final responseBody = await _postRaw(path: path, body: body, label: label);
    return _parseSingleResponse(responseBody);
  }

  /// Raw JSON POST → return response body string.
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
      // Jangan print full body untuk face_image (terlalu besar)
      if (encodedBody.length < 500) {
        debugPrint('[$label] Body: $encodedBody');
      } else {
        debugPrint(
          '[$label] Body: ${encodedBody.substring(0, 200)}... (${encodedBody.length} chars)',
        );
      }

      final response = await _client
          .post(uri, headers: headers, body: encodedBody)
          .timeout(_timeout);

      debugPrint('[$label] 📥 Status: ${response.statusCode}');
      debugPrint('[$label] Response: ${response.body}');

      if (response.statusCode == 200) {
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
      throw EmotionApiException('Network error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────
  //  Response Parsers
  // ────────────────────────────────────────────────────────────────────

  /// Parse response untuk endpoint tunggal (text/face/motion).
  ///
  /// Format yang diharapkan:
  /// ```json
  /// { "emotion": "Sedih", "confidence": 0.92 }
  /// ```
  ///
  /// **TODO: Sesuaikan key jika server mengembalikan format berbeda.**
  /// Misal `{ "label": "sad", "score": 0.92 }` → ganti `json['label']`.
  EmotionResult _parseSingleResponse(String responseBody) {
    final json = jsonDecode(responseBody) as Map<String, dynamic>;

    final emotion = json['emotion'] as String? ?? 'Neutral';
    final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;

    Map<String, double>? allPredictions;
    if (json.containsKey('all_predictions')) {
      final raw = json['all_predictions'] as Map<String, dynamic>;
      allPredictions = raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    return EmotionResult(emotion: emotion, confidence: confidence, allPredictions: allPredictions);
  }

  /// Parse response untuk endpoint gabungan.
  ///
  /// **TODO: Sesuaikan key jika format response server berbeda.**
  MultimodalEmotionResult _parseCombinedResponse(String responseBody) {
    final json = jsonDecode(responseBody) as Map<String, dynamic>;

    EmotionResult? parseOptional(String key) {
      if (!json.containsKey(key)) return null;
      final sub = json[key] as Map<String, dynamic>;
      return EmotionResult(
        emotion: sub['emotion'] as String? ?? 'Neutral',
        confidence: (sub['confidence'] as num?)?.toDouble() ?? 0.0,
      );
    }

    return MultimodalEmotionResult(
      faceEmotion: parseOptional('face_emotion'),
      motionEmotion: parseOptional('motion_emotion'),
      finalEmotion:
          parseOptional('final_emotion') ??
          parseOptional('face_emotion') ??
          EmotionResult(emotion: 'Neutral', confidence: 0.0),
    );
  }

  /// Bersihkan resources.
  void dispose() {
    _client.close();
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Data Classes
// ══════════════════════════════════════════════════════════════════════════

/// Hasil deteksi emosi tunggal (dari satu modalitas).
class EmotionResult {
  EmotionResult({required this.emotion, required this.confidence, this.allPredictions});

  /// Label emosi (misal: "Sedih", "Senang", "Marah", "Takut", "Jijik",
  /// "Terkejut", "Neutral")
  final String emotion;

  /// Skor kepercayaan (0.0 – 1.0)
  final double confidence;

  /// Semua prediksi per kelas (opsional)
  final Map<String, double>? allPredictions;

  @override
  String toString() =>
      'EmotionResult(emotion: $emotion, confidence: ${confidence.toStringAsFixed(3)})';
}

/// Hasil deteksi emosi multimodal (gabungan face + motion).
///
/// Dikirimkan dari CameraScreen → EmotionLoadingScreen → ChatScreen
/// melalui go_router `extra` parameter.
class MultimodalEmotionResult {
  MultimodalEmotionResult({this.faceEmotion, this.motionEmotion, required this.finalEmotion});

  /// Emosi dari wajah (EfficientNetB2) — bisa null jika wajah tidak terdeteksi.
  final EmotionResult? faceEmotion;

  /// Emosi dari isyarat BISINDO (BiLSTM) — bisa null jika tangan tidak terdeteksi.
  final EmotionResult? motionEmotion;

  /// Emosi akhir (gabungan weighted: 70% face + 30% BISINDO, atau
  /// dari server jika endpoint gabungan digunakan).
  final EmotionResult finalEmotion;

  /// Hitung emosi akhir secara lokal (70% face + 30% motion).
  ///
  /// Gunakan ini jika backend TIDAK punya endpoint gabungan dan kamu
  /// memanggil face + motion secara terpisah.
  ///
  /// **TODO: Sesuaikan bobot jika diperlukan.**
  static MultimodalEmotionResult fusionLocal({
    EmotionResult? faceEmotion,
    EmotionResult? motionEmotion,
  }) {
    // Jika hanya salah satu yang ada, gunakan itu
    if (faceEmotion == null && motionEmotion == null) {
      return MultimodalEmotionResult(
        finalEmotion: EmotionResult(emotion: 'Neutral', confidence: 0.0),
      );
    }

    if (faceEmotion != null && motionEmotion == null) {
      return MultimodalEmotionResult(faceEmotion: faceEmotion, finalEmotion: faceEmotion);
    }

    if (faceEmotion == null && motionEmotion != null) {
      return MultimodalEmotionResult(motionEmotion: motionEmotion, finalEmotion: motionEmotion);
    }

    // Kedua modalitas ada → weighted fusion
    // TODO: Sesuaikan bobot 0.7 / 0.3 jika perlu.
    const double faceWeight = 0.7;
    const double motionWeight = 0.3;

    // Pilih emosi dengan weighted confidence tertinggi
    final faceScore = faceEmotion!.confidence * faceWeight;
    final motionScore = motionEmotion!.confidence * motionWeight;

    final finalResult = faceScore >= motionScore ? faceEmotion : motionEmotion;

    return MultimodalEmotionResult(
      faceEmotion: faceEmotion,
      motionEmotion: motionEmotion,
      finalEmotion: EmotionResult(
        emotion: finalResult.emotion,
        confidence: faceScore + motionScore,
      ),
    );
  }

  @override
  String toString() =>
      'MultimodalEmotionResult(face: $faceEmotion, motion: $motionEmotion, final: $finalEmotion)';
}

/// Exception khusus untuk error API emosi.
class EmotionApiException implements Exception {
  EmotionApiException(this.message, {this.statusCode, this.responseBody});

  final String message;
  final int? statusCode;
  final String? responseBody;

  @override
  String toString() => 'EmotionApiException: $message';
}
