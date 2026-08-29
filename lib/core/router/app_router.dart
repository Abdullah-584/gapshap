import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/home/presentation/screens/home_shell.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/conversation_details_screen.dart';
import '../../features/chat/presentation/screens/message_search_screen.dart';
import '../../features/chat/presentation/screens/forward_message_screen.dart';
import '../../features/chat/presentation/screens/create_group_screen.dart';
import '../../features/chat/presentation/screens/media_viewer_screen.dart';
import '../../features/contacts/presentation/screens/search_users_screen.dart';
import '../../features/contacts/presentation/screens/user_profile_screen.dart';
import '../../features/stories/presentation/screens/story_viewer_screen.dart';
import '../../features/stories/presentation/screens/create_story_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/privacy_settings_screen.dart';
import '../../features/settings/presentation/screens/blocked_users_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../widgets/splash_screen.dart';

/// Route names
class RouteNames {
  RouteNames._();

  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const emailVerification = '/email-verification';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const chat = '/chat/:conversationId';
  static const conversationDetails = '/chat/:conversationId/details';
  static const messageSearch = '/chat/:conversationId/search';
  static const forwardMessage = '/forward-message';
  static const searchUsers = '/search-users';
  static const userProfile = '/user/:userId';
  static const storyViewer = '/story/:userId';
  static const createStory = '/create-story';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const settings = '/settings';
  static const privacySettings = '/settings/privacy';
  static const blockedUsers = '/settings/blocked-users';
  static const createGroup = '/create-group';
  static const mediaViewer = '/media-viewer';
}

/// Adapter that converts a Stream into a ChangeNotifier so GoRouter
/// can use it as a refreshListenable.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
    // Also notify immediately so the first redirect runs
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// App Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  // Watch the auth stream provider to get a broadcast stream for refreshListenable
  final authStream = ref.watch(authStateProvider.stream);
  final refreshNotifier = GoRouterRefreshStream(authStream);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,

    redirect: (context, state) {
      // Read the current auth state each time redirect runs
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.signup ||
          state.matchedLocation == RouteNames.forgotPassword ||
          state.matchedLocation == RouteNames.emailVerification;
      final isSplash = state.matchedLocation == RouteNames.splash;

      // Still loading — stay on splash
      if (authState.isLoading) {
        return isSplash ? null : RouteNames.splash;
      }

      // Not authenticated — go to login
      if (!isAuthenticated) {
        return isAuthRoute ? null : RouteNames.login;
      }

      // Authenticated but on auth route — go to home
      if (isAuthenticated && isAuthRoute) {
        return RouteNames.home;
      }

      return null;
    },

    routes: [
      // Splash
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.emailVerification,
        builder: (context, state) => const EmailVerificationScreen(),
      ),

      // Onboarding
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Home Shell (with bottom nav)
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/chats',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderScreen(title: 'Chats'),
            ),
          ),
          GoRoute(
            path: '/stories',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderScreen(title: 'Stories'),
            ),
          ),
          GoRoute(
            path: '/contacts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderScreen(title: 'Contacts'),
            ),
          ),
          GoRoute(
            path: '/profile-tab',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Chat
      GoRoute(
        path: RouteNames.chat,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: RouteNames.conversationDetails,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ConversationDetailsScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: RouteNames.messageSearch,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return MessageSearchScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: RouteNames.forwardMessage,
        builder: (context, state) {
          final messageId = state.uri.queryParameters['messageId'] ?? '';
          final content = state.uri.queryParameters['content'] ?? '';
          return ForwardMessageScreen(
            messageId: messageId,
            content: content,
          );
        },
      ),

      // Search & User
      GoRoute(
        path: RouteNames.searchUsers,
        builder: (context, state) => const SearchUsersScreen(),
      ),
      GoRoute(
        path: RouteNames.userProfile,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfileScreen(userId: userId);
        },
      ),

      // Stories
      GoRoute(
        path: RouteNames.storyViewer,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return StoryViewerScreen(userId: userId);
        },
      ),
      GoRoute(
        path: RouteNames.createStory,
        builder: (context, state) => const CreateStoryScreen(),
      ),

      // Profile
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),

      // Settings
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.privacySettings,
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.blockedUsers,
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: RouteNames.createGroup,
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: RouteNames.mediaViewer,
        builder: (context, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          final tag = state.uri.queryParameters['tag'];
          final isLocal = state.uri.queryParameters['local'] == 'true';
          return MediaViewerScreen(imageUrl: url, heroTag: tag, isLocal: isLocal);
        },
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.matchedLocation}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ),
  );
});

/// Placeholder for routes not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
