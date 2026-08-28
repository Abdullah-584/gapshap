/// Story type enum
enum StoryType { image, video, text }

/// Story model
class Story {
  final String id;
  final String userId;
  final StoryType type;
  final String? content;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final String? backgroundColor;
  final String? fontFamily;
  final int viewCount;
  final bool isViewedByMe;
  final List<StoryViewer> viewers;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const Story({
    required this.id,
    required this.userId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    this.backgroundColor,
    this.fontFamily,
    this.viewCount = 0,
    this.isViewedByMe = false,
    this.viewers = const [],
    this.createdAt,
    this.expiresAt,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory Story.fromSupabase(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: StoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StoryType.image,
      ),
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      caption: json['caption'] as String?,
      backgroundColor: json['background_color'] as String?,
      fontFamily: json['font_family'] as String?,
      viewCount: json['view_count'] as int? ?? 0,
      isViewedByMe: json['is_viewed_by_me'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// Story viewer model
class StoryViewer {
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? viewedAt;

  const StoryViewer({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.viewedAt,
  });

  factory StoryViewer.fromSupabase(Map<String, dynamic> json) {
    return StoryViewer(
      userId: json['user_id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      viewedAt: json['viewed_at'] != null ? DateTime.parse(json['viewed_at'] as String) : null,
    );
  }
}
