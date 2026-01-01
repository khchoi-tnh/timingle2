import 'package:equatable/equatable.dart';

/// 채팅 메시지 엔티티
class ChatMessage extends Equatable {
  final int eventId;
  final DateTime createdAt;
  final String messageId;
  final int senderId;
  final String senderName;
  final String? senderProfileUrl;
  final String message;
  final String messageType; // text, system, image
  final List<String>? attachments;
  final String? replyTo;
  final DateTime? editedAt;
  final bool isDeleted;
  final Map<String, String>? metadata;

  const ChatMessage({
    required this.eventId,
    required this.createdAt,
    required this.messageId,
    required this.senderId,
    required this.senderName,
    this.senderProfileUrl,
    required this.message,
    this.messageType = 'text',
    this.attachments,
    this.replyTo,
    this.editedAt,
    this.isDeleted = false,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        eventId,
        createdAt,
        messageId,
        senderId,
        senderName,
        senderProfileUrl,
        message,
        messageType,
        attachments,
        replyTo,
        editedAt,
        isDeleted,
        metadata,
      ];

  /// 시스템 메시지인지 확인
  bool get isSystemMessage => messageType == 'system';

  /// 이미지 메시지인지 확인
  bool get isImageMessage => messageType == 'image';

  /// 내 메시지인지 확인
  bool isMyMessage(int currentUserId) => senderId == currentUserId;
}
