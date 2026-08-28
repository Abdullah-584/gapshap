import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/services/supabase_service.dart';

// ═══════════════════════════════════════════════
// Conversations Provider
// ═══════════════════════════════════════════════

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, AsyncValue<List<Conversation>>>(
  (ref) => ConversationsNotifier(ref),
);

class ConversationsNotifier extends StateNotifier<AsyncValue<List<Conversation>>> {
  final Ref ref;
  RealtimeChannel? _channel;

  ConversationsNotifier(this.ref) : super(const AsyncValue.loading());

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Future<void> loadConversations() async {
    state = const AsyncValue.loading();
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final response = await _client.rpc('get_conversations', params: {
        'p_user_id': userId,
      });

      final conversations = (response as List)
          .map((json) => Conversation.fromSupabase(json))
          .toList();

      state = AsyncValue.data(conversations);
      _subscribeToUpdates();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeToUpdates() {
    _channel?.unsubscribe();
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    _channel = _client
        .channel('conversations:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversation_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => loadConversations(),
        )
        .subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  /// Create a direct conversation with another user
  Future<String> createDirectConversation(String otherUserId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');

    // Check if conversation already exists
    final existing = await _client.rpc('find_direct_conversation', params: {
      'p_user1': userId,
      'p_user2': otherUserId,
    });

    if (existing != null && (existing as List).isNotEmpty) {
      return existing[0]['id'] as String;
    }

    // Create new conversation
    final response = await _client.from('conversations').insert({
      'type': 'direct',
      'created_by': userId,
    }).select().single();

    final conversationId = response['id'] as String;

    // Add both members
    await _client.from('conversation_members').insert([
      {
        'conversation_id': conversationId,
        'user_id': userId,
        'role': 'member',
      },
      {
        'conversation_id': conversationId,
        'user_id': otherUserId,
        'role': 'member',
      },
    ]);

    loadConversations();
    return conversationId;
  }

  /// Create a group conversation
  Future<String> createGroupConversation({
    required String name,
    required List<String> memberIds,
    String? avatarUrl,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client.from('conversations').insert({
      'type': 'group',
      'name': name,
      'avatar_url': avatarUrl,
      'created_by': userId,
    }).select().single();

    final conversationId = response['id'] as String;

    // Add creator as admin
    final members = <Map<String, dynamic>>[
      {
        'conversation_id': conversationId,
        'user_id': userId,
        'role': 'admin',
      },
    ];

    // Add other members
    for (final memberId in memberIds) {
      members.add({
        'conversation_id': conversationId,
        'user_id': memberId,
        'role': 'member',
      });
    }

    await _client.from('conversation_members').insert(members);

    loadConversations();
    return conversationId;
  }

  /// Pin/unpin conversation
  Future<void> togglePin(String conversationId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await _client.from('conversation_members').upsert({
      'conversation_id': conversationId,
      'user_id': userId,
      'is_pinned': true, // Toggle handled by DB
    });

    loadConversations();
  }

  /// Mute/unmute conversation
  Future<void> toggleMute(String conversationId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await _client.from('conversation_members').upsert({
      'conversation_id': conversationId,
      'user_id': userId,
      'is_muted': true, // Toggle handled by DB
    });

    loadConversations();
  }

  /// Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    // Soft delete - just remove the member
    await _client
        .from('conversation_members')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);

    loadConversations();
  }
}

// ═══════════════════════════════════════════════
// Messages Provider for a specific conversation
// ═══════════════════════════════════════════════

final messagesProvider = StateNotifierProvider.autoDispose
    .family<MessagesNotifier, AsyncValue<List<Message>>, String>(
  (ref, conversationId) => MessagesNotifier(ref, conversationId),
);

class MessagesNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final Ref ref;
  final String conversationId;
  RealtimeChannel? _typingChannel;
  RealtimeChannel? _messagesChannel;
  DateTime? _oldestMessageAt;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  MessagesNotifier(this.ref, this.conversationId)
      : super(const AsyncValue.loading()) {
    _loadInitialMessages();
  }

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Future<void> _loadInitialMessages() async {
    try {
      final response = await _client
          .from('messages')
          .select('*, sender:profiles!messages_sender_id_fkey(id, username, display_name, avatar_url)')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(AppConfig.messagesPageSize);

      final messages = (response as List).map((json) {
        final sender = json['sender'] as Map<String, dynamic>?;
        return Message.fromSupabase({
          ...json,
          'sender_name': sender?['display_name'],
          'sender_avatar_url': sender?['avatar_url'],
        });
      }).toList();

      // Messages come in reverse order, reverse to show oldest first
      messages.sort((a, b) =>
          (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));

      if (messages.isNotEmpty) {
        _oldestMessageAt = messages.first.createdAt;
      }

      _hasMore = messages.length >= AppConfig.messagesPageSize;
      state = AsyncValue.data(messages);

      // Subscribe to new messages
      _subscribeToMessages();

      // Mark as read
      _markAsRead();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeToMessages() {
    _messagesChannel?.unsubscribe();

    _messagesChannel = _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: _onNewMessage,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: _onMessageUpdate,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: _onDeleteMessage,
        )
        .subscribe();
  }

  void _onNewMessage(PostgresChangePayload payload) async {
    final newRecord = payload.newRecord;
    final currentUserId = ref.read(currentUserIdProvider);

    // Don't add if we already have it (optimistic message)
    final currentMessages = state.valueOrNull ?? [];
    final tempMatch = currentMessages.where(
      (m) => m.id.startsWith('temp_') &&
          m.senderId == newRecord['sender_id'] &&
          m.content == newRecord['content'],
    );

    // Fetch full message with sender info
    try {
      final response = await _client
          .from('messages')
          .select('*, sender:profiles!messages_sender_id_fkey(id, username, display_name, avatar_url)')
          .eq('id', newRecord['id'])
          .single();

      final sender = response['sender'] as Map<String, dynamic>?;
      final message = Message.fromSupabase({
        ...response,
        'sender_name': sender?['display_name'],
        'sender_avatar_url': sender?['avatar_url'],
      });

      final updatedMessages = List<Message>.from(currentMessages);

      if (tempMatch.isNotEmpty) {
        // Replace optimistic message with real one
        final tempIndex = updatedMessages.indexOf(tempMatch.first);
        updatedMessages[tempIndex] = message;
      } else {
        // Add new message
        updatedMessages.add(message);
      }

      // Sort by created_at
      updatedMessages.sort((a, b) =>
          (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));

      state = AsyncValue.data(updatedMessages);

      // Mark as read if from other user
      if (message.senderId != currentUserId) {
        _markAsRead();
      }
    } catch (_) {
      // Fallback: add the basic message
      final message = Message.fromSupabase(newRecord);
      final updatedMessages = List<Message>.from(currentMessages);

      if (tempMatch.isNotEmpty) {
        final tempIndex = updatedMessages.indexOf(tempMatch.first);
        updatedMessages[tempIndex] = message;
      } else {
        updatedMessages.add(message);
      }

      updatedMessages.sort((a, b) =>
          (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
      state = AsyncValue.data(updatedMessages);
    }
  }

  void _onMessageUpdate(PostgresChangePayload payload) {
    final updatedRecord = payload.newRecord;
    final currentMessages = state.valueOrNull ?? [];

    final updatedMessages = currentMessages.map((m) {
      if (m.id == updatedRecord['id']) {
        return Message.fromSupabase(updatedRecord).copyWith(
          senderName: m.senderName,
          senderAvatarUrl: m.senderAvatarUrl,
        );
      }
      return m;
    }).toList();

    state = AsyncValue.data(updatedMessages);
  }

  void _onDeleteMessage(PostgresChangePayload payload) {
    final deletedRecord = payload.oldRecord;
    final currentMessages = state.valueOrNull ?? [];

    final updatedMessages = currentMessages
        .where((m) => m.id != deletedRecord['id'])
        .toList();

    state = AsyncValue.data(updatedMessages);
  }

  /// Load older messages (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;

    try {
      final response = await _client
          .from('messages')
          .select('*, sender:profiles!messages_sender_id_fkey(id, username, display_name, avatar_url)')
          .eq('conversation_id', conversationId)
          .lt('created_at', _oldestMessageAt?.toIso8601String() ?? '')
          .order('created_at', ascending: false)
          .limit(AppConfig.messagesPageSize);

      final messages = (response as List).map((json) {
        final sender = json['sender'] as Map<String, dynamic>?;
        return Message.fromSupabase({
          ...json,
          'sender_name': sender?['display_name'],
          'sender_avatar_url': sender?['avatar_url'],
        });
      }).toList();

      if (messages.isNotEmpty) {
        _oldestMessageAt = messages.last.createdAt;
        messages.sort((a, b) =>
            (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));

        final currentMessages = state.valueOrNull ?? [];
        state = AsyncValue.data([...messages, ...currentMessages]);
      }

      _hasMore = messages.length >= AppConfig.messagesPageSize;
    } catch (_) {
      // Silently fail pagination
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Send a text message with optimistic UI
  Future<void> sendTextMessage({
    required String content,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderName,
    MessageType? replyToType,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (userId == null) return;

    // Create optimistic message
    final optimisticMessage = Message.optimistic(
      conversationId: conversationId,
      senderId: userId,
      type: MessageType.text,
      content: content,
      replyToMessageId: replyToMessageId,
      replyToContent: replyToContent,
      replyToSenderName: replyToSenderName,
      replyToType: replyToType,
      senderName: profile?.displayName,
      senderAvatarUrl: profile?.avatarUrl,
    );

    // Add to local state immediately
    final currentMessages = state.valueOrNull ?? [];
    state = AsyncValue.data([...currentMessages, optimisticMessage]);

    try {
      // Insert into database
      final response = await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': userId,
        'type': MessageType.text.name,
        'content': content,
        'reply_to_message_id': replyToMessageId,
        'reply_to_content': replyToContent,
        'reply_to_sender_name': replyToSenderName,
        'reply_to_type': replyToType?.name,
      }).select().single();

      // The realtime callback will replace the optimistic message
      // But let's also update the status
      final updatedMessages = state.valueOrNull ?? [];
      final updatedList = updatedMessages.map((m) {
        if (m.id == optimisticMessage.id) {
          return m.copyWith(
            id: response['id'] as String,
            status: MessageStatus.sent,
            createdAt: DateTime.parse(response['created_at'] as String),
          );
        }
        return m;
      }).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      // Mark message as failed
      final updatedMessages = state.valueOrNull ?? [];
      final updatedList = updatedMessages.map((m) {
        if (m.id == optimisticMessage.id) {
          return m.copyWith(status: MessageStatus.failed);
        }
        return m;
      }).toList();
      state = AsyncValue.data(updatedList);
    }
  }

  /// Edit a message
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _client.from('messages').update({
        'content': newContent,
        'is_edited': true,
        'edited_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a message (for everyone)
  Future<void> deleteMessage(String messageId) async {
    try {
      await _client.from('messages').update({
        'is_deleted': true,
        'content': null,
      }).eq('id', messageId);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete message for me only (local)
  void deleteMessageForMe(String messageId) {
    final currentMessages = state.valueOrNull ?? [];
    state = AsyncValue.data(
      currentMessages.where((m) => m.id != messageId).toList(),
    );
  }

  /// Add reaction to message
  Future<void> addReaction(String messageId, String emoji) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _client.rpc('toggle_message_reaction', params: {
        'p_message_id': messageId,
        'p_user_id': userId,
        'p_emoji': emoji,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Mark conversation as read
  Future<void> _markAsRead() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _client.rpc('mark_conversation_read', params: {
        'p_conversation_id': conversationId,
        'p_user_id': userId,
      });
    } catch (_) {
      // Silent fail
    }
  }

  /// Retry sending a failed message
  Future<void> retryMessage(Message message) async {
    final currentMessages = state.valueOrNull ?? [];
    // Remove the failed message
    state = AsyncValue.data(
      currentMessages.where((m) => m.id != message.id).toList(),
    );

    // Resend
    if (message.type == MessageType.text) {
      sendTextMessage(content: message.content ?? '');
    }
  }

  void dispose() {
    _messagesChannel?.unsubscribe();
    _typingChannel?.unsubscribe();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════
// Typing Indicator Provider
// ═══════════════════════════════════════════════

final typingProvider = StateNotifierProvider.autoDispose
    .family<TypingNotifier, Set<String>, String>(
  (ref, conversationId) => TypingNotifier(ref, conversationId),
);

class TypingNotifier extends StateNotifier<Set<String>> {
  final Ref ref;
  final String conversationId;
  RealtimeChannel? _channel;
  Timer? _clearTimer;

  TypingNotifier(this.ref, this.conversationId) : super({}) {
    _subscribe();
  }

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  void _subscribe() {
    _channel = _client.channel('typing:$conversationId').onBroadcast(
      event: 'typing',
      callback: (payload) {
        final userId = payload['user_id'] as String?;
        if (userId != null && userId != ref.read(currentUserIdProvider)) {
          state = {...state, userId};
          _clearTimer?.cancel();
          _clearTimer = Timer(const Duration(seconds: 3), () {
            state = state.where((id) => id != userId).toSet();
          });
        }
      },
    ).subscribe();
  }

  void sendTypingIndicator() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    _channel?.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': userId},
    );
  }

  void dispose() {
    _channel?.unsubscribe();
    _clearTimer?.cancel();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════
// Conversation Details Provider
// ═══════════════════════════════════════════════

final conversationDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, conversationId) async {
  final client = ref.read(supabaseClientProvider);
  try {
    final response = await client
        .from('conversations')
        .select('*, members:conversation_members(*, user:profiles(id, username, display_name, avatar_url, is_online))')
        .eq('id', conversationId)
        .single();
    return response;
  } catch (_) {
    return null;
  }
});

// ═══════════════════════════════════════════════
// Saved Messages Provider
// ═══════════════════════════════════════════════

final savedMessagesProvider =
    StateNotifierProvider<SavedMessagesNotifier, AsyncValue<List<Message>>>(
  (ref) => SavedMessagesNotifier(ref),
);

class SavedMessagesNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final Ref ref;
  SavedMessagesNotifier(this.ref) : super(const AsyncValue.loading()) {
    load();
  }

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Future<void> load() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final response = await _client
          .from('saved_messages')
          .select('message:messages(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final messages = (response as List)
          .map((json) => Message.fromSupabase(json['message']))
          .toList();

      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveMessage(String messageId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _client.from('saved_messages').insert({
        'user_id': userId,
        'message_id': messageId,
      });
      load();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unsaveMessage(String messageId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _client
          .from('saved_messages')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId);
      load();
    } catch (e) {
      rethrow;
    }
  }
}
