import '../../domain/entities/chat_message.dart';

/// 채팅 메시지 데이터 모델
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.eventId,
    required super.createdAt,
    required super.messageId,
    required super.senderId,
    required super.senderName,
    super.senderProfileUrl,
    required super.message,
    super.messageType = 'text',
    super.attachments,
    super.replyTo,
    super.editedAt,
    super.isDeleted = false,
    super.metadata,
  });

  /// JSON -> ChatMessageModel
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      eventId: json['event_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      messageId: json['message_id'] as String,
      senderId: json['sender_id'] as int,
      senderName: json['sender_name'] as String,
      senderProfileUrl: json['sender_profile_url'] as String?,
      message: json['message'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : null,
      replyTo: json['reply_to'] as String?,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      metadata: json['metadata'] != null
          ? Map<String, String>.from(json['metadata'] as Map)
          : null,
    );
  }

  /// ChatMessageModel -> JSON
  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'created_at': createdAt.toIso8601String(),
      'message_id': messageId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_profile_url': senderProfileUrl,
      'message': message,
      'message_type': messageType,
      'attachments': attachments,
      'reply_to': replyTo,
      'edited_at': editedAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'metadata': metadata,
    };
  }

  /// Entity -> Model
  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      eventId: entity.eventId,
      createdAt: entity.createdAt,
      messageId: entity.messageId,
      senderId: entity.senderId,
      senderName: entity.senderName,
      senderProfileUrl: entity.senderProfileUrl,
      message: entity.message,
      messageType: entity.messageType,
      attachments: entity.attachments,
      replyTo: entity.replyTo,
      editedAt: entity.editedAt,
      isDeleted: entity.isDeleted,
      metadata: entity.metadata,
    );
  }
}
