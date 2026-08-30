import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/story.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/services/supabase_service.dart';

/// Stories provider
final storiesProvider =
    StateNotifierProvider<StoriesNotifier, AsyncValue<List<Story>>>(
  (ref) => StoriesNotifier(ref),
);

class StoriesNotifier extends StateNotifier<AsyncValue<List<Story>>> {
  final Ref ref;
  StoriesNotifier(this.ref) : super(const AsyncValue.loading());

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Future<void> loadStories() async {
    state = const AsyncValue.loading();
    try {
      final userId = ref.read(currentUserIdProvider);
      final twentyFourHoursAgo =
          DateTime.now().subtract(const Duration(hours: 24));

      List<dynamic> response;

      if (userId != null) {
        // Load own stories + stories from contacts only (WhatsApp-style)
        // First get contact IDs
        final contactsResponse = await _client
            .from('contacts')
            .select('contact_id')
            .eq('user_id', userId);

        final contactIds = contactsResponse
            .map((c) => c['contact_id'] as String)
            .toList();

        // Build query: own stories + contact stories
        final userIds = [userId, ...contactIds];

        response = await _client
            .from('stories')
            .select('*, user:profiles!stories_user_id_fkey(id, username, display_name, avatar_url)')
            .inFilter('user_id', userIds)
            .gte('created_at', twentyFourHoursAgo.toIso8601String())
            .order('created_at', ascending: false);
      } else {
        response = [];
      }

      final stories = response.map((json) {
        final user = json['user'] as Map<String, dynamic>?;
        return Story.fromSupabase({
          ...json,
          'username': user?['username'],
          'display_name': user?['display_name'],
          'avatar_url': user?['avatar_url'],
        });
      }).toList();

      state = AsyncValue.data(stories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create a story
  Future<void> createStory({
    required StoryType type,
    String? content,
    String? mediaUrl,
    String? caption,
    String? backgroundColor,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _client.from('stories').insert({
        'user_id': userId,
        'type': type.name,
        'content': content,
        'media_url': mediaUrl,
        'caption': caption,
        'background_color': backgroundColor,
        'expires_at': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      });

      loadStories();
    } catch (e) {
      rethrow;
    }
  }

  /// View a story (record the view)
  Future<void> viewStory(String storyId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _client.from('story_views').upsert({
        'story_id': storyId,
        'user_id': userId,
      });
    } catch (_) {
      // Silent fail
    }
  }

  /// Delete a story
  Future<void> deleteStory(String storyId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _client
          .from('stories')
          .delete()
          .eq('id', storyId)
          .eq('user_id', userId);

      loadStories();
    } catch (e) {
      rethrow;
    }
  }

  /// Get stories for a specific user
  Future<List<Story>> getUserStories(String userId) async {
    try {
      final twentyFourHoursAgo =
          DateTime.now().subtract(const Duration(hours: 24));

      final response = await _client
          .from('stories')
          .select()
          .eq('user_id', userId)
          .gte('created_at', twentyFourHoursAgo.toIso8601String())
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => Story.fromSupabase(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get story viewers
  Future<List<Map<String, dynamic>>> getStoryViewers(String storyId) async {
    try {
      final response = await _client
          .from('story_views')
          .select('user:profiles!story_views_user_id_fkey(id, username, display_name, avatar_url), viewed_at')
          .eq('story_id', storyId)
          .order('viewed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }
}
