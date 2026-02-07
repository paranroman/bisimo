import 'dart:math';

import '../models/hand_landmark_result.dart';

/// BISINDO Feature Extractor — Dart port of `extract_landmarks.py`
///
/// Computes **77 features per hand** (154 total for two hands) from 21
/// MediaPipe hand landmarks, using **wrist-relative coordinates**.
///
/// Feature layout per hand (77):
///   1. Relative coordinates:  20 landmarks × 3 = 60  (wrist = origin)
///   2. Hand scale:            1                       (wrist → middle MCP dist)
///   3. Wrist position (abs):  2                       (x, y only)
///   4. Palm orientation:      5                       (normal xyz + facing + openness)
///   5. Finger features:       9                       (5 extensions + 4 spreads)
///
/// Total: 77 × 2 hands = 154 features per frame.
class BisindoFeatureExtractor {
  BisindoFeatureExtractor({this.normalizeScale = true, this.includeFingerFeatures = true});

  /// If true, relative coordinates are divided by hand scale (translation +
  /// scale invariant). Matches Python `normalize_scale=True`.
  final bool normalizeScale;

  /// If true, includes finger extension & spread features (9 per hand).
  /// Matches Python `include_finger_features=True`.
  final bool includeFingerFeatures;

  // Feature dimensions per hand
  static const int _numRelativeCoords = 20 * 3; // 60
  static const int _numScale = 1;
  static const int _numWristPos = 2;
  static const int _numOrientation = 5;

  int get _numFingerFeatures => includeFingerFeatures ? 9 : 0;

  int get featuresPerHand =>
      _numRelativeCoords + _numScale + _numWristPos + _numOrientation + _numFingerFeatures;

  int get totalFeatures => featuresPerHand * 2; // 154

  // ────────────────────────────────────────────────────────────────────────
  //  Public API
  // ────────────────────────────────────────────────────────────────────────

