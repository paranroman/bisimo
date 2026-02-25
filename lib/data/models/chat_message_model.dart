/// Chat message model for Cimo chat
class ChatMessageModel {
  final String id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final MessageStatus status;
  final String? detectedEmotion;
  final double? emotionConfidence;

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.detectedEmotion,
    this.emotionConfidence,
  });

  ChatMessageModel copyWith({
    String? id,
    String? content,
    bool? isFromUser,
    DateTime? timestamp,
    MessageStatus? status,
    String? detectedEmotion,
    double? emotionConfidence,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      isFromUser: isFromUser ?? this.isFromUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      detectedEmotion: detectedEmotion ?? this.detectedEmotion,
      emotionConfidence: emotionConfidence ?? this.emotionConfidence,
    );
  }
}

enum MessageStatus { sending, sent, delivered, read, failed }

