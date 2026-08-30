import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/auth/domain/models/app_user.dart';
import '../../features/chat/domain/models/conversation.dart';
import '../../features/chat/domain/models/message.dart';

/// Cache service provider
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

/// Local cache service using Hive
class CacheService {
  static const String _conversationsBox = 'conversations';
  static const String _messagesBox = 'messages';
  static const String _profileBox = 'profile';
  static const String _settingsBox = 'settings';
  static const String _contactsBox = 'contacts';

  Box? _conversations;
  Box? _messages;
  Box? _profile;
  Box? _settings;
  Box? _contacts;

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    await Hive.initFlutter();

    _conversations = await Hive.openBox(_conversationsBox);
    _messages = await Hive.openBox(_messagesBox);
    _profile = await Hive.openBox(_profileBox);
    _settings = await Hive.openBox(_settingsBox);
    _contacts = await Hive.openBox(_contactsBox);
  }

  // ═══════════════════════════════════════════
  // Conversations Cache
  // ═══════════════════════════════════════════

  /// Cache conversations
  Future<void> cacheConversations(List<Conversation> conversations) async {
    if (_conversations == null) return;

    final data = conversations.map((c) => {
      'id': c.id,
      'type': c.type.name,
      'name': c.name,
      'avatar_url': c.avatarUrl,
      'created_by': c.createdBy,
      'last_message_content': c.lastMessageContent,
      'last_message_sender_id': c.lastMessageSenderId,
      'last_message_created_at': c.lastMessageCreatedAt?.toIso8601String(),
      'unread_count': c.unreadCount,
      'is_pinned': c.isPinned,
      'is_muted': c.isMuted,
      'other_user_id': c.otherUserId,
      'other_username': c.otherUsername,
      'other_display_name': c.otherDisplayName,
      'other_avatar_url': c.otherAvatarUrl,
      'other_user_is_online': c.otherUserIsOnline,
      'member_count': c.memberCount,
    }).toList();

    await _conversations!.put('all', jsonEncode(data));
  }

  /// Get cached conversations
  List<Conversation> getCachedConversations() {
    if (_conversations == null) return [];

    final raw = _conversations!.get('all');
    if (raw == null) return [];

    try {
      final data = jsonDecode(raw as String) as List;
      return data.map((json) => Conversation.fromSupabase(json)).toList();
    } catch (_) {
      return [];
    }
  }

  // ═══════════════════════════════════════════
  // Messages Cache
  // ═══════════════════════════════════════════

  /// Cache messages for a conversation
  Future<void> cacheMessages(
      String conversationId, List<Message> messages) async {
    if (_messages == null) return;

    final data = messages.map((m) => {
      'id': m.id,
      'conversation_id': m.conversationId,
      'sender_id': m.senderId,
      'type': m.type.name,
      'content': m.content,
      'is_edited': m.isEdited,
      'is_deleted': m.isDeleted,
      'reply_to_message_id': m.replyToMessageId,
      'reply_to_content': m.replyToContent,
      'reply_to_sender_name': m.replyToSenderName,
      'reply_to_type': m.replyToType?.name,
      'attachment_url': m.attachmentUrl,
      'attachment_thumbnail_url': m.attachmentThumbnailUrl,
      'attachment_name': m.attachmentName,
      'attachment_mime_type': m.attachmentMimeType,
      'attachment_size': m.attachmentSize,
      'attachment_duration': m.attachmentDuration,
      'reactions': m.reactions,
      'created_at': m.createdAt?.toIso8601String(),
      'updated_at': m.updatedAt?.toIso8601String(),
      'edited_at': m.editedAt?.toIso8601String(),
      'sender_name': m.senderName,
      'sender_avatar_url': m.senderAvatarUrl,
    }).toList();

    await _messages!.put(conversationId, jsonEncode(data));
  }

  /// Get cached messages for a conversation
  List<Message> getCachedMessages(String conversationId) {
    if (_messages == null) return [];

    final raw = _messages!.get(conversationId);
    if (raw == null) return [];

    try {
      final data = jsonDecode(raw as String) as List;
      return data.map((json) => Message.fromSupabase(json)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Add a single message to cache
  Future<void> addMessageToCache(Message message) async {
    final cached = getCachedMessages(message.conversationId);

    // Don't add duplicates
    if (cached.any((m) => m.id == message.id)) return;

    cached.add(message);

    // Keep only last 100 messages per conversation
    if (cached.length > 100) {
      cached.removeRange(0, cached.length - 100);
    }

    await cacheMessages(message.conversationId, cached);
  }

  /// Update message in cache
  Future<void> updateMessageInCache(Message message) async {
    final cached = getCachedMessages(message.conversationId);
    final index = cached.indexWhere((m) => m.id == message.id);

    if (index != -1) {
      cached[index] = message;
      await cacheMessages(message.conversationId, cached);
    }
  }

  /// Remove message from cache
  Future<void> removeMessageFromCache(
      String conversationId, String messageId) async {
    final cached = getCachedMessages(conversationId);
    cached.removeWhere((m) => m.id == messageId);
    await cacheMessages(conversationId, cached);
  }

  // ═══════════════════════════════════════════
  // Profile Cache
  // ═══════════════════════════════════════════

  /// Cache user profile
  Future<void> cacheProfile(AppProfile profile) async {
    if (_profile == null) return;

    final data = {
      'id': profile.id,
      'username': profile.username,
      'display_name': profile.displayName,
      'avatar_url': profile.avatarUrl,
      'bio': profile.bio,
      'is_online': profile.isOnline,
      'last_seen': profile.lastSeen?.toIso8601String(),
      'online_status_visibility': profile.onlineStatusVisibility,
      'last_seen_visibility': profile.lastSeenVisibility,
      'profile_photo_visibility': profile.profilePhotoVisibility,
      'read_receipts_enabled': profile.readReceiptsEnabled,
      'typing_indicator_enabled': profile.typingIndicatorEnabled,
      'story_visibility': profile.storyVisibility,
      'message_permission': profile.messagePermission,
      'created_at': profile.createdAt?.toIso8601String(),
      'updated_at': profile.updatedAt?.toIso8601String(),
    };

    await _profile!.put(profile.id, jsonEncode(data));
  }

  /// Get cached profile
  AppProfile? getCachedProfile(String userId) {
    if (_profile == null) return null;

    final raw = _profile!.get(userId);
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      return AppProfile.fromSupabase(data);
    } catch (_) {
      return null;
    }
  }

  /// Get current user's cached profile
  AppProfile? getCurrentProfile() {
    if (_profile == null) return null;

    final raw = _profile!.get('current');
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      return AppProfile.fromSupabase(data);
    } catch (_) {
      return null;
    }
  }

  /// Cache current user profile
  Future<void> cacheCurrentProfile(AppProfile profile) async {
    if (_profile == null) return;

    final data = {
      'id': profile.id,
      'username': profile.username,
      'display_name': profile.displayName,
      'avatar_url': profile.avatarUrl,
      'bio': profile.bio,
      'online_status_visibility': profile.onlineStatusVisibility,
      'last_seen_visibility': profile.lastSeenVisibility,
      'profile_photo_visibility': profile.profilePhotoVisibility,
      'read_receipts_enabled': profile.readReceiptsEnabled,
      'typing_indicator_enabled': profile.typingIndicatorEnabled,
      'story_visibility': profile.storyVisibility,
      'message_permission': profile.messagePermission,
      'created_at': profile.createdAt?.toIso8601String(),
      'updated_at': profile.updatedAt?.toIso8601String(),
    };

    await _profile!.put('current', jsonEncode(data));
  }

  // ═══════════════════════════════════════════
  // Contacts Cache
  // ═══════════════════════════════════════════

  /// Cache contacts
  Future<void> cacheContacts(List<AppProfile> contacts) async {
    if (_contacts == null) return;

    final data = contacts.map((c) => {
      'id': c.id,
      'username': c.username,
      'display_name': c.displayName,
      'avatar_url': c.avatarUrl,
      'bio': c.bio,
      'is_online': c.isOnline,
      'last_seen': c.lastSeen?.toIso8601String(),
    }).toList();

    await _contacts!.put('all', jsonEncode(data));
  }

  /// Get cached contacts
  List<AppProfile> getCachedContacts() {
    if (_contacts == null) return [];

    final raw = _contacts!.get('all');
    if (raw == null) return [];

    try {
      final data = jsonDecode(raw as String) as List;
      return data.map((json) => AppProfile.fromSupabase(json)).toList();
    } catch (_) {
      return [];
    }
  }

  // ═══════════════════════════════════════════
  // Settings Cache
  // ═══════════════════════════════════════════

  /// Cache a setting
  Future<void> cacheSetting(String key, dynamic value) async {
    if (_settings == null) return;
    await _settings!.put(key, value);
  }

  /// Get a cached setting
  T? getSetting<T>(String key) {
    if (_settings == null) return null;
    return _settings!.get(key) as T?;
  }

  // ═══════════════════════════════════════════
  // Cleanup
  // ═══════════════════════════════════════════

  /// Clear all cache
  Future<void> clearAll() async {
    await _conversations?.clear();
    await _messages?.clear();
    await _profile?.clear();
    await _settings?.clear();
    await _contacts?.clear();
  }

  /// Clear messages cache for a specific conversation
  Future<void> clearConversationMessagesCache(String conversationId) async {
    await _messages?.delete(conversationId);
  }

  /// Clear all messages cache
  Future<void> clearMessagesCache() async {
    await _messages?.clear();
  }

  /// Close Hive boxes
  Future<void> close() async {
    await Hive.close();
  }
}
