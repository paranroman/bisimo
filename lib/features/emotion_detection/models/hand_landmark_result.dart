import 'dart:math';

/// A 3D point with x, y, z coordinates.
///
/// Coordinates follow MediaPipe conventions:
///   - x, y are normalised to [0, 1] relative to image dimensions
///   - z represents depth relative to the wrist (negative = closer to camera)
class Point3D {
  final double x;
  final double y;
  final double z;

  const Point3D(this.x, this.y, this.z);

  const Point3D.zero() : x = 0, y = 0, z = 0;

  Point3D operator -(Point3D other) => Point3D(x - other.x, y - other.y, z - other.z);

  Point3D operator +(Point3D other) => Point3D(x + other.x, y + other.y, z + other.z);

  Point3D operator *(double scalar) => Point3D(x * scalar, y * scalar, z * scalar);

  Point3D operator /(double scalar) => Point3D(x / scalar, y / scalar, z / scalar);

  /// Euclidean distance (L2 norm) of this point.
  double get norm => sqrt(x * x + y * y + z * z);

  /// Dot product with [other].
  double dot(Point3D other) => x * other.x + y * other.y + z * other.z;

  /// Cross product with [other].
  Point3D cross(Point3D other) =>
      Point3D(y * other.z - z * other.y, z * other.x - x * other.z, x * other.y - y * other.x);

  /// Returns a unit-length version of this vector (or zero if norm is 0).
  Point3D get normalized {
    final n = norm;
    return n > 0 ? this / n : const Point3D.zero();
  }

  @override
  String toString() => 'Point3D($x, $y, $z)';
}

// ──────────────────────────────────────────────────────────────────────────────
// MediaPipe Hand Landmark Indices
// ──────────────────────────────────────────────────────────────────────────────

/// Standard 21 hand landmark indices (matches MediaPipe / Python enum).
class HandLandmark {
  HandLandmark._();

  static const int wrist = 0;
  static const int thumbCmc = 1;
  static const int thumbMcp = 2;
  static const int thumbIp = 3;
  static const int thumbTip = 4;
  static const int indexMcp = 5;
  static const int indexPip = 6;
  static const int indexDip = 7;
  static const int indexTip = 8;
  static const int middleMcp = 9;
  static const int middlePip = 10;
  static const int middleDip = 11;
  static const int middleTip = 12;
  static const int ringMcp = 13;
  static const int ringPip = 14;
  static const int ringDip = 15;
  static const int ringTip = 16;
  static const int pinkyMcp = 17;
  static const int pinkyPip = 18;
  static const int pinkyDip = 19;
  static const int pinkyTip = 20;

  static const int count = 21;
}

// ──────────────────────────────────────────────────────────────────────────────
// Hand Landmark Result
// ──────────────────────────────────────────────────────────────────────────────

/// Result from hand landmark detection for a single hand.
class HandLandmarkResult {
  /// 21 landmarks in MediaPipe order.
  final List<Point3D> landmarks;

  /// Confidence score for hand presence (0.0 – 1.0).
  final double confidence;

  /// Whether this is the left hand (true) or right hand (false).
  final bool isLeftHand;

  const HandLandmarkResult({
    required this.landmarks,
    required this.confidence,
    required this.isLeftHand,
  });

  /// Access a specific landmark by index.
  Point3D operator [](int index) => landmarks[index];

  /// Creates an empty (zeros) result — used for padding when a hand is not detected.
  factory HandLandmarkResult.empty({bool isLeft = true}) => HandLandmarkResult(
    landmarks: List.filled(HandLandmark.count, const Point3D.zero()),
    confidence: 0.0,
    isLeftHand: isLeft,
  );
}
