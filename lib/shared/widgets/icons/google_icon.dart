import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Google Icon widget using SVG asset
class GoogleIcon extends StatelessWidget {
  final double size;

  const GoogleIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/Screens/Auth/Google_Logo.svg', width: size, height: size);
  }
}
