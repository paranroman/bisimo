import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';

/// Chat Screen - Obrolan bersama Cimo
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  // Default to happy Cimo
  final String _emotion = 'happy';
  final String _emotionIndonesian = 'Kebahagiaan';

  @override
  void initState() {
    super.initState();
    // Add initial Cimo message
    _addCimoInitialMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getEmotionMessage(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
      case 'happy':
        return 'Kamu sedang merasakan kebahagiaan. Senang sekali melihatmu bahagia! Semoga harimu terus menyenangkan. Ceritakan apa yang membuatmu senang hari ini.';
      case 'sad':
        return 'Kamu sedang merasakan kesedihan. Perasaanmu sangat valid. Itu pasti membuat mu frustrasi. Terima kasih sudah mau berbagi denganku di sini.';
      case 'angry':
        return 'Kamu sedang merasakan kemarahan. Perasaanmu sangat valid. Wajar jika kamu merasa kesal. Aku di sini untuk mendengarkanmu.';
      case 'fear':
        return 'Kamu sedang merasakan ketakutan. Perasaanmu sangat valid. Kamu tidak sendirian, aku di sini bersamamu. Ceritakan apa yang membuatmu takut.';
      case 'surprise':
        return 'Kamu sedang merasakan keterkejutan. Sepertinya ada sesuatu yang mengejutkanmu! Ceritakan apa yang terjadi.';
      case 'disgust':
        return 'Kamu sedang merasakan kejijikan. Perasaanmu sangat valid. Ceritakan apa yang membuatmu merasa seperti ini.';
      default:
        return 'Kamu sedang merasakan kesedihan. Perasaanmu sangat valid. Aku di sini untuk mendengarkanmu.';
    }
  }

  void _addCimoInitialMessage() {
    setState(() {
      _messages.add(
        ChatMessage(text: _getEmotionMessage(_emotion), isUser: false, timestamp: DateTime.now()),
      );
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate Cimo response (dummy for now)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(text: _getDummyResponse(), isUser: false, timestamp: DateTime.now()),
          );
        });
        _scrollToBottom();
      }
    });
  }

  String _getDummyResponse() {
    final responses = [
      'Aku mengerti perasaanmu. Terima kasih sudah berbagi denganku.',
      'Ceritakan lebih lanjut, aku di sini untuk mendengarkanmu.',
      'Perasaanmu sangat valid. Kamu tidak sendirian.',
      'Aku senang kamu mau berbagi cerita denganku.',
      'Bagaimana perasaanmu sekarang setelah bercerita?',
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Obrolan bersama Cimo',
          style: TextStyle(
            fontFamily: AppFonts.sfProRounded,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Cimo Emotion Display
          _buildCimoEmotionCard(),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  /// Get background gradient colors based on emotion
  List<Color> _getEmotionBackgroundColors(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
      case 'happy':
        // Cimo joy is cream/yellow, bg is yellow gradient
        return [const Color(0xFFFFD859), const Color(0xFFE5B800)];
      case 'sad':
        // Cimo sad is blue, bg is darker blue
        return [const Color(0xFF5B9BD5), const Color(0xFF2E5984)];
      case 'angry':
        // Cimo angry is red, bg is darker red
        return [const Color(0xFFE57373), const Color(0xFFB71C1C)];
      case 'fear':
        // Cimo fear is purple/violet, bg is darker purple
        return [const Color(0xFF9575CD), const Color(0xFF512DA8)];
      case 'surprise':
        // Cimo surprise is orange, bg is darker orange
        return [const Color(0xFFFFB74D), const Color(0xFFE65100)];
      case 'disgust':
        // Cimo disgust is green, bg is darker green
        return [const Color(0xFF81C784), const Color(0xFF2E7D32)];
      default:
        return [const Color(0xFF5B9BD5), const Color(0xFF2E5984)];
    }
  }

  Widget _buildCimoEmotionCard() {
    final bgColors = _getEmotionBackgroundColors(_emotion);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Cimo Avatar with emotion
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: bgColors[1].withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(AssetPaths.getCimoByEmotion(_emotion), fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 12),

          // Emotion Label
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: AppFonts.sfProRounded,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              children: [
                const TextSpan(text: 'Perasaan: '),
                TextSpan(
                  text: _emotionIndonesian,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF5BC0EB) : const Color(0xFFF8A5A5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Text Input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(fontFamily: AppFonts.sfProRounded, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.sfProRounded,
                      color: AppColors.textHint,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Send Button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Color(0xFF5BC0EB), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat Message Model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}
