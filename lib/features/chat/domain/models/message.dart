/// Message type enum
enum MessageType { text, image, video, file, voice, system }

/// Message status
enum MessageStatus { sending, sent, delivered, read, failed }

/// Message model
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String? content;
  final MessageStatus status;
  final bool isEdited;
  final bool isDeleted;
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToSenderName;
  final MessageType? replyToType;
  final String? attachmentUrl;
  final String? attachmentThumbnailUrl;
  final String? attachmentName;
  final String? attachmentMimeType;
  final int? attachmentSize;
  final double? attachmentDuration;
  final Map<String, List<String>> reactions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? editedAt;
  final String? senderName;
  final String? senderAvatarUrl;
  final bool isReadByOther;
  final bool isDeliveredToOther;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    this.content,
    this.status = MessageStatus.sent,
    this.isEdited = false,
    this.isDeleted = false,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderName,
    this.replyToType,
    this.attachmentUrl,
    this.attachmentThumbnailUrl,
    this.attachmentName,
    this.attachmentMimeType,
    this.attachmentSize,
    this.attachmentDuration,
    this.reactions = const {},
    this.createdAt,
    this.updatedAt,
    this.editedAt,
    this.senderName,
    this.senderAvatarUrl,
    this.isReadByOther = false,
    this.isDeliveredToOther = false,
  });

  Message copyWith({
    String? id,
    String? content,
    MessageStatus? status,
    bool? isEdited,
    bool? isDeleted,
    Map<String, List<String>>? reactions,
    String? senderName,
    String? senderAvatarUrl,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId,
      senderId: senderId,
      type: type,
      content: content ?? this.content,
      status: status ?? this.status,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToMessageId: replyToMessageId,
      replyToContent: replyToContent,
      replyToSenderName: replyToSenderName,
      replyToType: replyToType,
      attachmentUrl: attachmentUrl,
      attachmentThumbnailUrl: attachmentThumbnailUrl,
      attachmentName: attachmentName,
      attachmentMimeType: attachmentMimeType,
      attachmentSize: attachmentSize,
      attachmentDuration: attachmentDuration,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt,
      editedAt: editedAt,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      isReadByOther: isReadByOther,
      isDeliveredToOther: isDeliveredToOther,
    );
  }

  factory Message.fromSupabase(Map<String, dynamic> json) {
    final reactionsJson = json['reactions'] as Map<String, dynamic>?;
    final reactions = <String, List<String>>{};
    if (reactionsJson != null) {
      reactionsJson.forEach((key, value) {
        if (value is List) {
          reactions[key] = List<String>.from(value);
        }
      });
    }

    MessageType type = MessageType.text;
    if (json['type'] != null) {
      type = MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      );
    }

    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      type: type,
      content: json['content'] as String?,
      status: MessageStatus.delivered,
      isEdited: json['is_edited'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      replyToMessageId: json['reply_to_message_id'] as String?,
      replyToContent: json['reply_to_content'] as String?,
      replyToSenderName: json['reply_to_sender_name'] as String?,
      replyToType: json['reply_to_type'] != null
          ? MessageType.values.firstWhere(
              (e) => e.name == json['reply_to_type'],
              orElse: () => MessageType.text,
            )
          : null,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentThumbnailUrl: json['attachment_thumbnail_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      attachmentMimeType: json['attachment_mime_type'] as String?,
      attachmentSize: json['attachment_size'] as int?,
      attachmentDuration: (json['attachment_duration'] as num?)?.toDouble(),
      reactions: reactions,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at'] as String) : null,
      senderName: json['sender_name'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      isReadByOther: json['is_read_by_other'] as bool? ?? false,
      isDeliveredToOther: json['is_delivered_to_other'] as bool? ?? false,
    );
  }

  /// Create an optimistic message (before sending to server)
  factory Message.optimistic({
    required String conversationId,
    required String senderId,
    required MessageType type,
    String? content,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderName,
    MessageType? replyToType,
    String? attachmentUrl,
    String? attachmentThumbnailUrl,
    String? attachmentName,
    String? attachmentMimeType,
    int? attachmentSize,
    double? attachmentDuration,
    String? senderName,
    String? senderAvatarUrl,
  }) {
    return Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      type: type,
      content: content,
      status: MessageStatus.sending,
      replyToMessageId: replyToMessageId,
      replyToContent: replyToContent,
      replyToSenderName: replyToSenderName,
      replyToType: replyToType,
      attachmentUrl: attachmentUrl,
      attachmentThumbnailUrl: attachmentThumbnailUrl,
      attachmentName: attachmentName,
      attachmentMimeType: attachmentMimeType,
      attachmentSize: attachmentSize,
      attachmentDuration: attachmentDuration,
      createdAt: DateTime.now(),
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
    );
  }
}
