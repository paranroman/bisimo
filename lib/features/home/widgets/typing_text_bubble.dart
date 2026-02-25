import 'package:flutter/material.dart';
import '../../../core/constants/app_fonts.dart';

/// Dynamic text bubble with typing animation
/// Displays Cimo's greeting message with animated typing effect
/// Has a speech bubble tail pointing to bottom-left (towards Cimo)
class TypingTextBubble extends StatefulWidget {
  final String userName;
  final String greetingPrefix;
  final String greetingSuffix;
  final String bodyText;
  final String questionText;
  final Duration typingSpeed;

  const TypingTextBubble({
    super.key,
    required this.userName,
    this.greetingPrefix = 'Halo, ',
    this.greetingSuffix = '!\n',
    this.bodyText = 'Cimo ingin mendengarmu di sini,\n',
    this.questionText = 'bagaimana perasaanmu?',
    this.typingSpeed = const Duration(milliseconds: 30),
  });

  @override
  State<TypingTextBubble> createState() => _TypingTextBubbleState();
}

class _TypingTextBubbleState extends State<TypingTextBubble> {
  int _currentIndex = 0;
  bool _isTypingComplete = false;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
  }

  String get _fullText {
    return '${widget.greetingPrefix}${widget.userName}${widget.greetingSuffix}${widget.bodyText}${widget.questionText}';
  }

  void _startTypingAnimation() async {
    for (int i = 0; i <= _fullText.length; i++) {
      if (!mounted) return;
      await Future.delayed(widget.typingSpeed);
      if (!mounted) return;
      setState(() {
        _currentIndex = i;
      });
    }
    if (mounted) {
      setState(() {
        _isTypingComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(),
      child: Container(padding: const EdgeInsets.fromLTRB(20, 20, 20, 28), child: _buildRichText()),
    );
  }

  Widget _buildRichText() {
    // Calculate what portions of text to show based on current index
    final prefixEnd = widget.greetingPrefix.length;
    final nameEnd = prefixEnd + widget.userName.length;
    final suffixEnd = nameEnd + widget.greetingSuffix.length;
    final bodyEnd = suffixEnd + widget.bodyText.length;

    List<TextSpan> spans = [];

    // Greeting prefix (regular)
    if (_currentIndex > 0) {
      final showLength = _currentIndex.clamp(0, prefixEnd);
      spans.add(
        TextSpan(text: widget.greetingPrefix.substring(0, showLength), style: _regularStyle),
      );
    }

    // User name (bold)
    if (_currentIndex > prefixEnd) {
      final showLength = (_currentIndex - prefixEnd).clamp(0, widget.userName.length);
      spans.add(TextSpan(text: widget.userName.substring(0, showLength), style: _boldStyle));
    }

    // Greeting suffix (bold - part of greeting emphasis)
    if (_currentIndex > nameEnd) {
      final showLength = (_currentIndex - nameEnd).clamp(0, widget.greetingSuffix.length);
      spans.add(TextSpan(text: widget.greetingSuffix.substring(0, showLength), style: _boldStyle));
    }

    // Body text (regular)
    if (_currentIndex > suffixEnd) {
      final showLength = (_currentIndex - suffixEnd).clamp(0, widget.bodyText.length);
      spans.add(TextSpan(text: widget.bodyText.substring(0, showLength), style: _regularStyle));
    }

    // Question text (bold)
    if (_currentIndex > bodyEnd) {
      final showLength = (_currentIndex - bodyEnd).clamp(0, widget.questionText.length);
      spans.add(TextSpan(text: widget.questionText.substring(0, showLength), style: _boldStyle));
    }

    // Cursor (blinking effect when typing)
    if (!_isTypingComplete) {
      spans.add(
        const TextSpan(
          text: '|',
          style: TextStyle(
            fontFamily: AppFonts.lexend,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
          ),
        ),
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }

  TextStyle get _regularStyle => const TextStyle(
    fontFamily: AppFonts.lexend,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.black,
    height: 1.4,
  );

  TextStyle get _boldStyle => const TextStyle(
    fontFamily: AppFonts.lexend,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.black,
    height: 1.4,
  );
}

/// Custom painter for speech bubble with smooth curved tail pointing to Cimo's ear
class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFCCE1)
      ..style = PaintingStyle.fill;

    // More rounded bubble
    final radius = 24.0;

    final path = Path();

    // Start from top-left (after curve)
    path.moveTo(radius, 0);

    // Top edge
    path.lineTo(size.width - radius, 0);

    // Top-right corner (smooth curve)
    path.quadraticBezierTo(size.width, 0, size.width, radius);

    // Right edge
    path.lineTo(size.width, size.height - radius);

    // Bottom-right corner (smooth curve)
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);

    // Bottom edge - leave space for curved tail
    path.lineTo(radius + 20, size.height);

    // Curved tail pointing to bottom-left (Cimo's right ear)
    // Control point creates a smooth curve into the tail
    path.quadraticBezierTo(
      radius,
      size.height, // control point
      5,
      size.height + 18, // tail tip - pointing to Cimo's ear
    );

    // Curve back up from tail tip to left edge
    path.quadraticBezierTo(
      0,
      size.height - 10, // control point
      0,
      size.height - radius - 10, // back to left edge
    );

    // Left edge
    path.lineTo(0, radius);

    // Top-left corner (smooth curve)
    path.quadraticBezierTo(0, 0, radius, 0);

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

