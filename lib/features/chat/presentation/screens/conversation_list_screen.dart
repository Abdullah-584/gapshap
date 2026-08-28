import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

class _ConversationListScreenState
    extends ConsumerState<ConversationListScreen> {
  @override
  void initState() {
    super.initState();
    // Load conversations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsProvider.notifier).loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome 👋',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondaryDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.valueOrNull?.displayName ?? 'Chat',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    // Avatar
                    GestureDetector(
                      onTap: () => context.push(RouteNames.profile),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceDark,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: profile.valueOrNull?.avatarUrl != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl:
                                      profile.valueOrNull!.avatarUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Icon(
                                    Icons.person,
                                    color: AppColors.textSecondaryDark,
                                  ),
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.person,
                                    color: AppColors.textSecondaryDark,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: AppColors.textSecondaryDark,
                              ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: GestureDetector(
                  onTap: () => context.push(RouteNames.searchUsers),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search,
                            color: AppColors.textSecondaryDark, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Search conversations...',
                          style: TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),
            ),

            // Stories Section
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: _buildStoriesRow(),
              ),
            ),

            // Section title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Chats',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.archive_outlined, size: 20),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Conversations
            conversations.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: AppColors.textSecondaryDark.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppColors.textSecondaryDark),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a chat with your friends',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondaryDark),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final convo = list[index];
                      return _ConversationTile(conversation: convo);
                    },
                    childCount: list.length,
                  ),
                );
              },
              loading: () => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Loading conversations...',
                        style: TextStyle(color: AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('Failed to load conversations',
                          style: TextStyle(color: AppColors.textSecondaryDark)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref
                            .read(conversationsProvider.notifier)
                            .loadConversations(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesRow() {
    final profile = ref.watch(currentProfileProvider);

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Your Story
        _YourStoryCard(profile: profile.valueOrNull),
        const SizedBox(width: 12),
        // Other stories would be loaded from a provider
        // For now, show empty state
      ],
    );
  }
}

class _YourStoryCard extends StatelessWidget {
  final dynamic profile;
  const _YourStoryCard({this.profile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.createStory),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceDark,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  image: profile?.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(profile.avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profile?.avatarUrl == null
                    ? const Icon(Icons.person,
                        color: AppColors.textSecondaryDark, size: 28)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(Icons.add, size: 14, color: AppColors.textOnPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Your Story',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final dynamic conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final name = conversation.type.name == 'group'
        ? (conversation.name ?? 'Group')
        : (conversation.otherDisplayName ?? conversation.otherUsername ?? 'Unknown');
    final avatar = conversation.type.name == 'group'
        ? conversation.avatarUrl
        : conversation.otherAvatarUrl;
    final lastMessage = conversation.lastMessageContent ?? '';
    final time = conversation.lastMessageCreatedAt;
    final unread = conversation.unreadCount;

    return ListTile(
      onTap: () => context.push('/chat/${conversation.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Stack(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceDark,
            ),
            child: avatar != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatar,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Icon(Icons.person,
                          color: AppColors.textSecondaryDark),
                      errorWidget: (_, __, ___) => const Icon(Icons.person,
                          color: AppColors.textSecondaryDark),
                    ),
                  )
                : const Icon(Icons.person, color: AppColors.textSecondaryDark),
          ),
          if (conversation.otherUserIsOnline == true)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.online,
                  border: Border.all(color: AppColors.backgroundDark, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: unread > 0
              ? AppColors.textPrimaryDark
              : AppColors.textSecondaryDark,
          fontSize: 13,
          fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (time != null)
            Text(
              _formatTime(time),
              style: TextStyle(
                fontSize: 12,
                color: unread > 0
                    ? AppColors.primary
                    : AppColors.textSecondaryDark,
                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          if (unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 7) {
      return '${time.day}/${time.month}';
    } else if (diff.inDays > 0) {
      return timeago.format(time, locale: 'en_short');
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
