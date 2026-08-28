import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/services/supabase_service.dart';

/// Contacts provider
final contactsProvider =
    StateNotifierProvider<ContactsNotifier, AsyncValue<List<AppProfile>>>(
  (ref) => ContactsNotifier(ref),
);

class ContactsNotifier extends StateNotifier<AsyncValue<List<AppProfile>>> {
  final Ref ref;
  ContactsNotifier(this.ref) : super(const AsyncValue.loading());

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Future<void> loadContacts() async {
    state = const AsyncValue.loading();
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final response = await _client
          .from('contacts')
          .select('contact:profiles!contacts_contact_id_fkey(*)')
          .eq('user_id', userId);

      final contacts = (response as List)
          .map((json) => AppProfile.fromSupabase(json['contact']))
          .toList();

      state = AsyncValue.data(contacts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add a contact
  Future<void> addContact(String contactId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await _client.from('contacts').insert({
      'user_id': userId,
      'contact_id': contactId,
    });

    loadContacts();
  }

  /// Remove a contact
  Future<void> removeContact(String contactId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await _client
        .from('contacts')
        .delete()
        .eq('user_id', userId)
        .eq('contact_id', contactId);

    loadContacts();
  }

  /// Block a user
  Future<void> blockUser(String userId) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    await _client.from('blocked_users').insert({
      'user_id': currentUserId,
      'blocked_user_id': userId,
    });

    loadContacts();
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    await _client
        .from('blocked_users')
        .delete()
        .eq('user_id', currentUserId)
        .eq('blocked_user_id', userId);

    loadContacts();
  }

  /// Search users by username or display name
  Future<List<AppProfile>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _client
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(20);

      return (response as List)
          .map((json) => AppProfile.fromSupabase(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get blocked users
  Future<List<AppProfile>> getBlockedUsers() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return [];

    try {
      final response = await _client
          .from('blocked_users')
          .select('blocked:profiles!blocked_users_blocked_user_id_fkey(*)')
          .eq('user_id', userId);

      return (response as List)
          .map((json) => AppProfile.fromSupabase(json['blocked']))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// Search results provider
final searchUsersProvider =
    FutureProvider.autoDispose<List<AppProfile>>((ref) async {
  return [];
});

/// User profile provider (for viewing other profiles)
final userProfileProvider =
    FutureProvider.autoDispose.family<AppProfile?, String>(
  (ref, userId) async {
    final client = ref.read(supabaseClientProvider);
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return AppProfile.fromSupabase(response);
    } catch (_) {
      return null;
    }
  },
);
