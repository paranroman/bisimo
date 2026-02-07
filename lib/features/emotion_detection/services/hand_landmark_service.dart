import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import '../models/hand_landmark_result.dart';

/// Service for detecting 21-point hand landmarks using the `hand_landmarker`
/// Flutter plugin, which wraps Google's MediaPipe Hand Landmarker task.
///
/// Pipeline (handled natively on Android via JNI):
///   CameraImage (YUV) → Native Kotlin → MediaPipe HandLandmarker → 21 (x,y,z)
///
/// The plugin bundles the `hand_landmarker.task` model internally, so no manual
/// model file is required. It handles palm detection + hand landmark detection
/// automatically.
class HandLandmarkService {
  HandLandmarkService._();

  HandLandmarkerPlugin? _plugin;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // ────────────────────────────────────────────────────────────────────────
  //  Factory & Lifecycle
  // ────────────────────────────────────────────────────────────────────────

  /// Creates and initialises the service (synchronous).
  static HandLandmarkService create({
    int numHands = 2,
    double minConfidence = 0.5,
    bool useGpu = true,
  }) {
    final service = HandLandmarkService._();
    service._init(numHands, minConfidence, useGpu);
    return service;
  }

  void _init(int numHands, double minConfidence, bool useGpu) {
    try {
      _plugin = HandLandmarkerPlugin.create(
        numHands: numHands,
        minHandDetectionConfidence: minConfidence,
        delegate: useGpu ? HandLandmarkerDelegate.gpu : HandLandmarkerDelegate.cpu,
      );
      _isInitialized = true;
      debugPrint(
        '[HandLandmarkService] ✅ Initialized — '
        'numHands: $numHands, confidence: $minConfidence, '
        'delegate: ${useGpu ? "GPU" : "CPU"}',
      );
    } catch (e) {
      debugPrint('[HandLandmarkService] ❌ Init failed: $e');
      _isInitialized = false;

      // Retry with CPU if GPU failed
      if (useGpu) {
        debugPrint('[HandLandmarkService] Retrying with CPU delegate...');
        _init(numHands, minConfidence, false);
      }
    }
  }

  /// Release native resources.
  void dispose() {
    _plugin?.dispose();
    _plugin = null;
    _isInitialized = false;
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Detection
  // ────────────────────────────────────────────────────────────────────────

  /// Detect hand landmarks from a [CameraImage] frame.
  ///
  /// The plugin handles YUV → native image conversion and runs both palm
  /// detection + hand landmark detection internally via MediaPipe. No
  /// manual cropping or preprocessing needed.
  ///
  /// **This method is synchronous** (runs via JNI on native side), so it
  /// can be called directly within the camera frame callback.
  ///
  /// Returns up to 2 [HandLandmarkResult] objects (left/right).
  ({HandLandmarkResult? left, HandLandmarkResult? right}) detectHands(
    CameraImage cameraImage,
    int sensorOrientation,
  ) {
    if (!_isInitialized || _plugin == null) {
      return (left: null, right: null);
    }

    // The plugin expects 3 YUV planes (Y, U, V).
    // Camera must use ImageFormatGroup.yuv420 to provide them.
    if (cameraImage.planes.length < 3) {
      debugPrint(
        '[HandLandmarkService] ⚠️ Expected 3 planes, got '
        '${cameraImage.planes.length}. Use ImageFormatGroup.yuv420.',
      );
      return (left: null, right: null);
    }

    try {
      // The detect method is synchronous (runs via JNI on native side)
      final hands = _plugin!.detect(cameraImage, sensorOrientation);

      if (hands.isEmpty) {
        return (left: null, right: null);
      }

      // Convert Hand objects to HandLandmarkResult and classify left/right
      HandLandmarkResult? leftResult;
      HandLandmarkResult? rightResult;

      for (final hand in hands) {
        if (hand.landmarks.length < 21) continue;

        final landmarks = hand.landmarks.map((lm) => Point3D(lm.x, lm.y, lm.z)).toList();

        final isLeft = _isLeftHand(landmarks);

        final result = HandLandmarkResult(
          landmarks: landmarks,
          confidence: 1.0,
          isLeftHand: isLeft,
        );

        if (isLeft && leftResult == null) {
          leftResult = result;
        } else if (!isLeft && rightResult == null) {
          rightResult = result;
        }
      }

      return (left: leftResult, right: rightResult);
    } catch (e) {
      debugPrint('[HandLandmarkService] Detection error: $e');
      return (left: null, right: null);
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Handedness Classification
  // ────────────────────────────────────────────────────────────────────────

  /// Determines if a hand is LEFT or RIGHT based on thumb direction relative
  /// to pinky MCP. For a front camera (mirrored image):
  ///   - Person's LEFT hand: thumb tip is to the RIGHT of pinky MCP
  ///   - Person's RIGHT hand: thumb tip is to the LEFT of pinky MCP
  bool _isLeftHand(List<Point3D> landmarks) {
    if (landmarks.length < 21) return false;

    final wrist = landmarks[HandLandmark.wrist];
    final thumbTip = landmarks[HandLandmark.thumbTip];
    final pinkyMcp = landmarks[HandLandmark.pinkyMcp];

    // Cross-product based: compare thumb direction vs palm direction
    final thumbDirX = thumbTip.x - wrist.x;
    final palmDirX = pinkyMcp.x - wrist.x;

    // If thumb and pinky are on opposite sides of wrist → use thumb side
    // For front camera: left hand has thumb pointing right (positive x)
    if (thumbDirX.abs() > 0.01 && palmDirX.abs() > 0.01) {
      return thumbDirX > palmDirX;
    }

    // Fallback: use wrist x position
    return wrist.x > 0.5;
  }
}
