import 'dart:math';
import 'package:flutter/material.dart';

/// Responsive sizing helper for Bisimo app.
///
/// Scales all dimensions relative to a base mobile design (375 x 812).
/// On tablets and larger screens, scaling is capped so images and UI
/// elements don't become oversized.
///
/// Usage:
/// ```dart
/// final r = ResponsiveHelper.of(context);
/// Image.asset('...', width: r.img(120), height: r.img(120));
/// Text('Hello', style: TextStyle(fontSize: r.sp(16)));
/// SizedBox(height: r.h(24));
/// ```
class ResponsiveHelper {
  // ── Design reference (iPhone SE / standard mobile) ──
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;

  // ── Breakpoints ──
  static const double mobileMaxWidth = 600.0;
  static const double tabletMaxWidth = 900.0;

  final double screenWidth;
  final double screenHeight;

  ResponsiveHelper._({required this.screenWidth, required this.screenHeight});

  /// Construct from BuildContext (most common usage).
  factory ResponsiveHelper.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ResponsiveHelper._(
      screenWidth: mq.size.width,
      screenHeight: mq.size.height,
    );
  }

  // ───────── Raw scale factors ─────────

  double get _rawScaleW => screenWidth / _designWidth;
  double get _rawScaleH => screenHeight / _designHeight;

  // ───────── Capped scale factors ─────────

  /// Width-based scale capped at 1.3× for tablets/large screens.
  double get scaleWidth => min(_rawScaleW, 1.3);

  /// Height-based scale capped at 1.3×.
  double get scaleHeight => min(_rawScaleH, 1.3);

  // ───────── Device type helpers ─────────

  bool get isMobile => screenWidth < mobileMaxWidth;
  bool get isTablet =>
      screenWidth >= mobileMaxWidth && screenWidth < tabletMaxWidth;
  bool get isDesktop => screenWidth >= tabletMaxWidth;

  // ───────── Scaling methods ─────────

  /// Scale a dimension based on width (paddings, margins, widths).
  double w(double size) => size * scaleWidth;

  /// Scale a dimension based on height (vertical spacings, heights).
  double h(double size) => size * scaleHeight;

  /// Scale an image / asset / icon size.
  /// More conservative — capped at 1.2× on small tablets, 1.25× on large.
  double img(double baseSize) {
    if (isDesktop) return baseSize * min(_rawScaleW, 1.25);
    if (isTablet) return baseSize * min(_rawScaleW, 1.2);
    return baseSize * _rawScaleW;
  }

  /// Scale font size — most conservative to maintain readability.
  /// Capped at 1.15× on larger screens.
  double sp(double size) {
    if (screenWidth > mobileMaxWidth) {
      return size * min(_rawScaleW, 1.15);
    }
    return size * _rawScaleW;
  }

  /// Scale a border radius value.
  double radius(double size) => size * scaleWidth;

  /// Maximum content width — prevents overly-wide layouts on tablets.
  double get maxContentWidth =>
      isMobile ? screenWidth : min(screenWidth * 0.85, 600);

  /// Convenience: returns a symmetric horizontal padding that keeps
  /// content centred on wide screens.
  EdgeInsets get contentPadding {
    if (isMobile) return EdgeInsets.zero;
    final side = (screenWidth - maxContentWidth) / 2;
    return EdgeInsets.symmetric(horizontal: side);
  }
}
