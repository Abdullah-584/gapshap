/// Notification type
enum NotificationType {
  newMessage,
  reaction,
  storyInteraction,
  contactRequest,
  system,
}

/// Notification model
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String? title;
  final String? body;
  final String? conversationId;
  final String? storyId;
  final String? senderId;
  final String? senderUsername;
  final String? senderAvatarUrl;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    this.title,
    this.body,
    this.conversationId,
    this.storyId,
    this.senderId,
    this.senderUsername,
    this.senderAvatarUrl,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromSupabase(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      title: json['title'] as String?,
      body: json['body'] as String?,
      conversationId: json['conversation_id'] as String?,
      storyId: json['story_id'] as String?,
      senderId: json['sender_id'] as String?,
      senderUsername: json['sender_username'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }
}
