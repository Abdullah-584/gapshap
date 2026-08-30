import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/stories_provider.dart';
import '../../domain/models/story.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final String userId;
  const StoryViewerScreen({super.key, required this.userId});

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  List<Story> _stories = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });

    _loadStories();
  }

  Future<void> _loadStories() async {
    final stories = await ref
        .read(storiesProvider.notifier)
        .getUserStories(widget.userId);

    if (mounted) {
      setState(() {
        _stories = stories;
        _isLoading = false;
      });

      if (_stories.isNotEmpty) {
        _startStory();
      }
    }
  }

  void _startStory() {
    if (_currentIndex < _stories.length) {
      final story = _stories[_currentIndex];
      // Record view
      ref.read(storiesProvider.notifier).viewStory(story.id);

      _progressController.reset();
      _progressController.forward();
    }
  }

  void _nextStory() {
    if (_currentIndex < _stories.length - 1) {
      setState(() => _currentIndex++);
      _startStory();
    } else {
      _closeViewer();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startStory();
    }
  }

  void _deleteStory(Story story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete Story'),
        content: const Text('Are you sure you want to delete this story?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(storiesProvider.notifier).deleteStory(story.id);
              if (mounted) _closeViewer();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _closeViewer() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.of(context).pop();
  }

  void _pauseStory() {
    _progressController.stop();
  }

  void _resumeStory() {
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.circle_outlined,
                  size: 64, color: AppColors.textSecondaryDark),
              const SizedBox(height: 16),
              const Text('No stories',
                  style: TextStyle(color: AppColors.textSecondaryDark)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _closeViewer,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    final story = _stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final x = details.localPosition.dx;
          final width = MediaQuery.of(context).size.width;

          if (x < width / 3) {
            _previousStory();
          } else if (x > width * 2 / 3) {
            _nextStory();
          } else {
            // Tap and hold to pause
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story content
            if (story.type == StoryType.image && story.mediaUrl != null)
              CachedNetworkImage(
                imageUrl: story.mediaUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: AppColors.surfaceDark,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                errorWidget: (_, _, _) => Container(
                  color: AppColors.surfaceDark,
                  child: const Icon(Icons.error, color: Colors.white),
                ),
              )
            else if (story.type == StoryType.text)
              Container(
                color: story.backgroundColor != null
                    ? Color(int.parse(
                        story.backgroundColor!.replaceFirst('#', '0xFF')))
                    : AppColors.surfaceDark,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      story.content ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(color: AppColors.surfaceDark),

            // Gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(_stories.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white30,
                      ),
                      child: index < _currentIndex
                          ? Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: Colors.white,
                              ),
                            )
                          : index == _currentIndex
                              ? AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, child) {
                                    return FractionallySizedBox(
                                      widthFactor: _progressController.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(2),
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : const SizedBox.shrink(),
                    ),
                  );
                }),
              ),
            ),

            // User info
            Positioned(
              top: MediaQuery.of(context).padding.top + 24,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceDark,
                    ),
                    child: story.avatarUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: story.avatarUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const Icon(Icons.person,
                                  color: Colors.white),
                              errorWidget: (_, _, _) =>
                                  const Icon(Icons.person, color: Colors.white),
                            ),
                          )
                        : const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.displayName ?? story.username ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          story.createdAt != null
                              ? timeago.format(story.createdAt!)
                              : '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Delete button (only for own stories)
                  if (story.userId == ref.watch(currentUserIdProvider))
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: () => _deleteStory(story),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _closeViewer,
                  ),
                ],
              ),
            ),

            // Bottom info
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  if (story.caption != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        story.caption!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  // View count — only visible to story owner (WhatsApp-style)
                  if (story.userId == ref.watch(currentUserIdProvider))
                    const SizedBox(height: 12),
                  if (story.userId == ref.watch(currentUserIdProvider))
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.visibility,
                            size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          '${story.viewCount} views',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
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
    );
  }
}