  /// Extract 154 features from a pair of hand landmarks.
  ///
  /// Pass `null` if a hand was not detected — its features will be all zeros.
  List<double> extractFrameFeatures({HandLandmarkResult? leftHand, HandLandmarkResult? rightHand}) {
    final left = _extractHandFeatures(leftHand);
    final right = _extractHandFeatures(rightHand);
    return [...left, ...right];
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Per-Hand Feature Extraction  (mirrors Python `extract_hand_features`)
  // ────────────────────────────────────────────────────────────────────────

  List<double> _extractHandFeatures(HandLandmarkResult? hand) {
    if (hand == null || hand.confidence <= 0) {
      return List.filled(featuresPerHand, 0.0);
    }

    final lm = hand.landmarks;
    final features = <double>[];

    // 1. Relative coordinates (60 features)
    final (relCoords, handScale, wristPos) = _getRelativeCoordinates(lm);
    features.addAll(relCoords);

    // 2. Hand scale (1 feature)
    features.add(handScale);

    // 3. Wrist absolute position — x, y only (2 features)
    features.add(wristPos.x);
    features.add(wristPos.y);

    // 4. Palm orientation (5 features)
    final (palmNormal, palmFacing) = _calculatePalmNormal(lm);
    final openness = _calculateHandOpenness(lm);
    features.addAll([palmNormal.x, palmNormal.y, palmNormal.z, palmFacing, openness]);

    // 5. Finger features (9 features)
    if (includeFingerFeatures) {
      features.addAll(_calculateFingerExtensions(lm)); // 5
      features.addAll(_calculateFingerSpreads(lm)); // 4
    }

    assert(features.length == featuresPerHand);
    return features;
  }

  // ────────────────────────────────────────────────────────────────────────
  //  1. Relative Coordinates  (Python: get_relative_coordinates)
  // ────────────────────────────────────────────────────────────────────────

  /// Converts absolute landmarks to wrist-relative coordinates.
  ///
  /// Returns (relativeCoords[60], handScale, wristPoint).
  (List<double>, double, Point3D) _getRelativeCoordinates(List<Point3D> lm) {
    final wrist = lm[HandLandmark.wrist];

    // Hand scale = distance(wrist, middle_finger_MCP)
    final middleMcp = lm[HandLandmark.middleMcp];
    double handScale = (middleMcp - wrist).norm;
    if (handScale < 0.001) handScale = 0.001;

    final relCoords = <double>[];

    // Landmarks 1–20 (skip wrist at index 0)
    for (int i = 1; i <= 20; i++) {
      double relX = lm[i].x - wrist.x;
      double relY = lm[i].y - wrist.y;
      double relZ = lm[i].z - wrist.z;

      if (normalizeScale) {
        relX /= handScale;
        relY /= handScale;
        relZ /= handScale;
      }

      relCoords.addAll([relX, relY, relZ]);
    }

    return (relCoords, handScale, wrist);
  }

  // ────────────────────────────────────────────────────────────────────────
  //  4a. Palm Normal Vector  (Python: calculate_palm_normal)
  // ────────────────────────────────────────────────────────────────────────

  /// Returns (normalizedNormal, palmFacingScore).
  ///
  /// - `vec1 = middle_MCP - wrist`
  /// - `vec2 = pinky_MCP - index_MCP`
  /// - `normal = cross(vec1, vec2)`, normalised
  /// - `palmFacingScore = -normal.z`
  (Point3D, double) _calculatePalmNormal(List<Point3D> lm) {
    final wrist = lm[HandLandmark.wrist];
    final indexMcp = lm[HandLandmark.indexMcp];
    final pinkyMcp = lm[HandLandmark.pinkyMcp];
    final middleMcp = lm[HandLandmark.middleMcp];

    final vec1 = middleMcp - wrist;
    final vec2 = pinkyMcp - indexMcp;

    var normal = vec1.cross(vec2);
    final n = normal.norm;
    if (n > 0) {
      normal = normal / n;
    }

    final palmFacing = -normal.z;
    return (normal, palmFacing);
  }

  // ────────────────────────────────────────────────────────────────────────
  //  4b. Hand Openness  (Python: calculate_hand_openness)
  // ────────────────────────────────────────────────────────────────────────

  /// Returns a value in [0, 1]. 0 = fist, 1 = fully open.
  double _calculateHandOpenness(List<Point3D> lm) {
    final wrist = lm[HandLandmark.wrist];
    final middleMcp = lm[HandLandmark.middleMcp];
    final handScale = (middleMcp - wrist).norm;
    if (handScale < 0.001) return 0.0;

    const fingertips = [
      HandLandmark.thumbTip,
      HandLandmark.indexTip,
      HandLandmark.middleTip,
      HandLandmark.ringTip,
      HandLandmark.pinkyTip,
    ];

    double sum = 0;
    for (final idx in fingertips) {
      sum += (lm[idx] - wrist).norm / handScale;
    }
    final avgDist = sum / fingertips.length;

    // Typical range: 1.0 (closed) → 3.0 (open)
    return (avgDist - 1.0).clamp(0.0, 2.0) / 2.0;
  }

  // ────────────────────────────────────────────────────────────────────────
  //  5a. Finger Extensions  (Python: calculate_finger_extensions)
  // ────────────────────────────────────────────────────────────────────────

  /// Returns 5 values (one per finger), each in [0, 1].
  /// 1 = straight, 0 = fully bent.
  List<double> _calculateFingerExtensions(List<Point3D> lm) {
    // (base, pip, dip, tip) — same order as Python
    const fingerConfigs = [
      [HandLandmark.thumbCmc, HandLandmark.thumbMcp, HandLandmark.thumbIp, HandLandmark.thumbTip],
      [HandLandmark.indexMcp, HandLandmark.indexPip, HandLandmark.indexDip, HandLandmark.indexTip],
      [
        HandLandmark.middleMcp,
        HandLandmark.middlePip,
        HandLandmark.middleDip,
        HandLandmark.middleTip,
      ],
      [HandLandmark.ringMcp, HandLandmark.ringPip, HandLandmark.ringDip, HandLandmark.ringTip],
      [HandLandmark.pinkyMcp, HandLandmark.pinkyPip, HandLandmark.pinkyDip, HandLandmark.pinkyTip],
    ];

    final extensions = <double>[];
    for (final cfg in fingerConfigs) {
      final base = lm[cfg[0]];
      final pip = lm[cfg[1]];
      final dip = lm[cfg[2]];
      final tip = lm[cfg[3]];

      final vec1 = pip - base;
      final vec2 = dip - pip;
      final vec3 = tip - dip;

      final avgAngle = (_angleBetween(vec1, vec2) + _angleBetween(vec2, vec3)) / 2;
      extensions.add(1.0 - (avgAngle / pi));
    }
    return extensions;
  }

  // ────────────────────────────────────────────────────────────────────────
  //  5b. Finger Spreads  (Python: calculate_finger_spreads)
  // ────────────────────────────────────────────────────────────────────────

  /// Returns 4 values — normalised distances between adjacent fingertip pairs.
  List<double> _calculateFingerSpreads(List<Point3D> lm) {
    final wrist = lm[HandLandmark.wrist];
    final middleMcp = lm[HandLandmark.middleMcp];
    final handScale = (middleMcp - wrist).norm;
    if (handScale < 0.001) return List.filled(4, 0.0);

    const tipPairs = [
      [HandLandmark.thumbTip, HandLandmark.indexTip],
      [HandLandmark.indexTip, HandLandmark.middleTip],
      [HandLandmark.middleTip, HandLandmark.ringTip],
      [HandLandmark.ringTip, HandLandmark.pinkyTip],
    ];

    return tipPairs.map((pair) {
      return (lm[pair[0]] - lm[pair[1]]).norm / handScale;
    }).toList();
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Sequence Interpolation
  // ────────────────────────────────────────────────────────────────────────

  /// The fixed sequence length expected by the LSTM model.
  static const int modelSequenceLength = 60;

  /// Interpolate a variable-length motion sequence to [modelSequenceLength]
  /// frames using **linear interpolation** — the exact same method used in
  /// the Python training pipeline (`preprocess.py → interpolate_sequence`).
  ///
  /// Each frame is a `List<double>` of 154 features.
  /// Returns a new list of exactly [targetLength] frames.
  ///
  /// If [sequence] is empty, returns 60 zero-filled frames.
  /// If [sequence] has exactly 60 frames, returns a copy as-is.
  static List<List<double>> interpolateSequence(
    List<List<double>> sequence, {
    int targetLength = modelSequenceLength,
  }) {
    final currentLength = sequence.length;

    if (currentLength == 0) {
      return List.generate(targetLength, (_) => List.filled(154, 0.0));
    }

    if (currentLength == targetLength) {
      return sequence.map((f) => List<double>.from(f)).toList();
    }

    final numFeatures = sequence.first.length; // 154

    // Build evenly-spaced indices into the original sequence.
    // E.g. for 14→60:  [0.0, 0.22, 0.44, ..., 13.0]
    final indices = List<double>.generate(
      targetLength,
      (i) => i * (currentLength - 1) / (targetLength - 1),
    );

    final result = List<List<double>>.generate(targetLength, (_) => List.filled(numFeatures, 0.0));

    for (var f = 0; f < numFeatures; f++) {
      // Extract this feature across all original frames.
      final original = List<double>.generate(currentLength, (i) => sequence[i][f]);

      for (var t = 0; t < targetLength; t++) {
        final idx = indices[t];
        final lo = idx.floor().clamp(0, currentLength - 1);
        final hi = (lo + 1).clamp(0, currentLength - 1);
        final frac = idx - lo;

        // Linear interpolation: original[lo] + frac * (original[hi] - original[lo])
        result[t][f] = original[lo] + frac * (original[hi] - original[lo]);
      }
    }

    return result;
  }

  // ────────────────────────────────────────────────────────────────────────
  //  Vector Math Helpers
  // ────────────────────────────────────────────────────────────────────────

  /// Angle (in radians) between two 3D vectors.
  static double _angleBetween(Point3D v1, Point3D v2) {
    final denom = v1.norm * v2.norm + 1e-8;
    final cosAngle = (v1.dot(v2) / denom).clamp(-1.0, 1.0);
    return acos(cosAngle);
  }
}
