import '../../../../core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/contacts_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final isMe = currentUserId == userId;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isMe)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              color: AppColors.surfaceDark,
              onSelected: (value) {
                switch (value) {
                  case 'block':
                    ref.read(contactsProvider.notifier).blockUser(userId);
                    context.showSuccessSnackBar('User blocked');
                    break;
                  case 'report':
                    _showReportDialog(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'block',
                  child: Text('Block User',
                      style: TextStyle(color: AppColors.error)),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Report User'),
                ),
              ],
            ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('User not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceDark,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  child: profile.avatarUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: profile.avatarUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const Icon(Icons.person,
                                size: 48, color: AppColors.textSecondaryDark),
                            errorWidget: (_, _, _) => const Icon(
                                Icons.person,
                                size: 48,
                                color: AppColors.textSecondaryDark),
                          ),
                        )
                      : const Icon(Icons.person,
                          size: 48, color: AppColors.textSecondaryDark),
                ).animate().fadeIn().scale(),
                const SizedBox(height: 20),

                // Name
                Text(
                  profile.displayName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 4),

                // Username
                Text(
                  '@${profile.username}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),

                // Online status
                if (profile.isOnline)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.online),
                      SizedBox(width: 6),
                      Text('Online',
                          style: TextStyle(
                              color: AppColors.online, fontSize: 13)),
                    ],
                  )
                else if (profile.lastSeen != null)
                  Text(
                    'Last seen ${profile.lastSeen}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                  ),

                const SizedBox(height: 16),

                // Bio
                if (profile.bio != null && profile.bio!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      profile.bio!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 32),

                // Action buttons
                if (!isMe) ...[
                  // Message button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final chatId = await ref
                            .read(conversationsProvider.notifier)
                            .createDirectConversation(userId);
                        if (context.mounted) {
                          context.push('/chat/$chatId');
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Send Message'),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 12),

                  // Add contact button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(contactsProvider.notifier)
                            .addContact(userId);
                        if (context.mounted) {
                          context.showSuccessSnackBar('Contact added');
                        }
                      },
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Add Contact'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => const Center(child: Text('Failed to load profile')),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'spam',
            'harassment',
            'inappropriate_content',
            'impersonation',
            'other',
          ]
              .map(
                (reason) => ListTile(
                  title: Text(reason.replaceAll('_', ' ').toUpperCase()),
                  onTap: () {
                    Navigator.pop(context);
                    context.showSuccessSnackBar('Report submitted');
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
