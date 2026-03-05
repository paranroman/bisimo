import 'dart:io';
import 'dart:math';

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/hand_landmark_result.dart';
import '../services/bisindo_feature_extractor.dart';
import '../services/hand_landmark_service.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/app_routes.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Top-level data classes & functions for compute() isolate
// ──────────────────────────────────────────────────────────────────────────────

/// Plane metadata transported to the isolate.
class _PlaneData {
  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;

  _PlaneData({required this.bytes, required this.bytesPerRow, required this.bytesPerPixel});
}

/// Parameters passed into the background isolate for face cropping & resizing.
class _CropParams {
  final int imageWidth;
  final int imageHeight;
  final List<_PlaneData> planes;
  final int bboxLeft;
  final int bboxTop;
  final int bboxWidth;
  final int bboxHeight;

  /// `true` when camera format is BGRA (iOS). `false` for YUV420 (Android).
  final bool isBGRA;

  /// Sensor orientation in degrees (0, 90, 180, 270).
  final int sensorOrientation;

  _CropParams({
    required this.imageWidth,
    required this.imageHeight,
    required this.planes,
    required this.bboxLeft,
    required this.bboxTop,
    required this.bboxWidth,
    required this.bboxHeight,
    required this.isBGRA,
    required this.sensorOrientation,
  });
}

/// Runs in a separate isolate via `compute()`.
///
/// Pipeline (matches training):
///   1. Camera bytes → RGB image  (YUV420 on Android, BGRA on iOS)
///   2. Rotate to upright          (sensorOrientation → portrait)
///   3. Mirror horizontally        (cv2.flip(frame,1) equivalent)
///   4. Transform bbox to mirrored space
///   5. Crop face with 10 % padding
///   6. Resize to 224 × 224
///   7. Encode as JPEG (RGB)
///
/// Returns JPEG-encoded bytes of the processed face (or `null`).
Uint8List? _cropAndResizeFace(_CropParams p) {
  try {
    img.Image? fullImage;

    if (p.isBGRA) {
      // ── iOS: BGRA8888 → RGB ────────────────────────────────────────
      fullImage = img.Image(width: p.imageWidth, height: p.imageHeight);
      final bytes = p.planes[0].bytes;
      final bpr = p.planes[0].bytesPerRow;
      for (int y = 0; y < p.imageHeight; y++) {
        for (int x = 0; x < p.imageWidth; x++) {
          final idx = y * bpr + x * 4;
          if (idx + 3 < bytes.length) {
            fullImage.setPixelRgba(
              x,
              y,
              bytes[idx + 2],
              bytes[idx + 1],
              bytes[idx],
              bytes[idx + 3],
            );
          }
        }
      }
    } else {
      // ── Android: YUV420 → RGB ──────────────────────────────────────
      fullImage = _convertYUV420ToImage(p);
    }

    if (fullImage == null) return null;

    // ── Step 1: Rotate to upright (match ML Kit bbox coordinate space) ─
    // ML Kit applies rotation metadata internally, producing bbox values
    // in the rotated (upright) coordinate space.  We must rotate our raw
    // RGB buffer to the same orientation before cropping.
    if (p.sensorOrientation != 0) {
      fullImage = img.copyRotate(fullImage, angle: p.sensorOrientation);
    }

    // ── Step 2: Mirror horizontally ─────────────────────────────────
    // Training used cv2.flip(frame, 1).  We replicate that so the
    // cropped face matches what EfficientNetB2 was trained on.
    img.flipHorizontal(fullImage);

    // ── Step 3: Transform bbox from pre-mirror → mirrored space ─────
    // ML Kit bbox is in the rotated-but-NOT-mirrored coordinate space.
    // After horizontal flip:  new_left = width − old_left − old_width.
    final mirroredBboxLeft = fullImage.width - p.bboxLeft - p.bboxWidth;

    // ── Step 4: Crop with 10 % padding ──────────────────────────────
    final padX = (p.bboxWidth * 0.10).round();
    final padY = (p.bboxHeight * 0.10).round();

    final cropLeft = (mirroredBboxLeft - padX).clamp(0, fullImage.width - 1);
    final cropTop = (p.bboxTop - padY).clamp(0, fullImage.height - 1);
    final cropWidth = (p.bboxWidth + padX * 2).clamp(1, fullImage.width - cropLeft);
    final cropHeight = (p.bboxHeight + padY * 2).clamp(1, fullImage.height - cropTop);

    final cropped = img.copyCrop(
      fullImage,
      x: cropLeft,
      y: cropTop,
      width: cropWidth,
      height: cropHeight,
    );

    // ── Step 5: Resize to 224 × 224 (EfficientNetB2 input) ──────────
    final resized = img.copyResize(
      cropped,
      width: 224,
      height: 224,
      interpolation: img.Interpolation.linear,
    );

    return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
  } catch (_) {
    return null;
  }
}

