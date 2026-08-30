/// Conversation type
enum ConversationType { direct, group }

/// Conversation model
class Conversation {
  final String id;
  final ConversationType type;
  final String? name;
  final String? avatarUrl;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? lastMessageContent;
  final String? lastMessageSenderId;
  final DateTime? lastMessageCreatedAt;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final String? otherUserId;
  final String? otherUsername;
  final String? otherDisplayName;
  final String? otherAvatarUrl;
  final bool otherUserIsOnline;
  final int memberCount;

  const Conversation({
    required this.id,
    required this.type,
    this.name,
    this.avatarUrl,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.lastMessageContent,
    this.lastMessageSenderId,
    this.lastMessageCreatedAt,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.otherUserId,
    this.otherUsername,
    this.otherDisplayName,
    this.otherAvatarUrl,
    this.otherUserIsOnline = false,
    this.memberCount = 0,
  });

  factory Conversation.fromSupabase(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      type: json['type'] == 'group' ? ConversationType.group : ConversationType.direct,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      lastMessageContent: json['last_message_content'] as String?,
      lastMessageSenderId: json['last_message_sender_id'] as String?,
      lastMessageCreatedAt: json['last_message_created_at'] != null
          ? DateTime.parse(json['last_message_created_at'] as String)
          : null,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '') ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
      otherUserId: json['other_user_id'] as String?,
      otherUsername: json['other_username'] as String?,
      otherDisplayName: json['other_display_name'] as String?,
      otherAvatarUrl: json['other_avatar_url'] as String?,
      otherUserIsOnline: json['other_user_is_online'] as bool? ?? false,
      memberCount: int.tryParse(json['member_count']?.toString() ?? '') ?? 0,
    );
  }
}
