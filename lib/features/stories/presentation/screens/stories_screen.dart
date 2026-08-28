import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/stories_provider.dart';

class StoriesScreen extends ConsumerStatefulWidget {
  const StoriesScreen({super.key});

  @override
  ConsumerState<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends ConsumerState<StoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storiesProvider.notifier).loadStories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesProvider);
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Text(
                  'Stories',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            // Create story card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => context.push('/create-story'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.backgroundDark,
                              ),
                              child: profile.valueOrNull?.avatarUrl != null
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            profile.valueOrNull!.avatarUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Icon(
                                            Icons.person,
                                            color: AppColors.textSecondaryDark),
                                        errorWidget: (_, __, ___) =>
                                            const Icon(Icons.person,
                                                color:
                                                    AppColors.textSecondaryDark),
                                      ),
                                    )
                                  : const Icon(Icons.person,
                                      color: AppColors.textSecondaryDark),
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
                                child: const Icon(Icons.add,
                                    size: 14, color: AppColors.textOnPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Create Story',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Share a moment',
                                style: TextStyle(
                                  color: AppColors.textSecondaryDark,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: AppColors.textSecondaryDark),
                      ],
                    ),
                  ),
                ).animate().fadeIn(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // Stories list
            stories.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.circle_outlined,
                              size: 64,
                              color: AppColors.textSecondaryDark
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No stories yet',
                            style: TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final story = list[index];
                      return _StoryCard(story: story);
                    },
                    childCount: list.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child:
                    Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      const Text('Failed to load stories'),
                      TextButton(
                        onPressed: () =>
                            ref.read(storiesProvider.notifier).loadStories(),
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
}

class _StoryCard extends StatelessWidget {
  final dynamic story;
  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push('/story/${story.userId}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: story.isViewedByMe
                ? AppColors.storyRingViewed
                : AppColors.storyRingUnread,
            width: 3,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceDark,
          ),
          child: story.avatarUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: story.avatarUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Icon(Icons.person,
                        color: AppColors.textSecondaryDark),
                    errorWidget: (_, __, ___) => const Icon(Icons.person,
                        color: AppColors.textSecondaryDark),
                  ),
                )
              : const Icon(Icons.person, color: AppColors.textSecondaryDark),
        ),
      ),
      title: Text(
        story.displayName ?? story.username ?? 'User',
        style: TextStyle(
          fontWeight: story.isViewedByMe ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${story.viewCount} views',
        style: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 13,
        ),
      ),
      trailing: story.type == 'video'
          ? const Icon(Icons.videocam, size: 18, color: AppColors.textSecondaryDark)
          : null,
    );
  }
}
