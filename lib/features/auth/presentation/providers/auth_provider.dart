import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../domain/models/app_user.dart';

/// Auth state - uses StreamController for reliability.
/// The async* generator approach can hang if Supabase isn't ready or
/// if onAuthStateChange never emits. This version always emits immediately.
final authStateProvider = StreamProvider<User?>((ref) {
  final controller = StreamController<User?>.broadcast();
  final client = ref.read(supabaseClientProvider);

  // Emit current user IMMEDIATELY so the app never gets stuck loading
  controller.add(client.auth.currentUser);

  // Listen for auth state changes
  final subscription = client.auth.onAuthStateChange.listen((event) {
    if (!controller.isClosed) {
      controller.add(event.session?.user);
    }
  });

  // Cancel subscription when provider is disposed
  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Current user ID helper
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.id;
});

/// Current user profile provider
final currentProfileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<AppProfile?>>((ref) {
  return ProfileNotifier(ref);
});

class ProfileNotifier extends StateNotifier<AsyncValue<AppProfile?>> {
  final Ref ref;

  ProfileNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Load profile on creation
    _loadProfile();

    // Reload profile whenever auth state changes (login/logout)
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous != next) {
        _loadProfile();
      }
    });
  }

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Future<void> _loadProfile() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        state = AsyncValue.data(AppProfile.fromSupabase(response));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create or update profile
  Future<void> createProfile({
    required String username,
    required String displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');

    state = const AsyncValue.loading();

    try {
      final response = await _client.from('profiles').upsert({
        'id': userId,
        'username': username.toLowerCase(),
        'display_name': displayName,
        'bio': bio,
        'avatar_url': avatarUrl,
      }).select().single();

      state = AsyncValue.data(AppProfile.fromSupabase(response));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update profile
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');

    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      state = AsyncValue.data(AppProfile.fromSupabase(response));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings({
    String? onlineStatusVisibility,
    String? lastSeenVisibility,
    String? profilePhotoVisibility,
    bool? readReceiptsEnabled,
    bool? typingIndicatorEnabled,
    String? storyVisibility,
    String? messagePermission,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');

    try {
      final updates = <String, dynamic>{};
      if (onlineStatusVisibility != null) {
        updates['online_status_visibility'] = onlineStatusVisibility;
      }
      if (lastSeenVisibility != null) {
        updates['last_seen_visibility'] = lastSeenVisibility;
      }
      if (profilePhotoVisibility != null) {
        updates['profile_photo_visibility'] = profilePhotoVisibility;
      }
      if (readReceiptsEnabled != null) {
        updates['read_receipts_enabled'] = readReceiptsEnabled;
      }
      if (typingIndicatorEnabled != null) {
        updates['typing_indicator_enabled'] = typingIndicatorEnabled;
      }
      if (storyVisibility != null) {
        updates['story_visibility'] = storyVisibility;
      }
      if (messagePermission != null) {
        updates['message_permission'] = messagePermission;
      }

      final response = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      state = AsyncValue.data(AppProfile.fromSupabase(response));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Refresh profile
  Future<void> refresh() async => _loadProfile();

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id')
          .ilike('username', username.toLowerCase())
          .maybeSingle();
      return response == null;
    } catch (_) {
      return false;
    }
  }

  /// Sign up
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');

    try {
      // Delete profile data (RLS handles the rest)
      await _client.from('profiles').delete().eq('id', userId);
      await _client.auth.admin.deleteUser(userId);
    } catch (e) {
      rethrow;
    }
  }
}
