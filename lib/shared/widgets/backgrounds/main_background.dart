import 'package:flutter/material.dart';

/// Main background widget with decorative shapes
class MainBackground extends StatelessWidget {
  final Widget child;

  const MainBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/Screens/main_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}

