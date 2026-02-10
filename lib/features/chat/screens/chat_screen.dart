import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../providers/chat_provider.dart';
import '../../../data/models/chat_message_model.dart';
import '../../emotion_detection/services/emotion_api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.emotionResult});

  // Corrected the type to CombinedEmotionResult
  final CombinedEmotionResult? emotionResult;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _initializeChat() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // Now this call matches the corrected provider method signature
    chatProvider.startChatSession(emotionResult: widget.emotionResult);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(ChatProvider provider) {
    final content = _messageController.text.trim();
    if (content.isNotEmpty && !provider.isTyping) {
      provider.sendMessage(content);
      _messageController.clear();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          _scrollToBottom();

          return Column(
            children: [
              _buildCimoEmotionCard(chatProvider),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(chatProvider.messages[index]);
                  },
                ),
              ),
              if (chatProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    chatProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              _buildInputArea(chatProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCimoEmotionCard(ChatProvider provider) {
    final bool hasEmotion = widget.emotionResult != null;
    final String emotionKey = widget.emotionResult?.finalEmotion.emotion.toLowerCase() ?? '';
    // Capitalize first letter for display
    final String displayEmotion = emotionKey.isNotEmpty
        ? '${emotionKey[0].toUpperCase()}${emotionKey.substring(1)}'
        : '';
    final List<Color> bgColors = hasEmotion
        ? _getEmotionBackgroundColors(emotionKey)
        : [const Color(0xFF5BC0EB), const Color(0xFF2E86C1)];
    final String cimoImage = hasEmotion
        ? AssetPaths.getCimoByEmotion(emotionKey)
        : AssetPaths.cimoJoy;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
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
                  color: bgColors[1].withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(cimoImage, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontFamily: AppFonts.sfProRounded,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              children: hasEmotion
                  ? [
                      const TextSpan(text: 'Perasaan: '),
                      TextSpan(
                        text: displayEmotion,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ]
                  : [
                      const TextSpan(
                        text: 'Ceritakan perasaanmu pada Cimo!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isUser = message.isFromUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
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
                    message.content,
                    style: TextStyle(
                      fontFamily: AppFonts.sfProRounded,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                // Tampilkan label emosi yang dideteksi IndoBERT
                if (isUser && message.detectedEmotion != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '😊 ${message.detectedEmotion}',
                      style: TextStyle(
                        fontFamily: AppFonts.sfProRounded,
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatProvider provider) {
    final isTyping = provider.isTyping;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 14,
                  color: isTyping ? Colors.grey.shade600 : Colors.black,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: isTyping ? 'Cimo sedang mengetik...' : 'Ketik pesan...',
                  hintStyle: const TextStyle(
                    fontFamily: AppFonts.sfProRounded,
                    color: AppColors.textHint,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(
                      color: isTyping ? Colors.grey.shade400 : Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(
                      color: isTyping ? Colors.grey.shade400 : Colors.grey.shade300,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(provider),
                readOnly: isTyping,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _sendMessage(provider),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isTyping ? Colors.grey.shade400 : const Color(0xFF5BC0EB),
                  shape: BoxShape.circle,
                ),
                child: isTyping
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        ),
                      )
                    : const Icon(Icons.arrow_forward, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getEmotionBackgroundColors(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'senang':
        return [const Color(0xFFFFD859), const Color(0xFFE5B800)];
      case 'sedih':
        return [const Color(0xFF5B9BD5), const Color(0xFF2E5984)];
      case 'marah':
        return [const Color(0xFFE57373), const Color(0xFFB71C1C)];
      case 'takut':
        return [const Color(0xFF9575CD), const Color(0xFF512DA8)];
      case 'terkejut':
        return [const Color(0xFFFFB74D), const Color(0xFFE65100)];
      case 'jijik':
        return [const Color(0xFF81C784), const Color(0xFF2E7D32)];
      default:
        return [const Color(0xFF5B9BD5), const Color(0xFF2E5984)];
    }
  }
}
