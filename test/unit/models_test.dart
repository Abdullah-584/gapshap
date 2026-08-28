import 'package:flutter_test/flutter_test.dart';
import 'package:gapshap/features/auth/domain/models/app_user.dart';
import 'package:gapshap/features/chat/domain/models/conversation.dart';
import 'package:gapshap/features/chat/domain/models/message.dart';
import 'package:gapshap/features/stories/domain/models/story.dart';
import 'package:gapshap/features/notifications/domain/models/app_notification.dart';

void main() {
  group('AppProfile', () {
    test('creates from Supabase JSON', () {
      final json = {
        'id': 'test-id',
        'username': 'testuser',
        'display_name': 'Test User',
        'avatar_url': null,
        'bio': 'Hello',
        'is_online': true,
        'last_seen': '2026-01-01T00:00:00Z',
        'online_status_visibility': 'everyone',
        'last_seen_visibility': 'contacts',
        'profile_photo_visibility': 'everyone',
        'read_receipts_enabled': true,
        'typing_indicator_enabled': true,
        'story_visibility': 'everyone',
        'message_permission': 'everyone',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      final profile = AppProfile.fromSupabase(json);

      expect(profile.id, 'test-id');
      expect(profile.username, 'testuser');
      expect(profile.displayName, 'Test User');
      expect(profile.isOnline, true);
      expect(profile.lastSeenVisibility, 'contacts');
      expect(profile.readReceiptsEnabled, true);
    });

    test('copyWith works correctly', () {
      const profile = AppProfile(
        id: 'id',
        username: 'user',
        displayName: 'User',
      );

      final updated = profile.copyWith(
        displayName: 'New Name',
        bio: 'New bio',
      );

      expect(updated.displayName, 'New Name');
      expect(updated.bio, 'New bio');
      expect(updated.username, 'user'); // unchanged
    });

    test('serializes to Supabase format', () {
      const profile = AppProfile(
        id: 'id',
        username: 'user',
        displayName: 'User',
        bio: 'Bio',
      );

      final json = profile.toSupabase();

      expect(json['id'], 'id');
      expect(json['username'], 'user');
      expect(json['display_name'], 'User');
      expect(json['bio'], 'Bio');
    });
  });

  group('Conversation', () {
    test('creates from Supabase JSON - direct', () {
      final json = {
        'id': 'conv-1',
        'type': 'direct',
        'name': null,
        'avatar_url': null,
        'created_by': 'user-1',
        'last_message_content': 'Hello!',
        'last_message_created_at': '2026-01-01T00:00:00Z',
        'unread_count': 3,
        'is_pinned': false,
        'is_muted': false,
        'other_user_id': 'user-2',
        'other_username': 'jane',
        'other_display_name': 'Jane',
        'other_avatar_url': null,
        'other_user_is_online': true,
        'member_count': 2,
      };

      final convo = Conversation.fromSupabase(json);

      expect(convo.id, 'conv-1');
      expect(convo.type, ConversationType.direct);
      expect(convo.lastMessageContent, 'Hello!');
      expect(convo.unreadCount, 3);
      expect(convo.otherUserId, 'user-2');
      expect(convo.otherUserIsOnline, true);
    });

    test('creates from Supabase JSON - group', () {
      final json = {
        'id': 'conv-2',
        'type': 'group',
        'name': 'Dev Team',
        'created_by': 'user-1',
        'member_count': 5,
      };

      final convo = Conversation.fromSupabase(json);

      expect(convo.type, ConversationType.group);
      expect(convo.name, 'Dev Team');
      expect(convo.memberCount, 5);
    });
  });

  group('Message', () {
    test('creates from Supabase JSON', () {
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'sender_id': 'user-1',
        'type': 'text',
        'content': 'Hello!',
        'is_edited': false,
        'is_deleted': false,
        'reactions': {'👍': ['user-2', 'user-3'], '❤️': ['user-2']},
        'created_at': '2026-01-01T00:00:00Z',
        'sender_name': 'John',
        'sender_avatar_url': null,
      };

      final msg = Message.fromSupabase(json);

      expect(msg.id, 'msg-1');
      expect(msg.type, MessageType.text);
      expect(msg.content, 'Hello!');
      expect(msg.reactions['👍']?.length, 2);
      expect(msg.reactions['❤️']?.length, 1);
      expect(msg.senderName, 'John');
    });

    test('creates optimistic message', () {
      final msg = Message.optimistic(
        conversationId: 'conv-1',
        senderId: 'user-1',
        type: MessageType.text,
        content: 'Optimistic!',
        senderName: 'Me',
      );

      expect(msg.id.startsWith('temp_'), true);
      expect(msg.status, MessageStatus.sending);
      expect(msg.content, 'Optimistic!');
      expect(msg.senderName, 'Me');
    });

    test('copyWith preserves fields', () {
      final original = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        type: MessageType.text,
        content: 'Original',
        createdAt: DateTime(2026),
      );

      final updated = original.copyWith(
        content: 'Updated',
        status: MessageStatus.read,
      );

      expect(updated.content, 'Updated');
      expect(updated.status, MessageStatus.read);
      expect(updated.id, 'msg-1'); // preserved
      expect(updated.createdAt, DateTime(2026)); // preserved
    });

    test('handles deleted messages', () {
      final json = {
        'id': 'msg-2',
        'conversation_id': 'conv-1',
        'sender_id': 'user-1',
        'type': 'text',
        'content': null,
        'is_deleted': true,
        'created_at': '2026-01-01T00:00:00Z',
      };

      final msg = Message.fromSupabase(json);

      expect(msg.isDeleted, true);
      expect(msg.content, null);
    });

    test('handles reply messages', () {
      final json = {
        'id': 'msg-3',
        'conversation_id': 'conv-1',
        'sender_id': 'user-1',
        'type': 'text',
        'content': 'Reply!',
        'reply_to_message_id': 'msg-1',
        'reply_to_content': 'Original message',
        'reply_to_sender_name': 'Jane',
        'reply_to_type': 'text',
        'created_at': '2026-01-01T00:00:00Z',
      };

      final msg = Message.fromSupabase(json);

      expect(msg.replyToMessageId, 'msg-1');
      expect(msg.replyToContent, 'Original message');
      expect(msg.replyToSenderName, 'Jane');
      expect(msg.replyToType, MessageType.text);
    });
  });

  group('Story', () {
    test('creates from Supabase JSON', () {
      final json = {
        'id': 'story-1',
        'user_id': 'user-1',
        'type': 'image',
        'media_url': 'https://example.com/image.jpg',
        'view_count': 42,
        'created_at': '2026-01-01T00:00:00Z',
        'expires_at': '2026-01-02T00:00:00Z',
        'username': 'jane',
        'display_name': 'Jane',
        'avatar_url': null,
      };

      final story = Story.fromSupabase(json);

      expect(story.id, 'story-1');
      expect(story.type, StoryType.image);
      expect(story.viewCount, 42);
      expect(story.username, 'jane');
    });

    test('text story type', () {
      final json = {
        'id': 'story-2',
        'user_id': 'user-1',
        'type': 'text',
        'content': 'Hello World!',
        'background_color': '#FF0000',
        'created_at': '2026-01-01T00:00:00Z',
        'expires_at': '2026-01-02T00:00:00Z',
      };

      final story = Story.fromSupabase(json);

      expect(story.type, StoryType.text);
      expect(story.content, 'Hello World!');
      expect(story.backgroundColor, '#FF0000');
    });
  });

  group('AppNotification', () {
    test('creates from Supabase JSON', () {
      final json = {
        'id': 'notif-1',
        'user_id': 'user-1',
        'type': 'newMessage',
        'title': 'New Message',
        'body': 'Hello!',
        'conversation_id': 'conv-1',
        'sender_id': 'user-2',
        'is_read': false,
        'created_at': '2026-01-01T00:00:00Z',
      };

      final notif = AppNotification.fromSupabase(json);

      expect(notif.id, 'notif-1');
      expect(notif.type, NotificationType.newMessage);
      expect(notif.title, 'New Message');
      expect(notif.isRead, false);
    });
  });

  group('Enums', () {
    test('MessageType values', () {
      expect(MessageType.values.length, 6);
      expect(MessageType.text.name, 'text');
      expect(MessageType.image.name, 'image');
      expect(MessageType.voice.name, 'voice');
    });

    test('ConversationType values', () {
      expect(ConversationType.values.length, 2);
      expect(ConversationType.direct.name, 'direct');
      expect(ConversationType.group.name, 'group');
    });

    test('MessageStatus values', () {
      expect(MessageStatus.values.length, 5);
      expect(MessageStatus.sending.name, 'sending');
      expect(MessageStatus.read.name, 'read');
    });

    test('StoryType values', () {
      expect(StoryType.values.length, 3);
      expect(StoryType.image.name, 'image');
      expect(StoryType.video.name, 'video');
      expect(StoryType.text.name, 'text');
    });
  });
}
