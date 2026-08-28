/// App user model
class AppUser {
  final String id;
  final String email;
  final String? username;

  const AppUser({
    required this.id,
    required this.email,
    this.username,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
    );
  }
}

/// Extended user profile
class AppProfile {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final bool isOnline;
  final DateTime? lastSeen;
  final String onlineStatusVisibility;
  final String lastSeenVisibility;
  final String profilePhotoVisibility;
  final bool readReceiptsEnabled;
  final bool typingIndicatorEnabled;
  final String storyVisibility;
  final String messagePermission;
  final bool isContact;
  final bool isBlocked;
  final bool isBlockedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.isOnline = false,
    this.lastSeen,
    this.onlineStatusVisibility = 'everyone',
    this.lastSeenVisibility = 'everyone',
    this.profilePhotoVisibility = 'everyone',
    this.readReceiptsEnabled = true,
    this.typingIndicatorEnabled = true,
    this.storyVisibility = 'everyone',
    this.messagePermission = 'everyone',
    this.isContact = false,
    this.isBlocked = false,
    this.isBlockedBy = false,
    this.createdAt,
    this.updatedAt,
  });

  AppProfile copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? isOnline,
    DateTime? lastSeen,
    String? onlineStatusVisibility,
    String? lastSeenVisibility,
    String? profilePhotoVisibility,
    bool? readReceiptsEnabled,
    bool? typingIndicatorEnabled,
    String? storyVisibility,
    String? messagePermission,
  }) {
    return AppProfile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      onlineStatusVisibility: onlineStatusVisibility ?? this.onlineStatusVisibility,
      lastSeenVisibility: lastSeenVisibility ?? this.lastSeenVisibility,
      profilePhotoVisibility: profilePhotoVisibility ?? this.profilePhotoVisibility,
      readReceiptsEnabled: readReceiptsEnabled ?? this.readReceiptsEnabled,
      typingIndicatorEnabled: typingIndicatorEnabled ?? this.typingIndicatorEnabled,
      storyVisibility: storyVisibility ?? this.storyVisibility,
      messagePermission: messagePermission ?? this.messagePermission,
      isContact: isContact,
      isBlocked: isBlocked,
      isBlockedBy: isBlockedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory AppProfile.fromSupabase(Map<String, dynamic> json) {
    return AppProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      onlineStatusVisibility: json['online_status_visibility'] as String? ?? 'everyone',
      lastSeenVisibility: json['last_seen_visibility'] as String? ?? 'everyone',
      profilePhotoVisibility: json['profile_photo_visibility'] as String? ?? 'everyone',
      readReceiptsEnabled: json['read_receipts_enabled'] as bool? ?? true,
      typingIndicatorEnabled: json['typing_indicator_enabled'] as bool? ?? true,
      storyVisibility: json['story_visibility'] as String? ?? 'everyone',
      messagePermission: json['message_permission'] as String? ?? 'everyone',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'online_status_visibility': onlineStatusVisibility,
      'last_seen_visibility': lastSeenVisibility,
      'profile_photo_visibility': profilePhotoVisibility,
      'read_receipts_enabled': readReceiptsEnabled,
      'typing_indicator_enabled': typingIndicatorEnabled,
      'story_visibility': storyVisibility,
      'message_permission': messagePermission,
    };
  }
}