/// Compresses JPEG bytes further for network transfer.
///
/// Decodes the input JPEG → re-encodes at [quality] (default 50).
/// Runs via `compute()` in a background isolate.
Uint8List? _compressJpeg(_CompressParams p) {
  try {
    final decoded = img.decodeJpg(p.bytes);
    if (decoded == null) return null;
    return Uint8List.fromList(img.encodeJpg(decoded, quality: p.quality));
  } catch (_) {
    return null;
  }
}

/// Parameters for [_compressJpeg] isolate function.
class _CompressParams {
  final Uint8List bytes;
  final int quality;
  _CompressParams({required this.bytes, required this.quality});
}

/// Converts YUV420 (Android camera) image data to an [img.Image].
img.Image? _convertYUV420ToImage(_CropParams p) {
  try {
    final w = p.imageWidth;
    final h = p.imageHeight;
    final yPlane = p.planes[0].bytes;
    final uPlane = p.planes[1].bytes;
    final vPlane = p.planes[2].bytes;
    final yRowStride = p.planes[0].bytesPerRow;
    final uvRowStride = p.planes[1].bytesPerRow;
    final uvPixelStride = p.planes[1].bytesPerPixel;

    final image = img.Image(width: w, height: h);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final yIdx = y * yRowStride + x;
        final uvIdx = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
        if (yIdx >= yPlane.length || uvIdx >= uPlane.length || uvIdx >= vPlane.length) {
          continue;
        }
        final yVal = yPlane[yIdx];
        final uVal = uPlane[uvIdx];
        final vVal = vPlane[uvIdx];

        int r = (yVal + 1.370705 * (vVal - 128)).round().clamp(0, 255);
        int g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128)).round().clamp(0, 255);
        int b = (yVal + 1.732446 * (uVal - 128)).round().clamp(0, 255);

        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return image;
  } catch (_) {
    return null;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Camera Screen Widget
// ──────────────────────────────────────────────────────────────────────────────

/// Camera Screen – Real-time face detection for emotion analysis.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // ── Camera ──────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  // ── ML Kit Face Detection ──────────────────────────────────────────────
  late final FaceDetector _faceDetector;
  bool _isProcessingFrame = false;

  // ── Throttle control ───────────────────────────────────────────────────
  DateTime _lastProcessedTime = DateTime.now();
  static const Duration _throttleInterval = Duration(milliseconds: 100);

  // ── Processed face data ────────────────────────────────────────────────
  Uint8List? _processedFaceBytes;
  File? _processedFaceFile;

  // ── Periodic face capture (every 3 seconds) ────────────────────────────
  Timer? _faceCaptureTimer;
  final List<String> _capturedFacePaths = [];
  Directory? _faceTempDir;
  static const Duration _captureInterval = Duration(seconds: 3);

  // ── UI state ───────────────────────────────────────────────────────────
  bool _isSending = false;
  bool _faceDetected = false;
  Rect? _faceBoundingBox;
  int _imageWidth = 0;
  int _imageHeight = 0;
  int _sensorOrientation = 0;

  // ── Hand Landmark / BISINDO Sign Language ──────────────────────────────
  HandLandmarkService? _handLandmarkService;
  final BisindoFeatureExtractor _featureExtractor = BisindoFeatureExtractor();
  final List<List<double>> _motionSequence = [];
  bool _isMotionDataReady = false;

  /// Minimum frames needed before the user CAN send (UX guard).
  static const int _minFramesToSend = 10;

  /// Frames we aim to collect for best quality (shown in UI).
  static const int _targetFrames = 30;

  // ────────────────────────────────────────────────────────────────────────
  //  Lifecycle
  // ────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initFaceDetector();
    _initHandLandmarkService();
    _initializeCamera();
    _initFaceTempDir();
  }

  @override
  void dispose() {
    _faceCaptureTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector.close();
    _handLandmarkService?.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Temp Directory for Periodic Face Captures
  // ────────────────────────────────────────────────────────────────────────

  Future<void> _initFaceTempDir() async {
    final tmp = await getTemporaryDirectory();
    _faceTempDir = Directory('${tmp.path}/bisimo_face_captures');
    if (await _faceTempDir!.exists()) {
      await _faceTempDir!.delete(recursive: true);
    }
    await _faceTempDir!.create(recursive: true);
    debugPrint('[CameraScreen] 📂 Temp face dir: ${_faceTempDir!.path}');
  }

  /// Start periodic timer that saves face snapshot every 3 seconds.
  void _startFaceCaptureTimer() {
    _faceCaptureTimer?.cancel();
    _faceCaptureTimer = Timer.periodic(_captureInterval, (_) => _saveFaceSnapshot());
    debugPrint('[CameraScreen] ⏱️ Face capture timer started (every 3s)');
  }

  /// Save the latest processed face bytes to the temp directory.
  Future<void> _saveFaceSnapshot() async {
    if (_processedFaceBytes == null || _faceTempDir == null) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${_faceTempDir!.path}/face_$timestamp.jpg';
      final file = File(filePath);
      await file.writeAsBytes(_processedFaceBytes!);
      _capturedFacePaths.add(filePath);

      debugPrint(
        '[CameraScreen] 📸 Face #${_capturedFacePaths.length} saved '
        '(${(_processedFaceBytes!.length / 1024).toStringAsFixed(1)} KB): $filePath',
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[CameraScreen] ⚠️ Error saving face snapshot: $e');
    }
  }

  /// Delete all captured face images from temp directory.
  Future<void> _cleanupTempFaces() async {
    try {
      if (_faceTempDir != null && await _faceTempDir!.exists()) {
        await _faceTempDir!.delete(recursive: true);
        debugPrint(
          '[CameraScreen] 🗑️ Temp face dir cleaned '
          '(${_capturedFacePaths.length} images deleted)',
        );
      }
      _capturedFacePaths.clear();
    } catch (e) {
      debugPrint('[CameraScreen] ⚠️ Error cleaning temp faces: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Face Detector Initialization
  // ────────────────────────────────────────────────────────────────────────

  void _initFaceDetector() {
    final options = FaceDetectorOptions(
      enableClassification: false,
      enableLandmarks: false,
      enableContours: false,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    );
    _faceDetector = FaceDetector(options: options);
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Hand Landmark Service Initialization (BISINDO Sign Language)
  // ────────────────────────────────────────────────────────────────────────

  void _initHandLandmarkService() {
    try {
      _handLandmarkService = HandLandmarkService.create();
      debugPrint('[CameraScreen] ✅ Hand landmark service initialized');
    } catch (e) {
      debugPrint('[CameraScreen] ⚠️ Hand landmark init failed: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Camera Initialization + Image Stream
  // ────────────────────────────────────────────────────────────────────────

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      final frontCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);

      // Start the image stream for real-time face detection
      _cameraController!.startImageStream(_onCameraFrame);

      // Start periodic face capture timer (every 3 seconds)
      _startFaceCaptureTimer();
    } catch (e) {
      debugPrint('[CameraScreen] Error initializing camera: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Frame Processing (throttled)
  // ────────────────────────────────────────────────────────────────────────

  void _onCameraFrame(CameraImage cameraImage) {
    if (_isProcessingFrame) return;
    final now = DateTime.now();
    if (now.difference(_lastProcessedTime) < _throttleInterval) return;

    _isProcessingFrame = true;
    _lastProcessedTime = now;
    _processFrame(cameraImage);
  }

  Future<void> _processFrame(CameraImage cameraImage) async {
    try {
      // ─────────────────────────────────────────────────────────────────
      // Run hand detection FIRST (synchronous via JNI) while the
      // CameraImage buffer is still valid.
      // ─────────────────────────────────────────────────────────────────

      // 0. Hand Landmark Detection (synchronous — must run before any await)
      ({HandLandmarkResult? left, HandLandmarkResult? right})? handResults;
      if (_handLandmarkService != null && _handLandmarkService!.isInitialized) {
        try {
          final sensorOrientation = _cameraController!.description.sensorOrientation;
          handResults = _handLandmarkService!.detectHands(cameraImage, sensorOrientation);
        } catch (e) {
          debugPrint('[CameraScreen] Hand landmark error: $e');
        }
      }

      // 1. Build InputImage for ML Kit (copies bytes synchronously)
      final inputImage = _buildInputImage(cameraImage);
      if (inputImage == null) {
        _isProcessingFrame = false;
        return;
      }

      // ── 2. Face Detection ───────────────────────────────────────────
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (mounted) {
          setState(() {
            _faceDetected = false;
            _faceBoundingBox = null;
          });
        }
      } else {
        final face = faces.first;
        final bbox = face.boundingBox;

        debugPrint(
          '[CameraScreen] ✅ Wajah terdeteksi! '
          'BBox: left=${bbox.left.toInt()}, top=${bbox.top.toInt()}, '
          'w=${bbox.width.toInt()}, h=${bbox.height.toInt()}',
        );

        if (mounted) {
          setState(() {
            _faceDetected = true;
            _faceBoundingBox = bbox;
            _imageWidth = cameraImage.width;
            _imageHeight = cameraImage.height;
            _sensorOrientation = _cameraController!.description.sensorOrientation;
          });
        }

        // 3. Crop & resize face in a background isolate
        final planes = cameraImage.planes
            .map(
              (p) => _PlaneData(
                bytes: Uint8List.fromList(p.bytes),
                bytesPerRow: p.bytesPerRow,
                bytesPerPixel: p.bytesPerPixel ?? 1,
              ),
            )
            .toList();

        final cropParams = _CropParams(
          imageWidth: cameraImage.width,
          imageHeight: cameraImage.height,
          planes: planes,
          bboxLeft: bbox.left.toInt(),
          bboxTop: bbox.top.toInt(),
          bboxWidth: bbox.width.toInt(),
          bboxHeight: bbox.height.toInt(),
          isBGRA: Platform.isIOS,
          sensorOrientation: _cameraController!.description.sensorOrientation,
        );

        final result = await compute(_cropAndResizeFace, cropParams);

        if (result != null) {
          _processedFaceBytes = result;
          debugPrint(
            '[CameraScreen] ✅ Wajah berhasil di-crop & resize → '
            '224×224 (${result.length} bytes JPEG)',
          );
        }
      }

      // ── 4. Process Hand Landmark Results ───────────────────────────
      // Only collect when at least one hand was actually detected.
      // detectHands returns (left: null, right: null) on failure/no-hands,
      // so we must check the inner fields, not just the record itself.
      if (handResults != null && (handResults.left != null || handResults.right != null)) {
        try {
          // ── Mirror landmarks (x → 1−x) + swap left↔right ─────────
          // Training used cv2.flip(frame, 1) before MediaPipe Holistic,
          // so the model saw mirrored images.  To replicate:
          //   • Mirror each landmark's x-coordinate
          //   • What the plugin called "left" on the raw (non-mirrored)
          //     image becomes "right" in the mirrored image, & vice-versa
          final mirroredLeft = handResults.right?.mirrorX();
          final mirroredRight = handResults.left?.mirrorX();

          final features = _featureExtractor.extractFrameFeatures(
            leftHand: mirroredLeft,
            rightHand: mirroredRight,
          );
          _motionSequence.add(features);

          final count = _motionSequence.length;
          debugPrint(
            '[CameraScreen] 🤟 Frame collected: '
            '$count/60',
          );

          // Mark ready once we hit the minimum threshold.
          if (!_isMotionDataReady && count >= _minFramesToSend) {
            _isMotionDataReady = true;
            debugPrint(
              '[CameraScreen] ✅ Motion data sendable! '
              '$count frames (min $_minFramesToSend).',
            );
            if (mounted) setState(() {});
          }

          // Update UI progress periodically
          if (count <= _targetFrames && count % 5 == 0 && mounted) {
            setState(() {});
          }
        } catch (e) {
          debugPrint('[CameraScreen] Hand landmark error: $e');
        }
      }
    } catch (e) {
      debugPrint('[CameraScreen] Error processing frame: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Build ML Kit InputImage from CameraImage
  // ────────────────────────────────────────────────────────────────────────

  InputImage? _buildInputImage(CameraImage cameraImage) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      rotation = _intToRotation(sensorOrientation);
    } else if (Platform.isIOS) {
      rotation = InputImageRotation.rotation0deg;
    }
    if (rotation == null) return null;

    // ML Kit fromBytes() on Android only supports NV21 and YV12.
    // Camera is set to yuv420 (3 planes) for hand_landmarker, so we
    // must convert the 3 YUV420 planes → packed NV21 bytes.
    final Uint8List bytes;
    final InputImageFormat format;

    if (Platform.isAndroid && cameraImage.planes.length >= 3) {
      bytes = _yuv420ToNv21(cameraImage);
      format = InputImageFormat.nv21;
    } else {
      bytes = _concatenatePlanes(cameraImage);
      format = InputImageFormat.bgra8888;
    }

    final metadata = InputImageMetadata(
      size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: cameraImage.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  /// Converts YUV_420_888 (3 separate planes) to packed NV21 format.
  ///
  /// NV21 layout: [Y plane (w*h)] + [VU interleaved (w*h/2)]
  ///
  /// On CameraX, planes[1] (U) and planes[2] (V) share the same native
  /// buffer with pixelStride=2. plane[2].bytes starts at V and contains
  /// V,U,V,U... which is exactly the NV21 chroma layout.
  Uint8List _yuv420ToNv21(CameraImage image) {
    final w = image.width;
    final h = image.height;
    final yPlane = image.planes[0];
    final vPlane = image.planes[2]; // VU interleaved on CameraX = NV21
    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = vPlane.bytesPerRow;
    final chromaH = h ~/ 2;
    final nv21Size = w * h + w * chromaH;
    final nv21 = Uint8List(nv21Size);

    // ── Copy Y plane ──────────────────────────────────────────────────
    if (yRowStride == w) {
      // Fast path: no row padding
      nv21.setRange(0, w * h, yPlane.bytes);
    } else {
      // Slow path: skip row padding
      for (int row = 0; row < h; row++) {
        final srcOff = row * yRowStride;
        final dstOff = row * w;
        nv21.setRange(dstOff, dstOff + w, yPlane.bytes, srcOff);
      }
    }

    // ── Copy VU chroma ────────────────────────────────────────────────
    final chromaOffset = w * h;
    if (uvRowStride == w) {
      // Fast path: chroma data is already tightly packed VU
      final chromaLen = min(w * chromaH, vPlane.bytes.length);
      nv21.setRange(chromaOffset, chromaOffset + chromaLen, vPlane.bytes);
    } else {
      // Slow path: skip row padding
      for (int row = 0; row < chromaH; row++) {
        final srcOff = row * uvRowStride;
        final dstOff = chromaOffset + row * w;
        final copyLen = min(w, vPlane.bytes.length - srcOff);
        if (copyLen <= 0) break;
        nv21.setRange(dstOff, dstOff + copyLen, vPlane.bytes, srcOff);
      }
    }

    return nv21;
  }

  Uint8List _concatenatePlanes(CameraImage image) {
    final WriteBuffer buffer = WriteBuffer();
    for (final plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    return buffer.done().buffer.asUint8List();
  }

  InputImageRotation _intToRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  /// Resets the motion sequence buffer so the user can re-collect.
  void _resetMotionSequence() {
    _motionSequence.clear();
    _isMotionDataReady = false;
    if (mounted) setState(() {});
    debugPrint('[CameraScreen] 🔄 Motion sequence reset.');
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Send Button Handler
  // ────────────────────────────────────────────────────────────────────────

  Future<void> _onSendPressed() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    try {
      // Stop periodic capture & image stream before processing
      _faceCaptureTimer?.cancel();
      await _cameraController?.stopImageStream();

      // ── Also save the very latest frame as a final snapshot ────────
      if (_processedFaceBytes != null) {
        await _saveFaceSnapshot();
      }

      // ── Read all captured face images & compress for upload ────────
      final List<Uint8List> faceImagesList = [];
      int totalOriginalBytes = 0;
      int totalCompressedBytes = 0;

      for (final path in _capturedFacePaths) {
        final file = File(path);
        if (await file.exists()) {
          final rawBytes = await file.readAsBytes();
          totalOriginalBytes += rawBytes.length;

          // Compress each image in a background isolate
          final compressed = await compute(
            _compressJpeg,
            _CompressParams(bytes: rawBytes, quality: 50),
          );
          if (compressed != null) {
            faceImagesList.add(compressed);
            totalCompressedBytes += compressed.length;
          }
        }
      }

      if (faceImagesList.isNotEmpty) {
        debugPrint(
          '[CameraScreen] 🗜️ ${faceImagesList.length} face images compressed: '
          '${(totalOriginalBytes / 1024).toStringAsFixed(1)} KB → '
          '${(totalCompressedBytes / 1024).toStringAsFixed(1)} KB '
          '(${(100 - totalCompressedBytes * 100 / totalOriginalBytes).toStringAsFixed(0)}% smaller)',
        );
      } else {
        debugPrint('[CameraScreen] ⚠️ Tidak ada wajah terdeteksi untuk dikirim.');
      }

      // ── Interpolate motion sequence to model's expected 60 frames ──
      List<List<double>>? interpolatedSequence;
      if (_motionSequence.isNotEmpty) {
        interpolatedSequence = BisindoFeatureExtractor.interpolateSequence(_motionSequence);
        debugPrint(
          '[CameraScreen] 📦 Motion sequence interpolated: '
          '${_motionSequence.length} → ${interpolatedSequence.length} frames '
          '× ${_featureExtractor.totalFeatures} features',
        );
      } else {
        debugPrint('[CameraScreen] ⚠️ No motion frames collected.');
      }

      // ── Navigate ke Loading Screen, bawa data mentah ──────────────
      // Loading Screen akan memanggil cloud API selama animasi loading.
      // Face images dikirim sebagai List<Uint8List> (multiple JPEG 224×224).
      if (mounted) {
        context.push(
          AppRoutes.emotionDetection,
          extra: <String, dynamic>{
            'faceImagesList': faceImagesList.isNotEmpty ? faceImagesList : null,
            'motionSequence': interpolatedSequence, // List<List<double>>? (60×154)
          },
        );
      }

      // ── Cleanup temp folder after navigation ──────────────────────
      await _cleanupTempFaces();
    } catch (e) {
      debugPrint('[CameraScreen] Error during send: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Build UI
  // ────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            _cameraController?.stopImageStream().catchError((_) {});
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: const Text(
          'Deteksi Emosional',
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;

          final circleSize = screenWidth * 0.55;
          final circleLeft = -(circleSize * 0.25);
          final circleBottom = -(circleSize * 0.4);

          final cimoSize = screenWidth * 0.4;
          const cimoLeft = 1.0;
          const cimoBottom = 10.0;

          return Stack(
            children: [
              // ── Camera Preview ──────────────────────────────────────
              // ── Camera Preview ──────────────────────────────────────
              Positioned.fill(
                child: _isCameraInitialized && _cameraController != null
                    ? OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _cameraController!.value.previewSize?.height ?? 1,
                            height: _cameraController!.value.previewSize?.width ?? 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(_cameraController!),
                                if (_faceDetected && _faceBoundingBox != null)
                                  CustomPaint(
                                    painter: _FaceBoundingBoxPainter(
                                      boundingBox: _faceBoundingBox!,
                                      imageWidth: _imageWidth,
                                      imageHeight: _imageHeight,
                                      sensorOrientation: _sensorOrientation,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFF41B37E)),
                        ),
                      ),
              ),

              // ── Face status indicator ──────────────────────────────
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _faceDetected
                          ? const Color(0xFF41B37E).withValues(alpha: 0.85)
                          : Colors.red.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _faceDetected ? Icons.face_retouching_natural : Icons.face_retouching_off,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _faceDetected ? 'Wajah Terdeteksi' : 'Wajah Tidak Terdeteksi',
                          style: const TextStyle(
                            fontFamily: AppFonts.nunito,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Captured face count indicator ─────────────────────
              if (_capturedFacePaths.isNotEmpty)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_camera, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${_capturedFacePaths.length}',
                          style: const TextStyle(
                            fontFamily: AppFonts.nunito,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Motion sequence collection indicator ───────────────
              Positioned(
                top: 56,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isMotionDataReady
                              ? '✅ Isyarat Siap!'
                              : _motionSequence.isEmpty
                              ? 'Tunjuk isyarat tanganmu'
                              : 'Rekam isyarat...',
                          style: const TextStyle(
                            fontFamily: AppFonts.nunito,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 120,
                          height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: (_motionSequence.length / _targetFrames).clamp(0.0, 1.0),
                              backgroundColor: Colors.white.withValues(alpha: 0.25),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isMotionDataReady
                                    ? const Color(0xFF41B37E)
                                    : const Color(0xFFFFC107),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Yellow circle background ───────────────────────────
              Positioned(
                left: circleLeft,
                bottom: circleBottom,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFBD30)),
                ),
              ),

              // ── Cimo mascot ────────────────────────────────────────
              Positioned(
                left: cimoLeft,
                bottom: cimoBottom,
                child: SizedBox(
                  width: cimoSize,
                  height: cimoSize,
                  child: Image.asset(AssetPaths.cimoJoy, fit: BoxFit.contain),
                ),
              ),

              // ── Send Button (bottom right) ─────────────────────────
              Positioned(
                right: 24,
                bottom: 40,
                child: GestureDetector(
                  onTap: _isSending ? null : _onSendPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: _isSending
                          ? Colors.grey
                          : (_faceDetected ? const Color(0xFF41B37E) : Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _isSending
                              ? Colors.grey.shade600
                              : (_faceDetected ? const Color(0xFF2D7D58) : Colors.grey.shade600),
                          offset: const Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSending)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        else ...[
                          Text(
                            'Kirim',
                            style: TextStyle(
                              fontFamily: AppFonts.nunito,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _faceDetected ? Colors.black : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.send,
                            color: _faceDetected ? Colors.black : Colors.white,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Face Bounding Box Overlay Painter
// ──────────────────────────────────────────────────────────────────────────────

class _FaceBoundingBoxPainter extends CustomPainter {
  final Rect boundingBox;
  final int imageWidth;
  final int imageHeight;
  final int sensorOrientation;

  _FaceBoundingBoxPainter({
    required this.boundingBox,
    required this.imageWidth,
    required this.imageHeight,
    required this.sensorOrientation,
  });

  /// Translate x from ML Kit coordinates → canvas coordinates.
  /// Based on the official Google ML Kit Flutter example.
  double _translateX(double x, Size canvasSize) {
    switch (sensorOrientation) {
      case 90:
        return x * canvasSize.width / imageHeight;
      case 270:
        // 270° includes horizontal mirroring (front camera)
        return canvasSize.width - x * canvasSize.width / imageHeight;
      default:
        return x * canvasSize.width / imageWidth;
    }
  }

  /// Translate y from ML Kit coordinates → canvas coordinates.
  double _translateY(double y, Size canvasSize) {
    switch (sensorOrientation) {
      case 90:
      case 270:
        return y * canvasSize.height / imageWidth;
      default:
        return y * canvasSize.height / imageHeight;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth == 0 || imageHeight == 0) return;

    final paint = Paint()
      ..color = const Color(0xFF41B37E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Translate all four edges using the ML Kit coordinate translator
    final x0 = _translateX(boundingBox.left, size);
    final x1 = _translateX(boundingBox.right, size);
    final y0 = _translateY(boundingBox.top, size);
    final y1 = _translateY(boundingBox.bottom, size);

    // For 270° rotation, x0 > x1 due to mirroring, so use min/max
    final scaledRect = Rect.fromLTRB(min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1));

    // Rounded rectangle
    canvas.drawRRect(RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)), paint);

    // Corner accents
    final cornerLen = min(scaledRect.width, scaledRect.height) * 0.2;
    final cp = Paint()
      ..color = const Color(0xFF41B37E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(scaledRect.topLeft, Offset(scaledRect.left + cornerLen, scaledRect.top), cp);
    canvas.drawLine(scaledRect.topLeft, Offset(scaledRect.left, scaledRect.top + cornerLen), cp);
    // Top-right
    canvas.drawLine(scaledRect.topRight, Offset(scaledRect.right - cornerLen, scaledRect.top), cp);
    canvas.drawLine(scaledRect.topRight, Offset(scaledRect.right, scaledRect.top + cornerLen), cp);
    // Bottom-left
    canvas.drawLine(
      scaledRect.bottomLeft,
      Offset(scaledRect.left + cornerLen, scaledRect.bottom),
      cp,
    );
    canvas.drawLine(
      scaledRect.bottomLeft,
      Offset(scaledRect.left, scaledRect.bottom - cornerLen),
      cp,
    );
    // Bottom-right
    canvas.drawLine(
      scaledRect.bottomRight,
      Offset(scaledRect.right - cornerLen, scaledRect.bottom),
      cp,
    );
    canvas.drawLine(
      scaledRect.bottomRight,
      Offset(scaledRect.right, scaledRect.bottom - cornerLen),
      cp,
    );
  }

  @override
  bool shouldRepaint(_FaceBoundingBoxPainter oldDelegate) => oldDelegate.boundingBox != boundingBox;
}

