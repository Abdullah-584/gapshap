import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../../domain/models/conversation.dart';
import '../../../stories/presentation/providers/stories_provider.dart';
import '../../../stories/domain/models/story.dart';

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
    // Load conversations and stories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsProvider.notifier).loadConversations();
      ref.read(storiesProvider.notifier).loadStories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final profile = ref.watch(currentProfileProvider);
    final stories = ref.watch(storiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0ED),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome',
                                style: TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 0.2,
                                  color: Color(0xFF8F8A84),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.valueOrNull?.displayName ?? 'Chatdong',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push(RouteNames.profile),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE9E3DC),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: profile.valueOrNull?.avatarUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: profile.valueOrNull!.avatarUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, _) => const Icon(
                                        Icons.person,
                                        color: Color(0xFF7E7469),
                                      ),
                                      errorWidget: (_, _, _) => const Icon(
                                        Icons.person,
                                        color: Color(0xFF7E7469),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Color(0xFF7E7469),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                    child: GestureDetector(
                      onTap: () => context.push(RouteNames.searchUsers),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7E2DE),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: Color(0xFF7E7469),
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Search conversations...',
                              style: TextStyle(
                                color: Color(0xFF8C8178),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18, bottom: 8),
                    child: SizedBox(
                      height: 100,
                      child: _buildStoriesRow(stories),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Chat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'See all',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7E7469),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

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
                                color: const Color(
                                  0xFF8F8A84,
                                ).withValues(alpha: 0.75),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No conversations yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Start a chat with your friends',
                                style: TextStyle(color: Color(0xFF7E7469)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final convo = list[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                          child: _ConversationTile(conversation: convo),
                        );
                      }, childCount: list.length),
                    );
                  },
                  loading: () => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF1A1A1A),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Loading conversations...',
                            style: TextStyle(color: Color(0xFF7E7469)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Color(0xFFD15A5A),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Failed to load conversations',
                              style: TextStyle(color: Color(0xFFD15A5A)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e.toString(),
                              textAlign: TextAlign.center,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF7E7469),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesRow(AsyncValue<List<Story>> storiesState) {
    final profile = ref.watch(currentProfileProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    // Group stories by userId, only show non-expired, and group by user
    final storiesByUser = <String, Story>{};
    storiesState.whenData((list) {
      final now = DateTime.now();
      for (final story in list) {
        // Skip expired stories
        if (story.expiresAt != null && story.expiresAt!.isBefore(now)) continue;
        // Keep the first (most recent) story per user
        if (!storiesByUser.containsKey(story.userId)) {
          storiesByUser[story.userId] = story;
        }
      }
    });

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 18),
      children: [
        _YourStoryCard(profile: profile.valueOrNull),
        const SizedBox(width: 12),
        ...storiesByUser.entries.where((e) => e.key != currentUserId).map(
              (entry) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _StoryAvatar(
                  story: entry.value,
                ),
              ),
            ),
      ],
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final Story story;
  const _StoryAvatar({required this.story});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/story/${story.userId}'),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: story.isViewedByMe
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFF5E6C8), Color(0xFFD4C4A0)],
                    ),
              border: story.isViewedByMe
                  ? Border.all(color: const Color(0xFF555555), width: 2)
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE7E2DE),
              ),
              child: story.avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: story.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const Icon(
                          Icons.person,
                          color: Color(0xFF7E7469),
                          size: 28,
                        ),
                        errorWidget: (_, _, _) => const Icon(
                          Icons.person,
                          color: Color(0xFF7E7469),
                          size: 28,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Color(0xFF7E7469),
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 62,
            child: Text(
              story.displayName ?? story.username ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6E665F)),
            ),
          ),
        ],
      ),
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
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEAE1D8),
                  border: Border.all(
                    color: const Color(0xFF1A1A1A),
                    width: 1.5,
                  ),
                  image: profile?.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(profile.avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profile?.avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        color: Color(0xFF7E7469),
                        size: 28,
                      )
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
                    color: Color(0xFF1A1A1A),
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Add Story',
            style: TextStyle(color: Color(0xFF6E665F), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final name = conversation.type == ConversationType.group
        ? (conversation.name ?? 'Group')
        : (conversation.otherDisplayName ??
            conversation.otherUsername ??
            'Unknown');
    final avatar = conversation.type == ConversationType.group
        ? conversation.avatarUrl
        : conversation.otherAvatarUrl;
    final lastMessage = conversation.lastMessageContent ?? '';
    final time = conversation.lastMessageCreatedAt;
    final unread = conversation.unreadCount;

    return Material(
      color: const Color(0xFFF5F0EB),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/chat/${conversation.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7E0D8)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE7E2DE),
                    ),
                    child: avatar != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: avatar,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const Icon(
                                Icons.person,
                                color: Color(0xFF7E7469),
                              ),
                              errorWidget: (_, _, _) => const Icon(
                                Icons.person,
                                color: Color(0xFF7E7469),
                              ),
                            ),
                          )
                        : const Icon(Icons.person, color: Color(0xFF7E7469)),
                  ),
                  if (conversation.otherUserIsOnline == true)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF5CC26C),
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: unread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 15,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        if (time != null)
                          Text(
                            _formatTime(time),
                            style: TextStyle(
                              fontSize: 11,
                              color: unread > 0
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFF8F8A84),
                              fontWeight: unread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: unread > 0
                                  ? const Color(0xFF4E4A46)
                                  : const Color(0xFF8F8A84),
                            ),
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A1A1A),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
