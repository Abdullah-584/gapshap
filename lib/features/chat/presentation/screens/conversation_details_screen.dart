import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/chat_provider.dart';

class ConversationDetailsScreen extends ConsumerWidget {
  final String conversationId;
  const ConversationDetailsScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(conversationDetailsProvider(conversationId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Chat Info'),
      ),
      body: details.when(
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Conversation not found'));
          }

          final members = data['members'] as List? ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceDark,
                  ),
                  child: data['avatar_url'] != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: data['avatar_url'],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Icon(Icons.group,
                                size: 48, color: AppColors.textSecondaryDark),
                            errorWidget: (_, __, ___) => const Icon(Icons.group,
                                size: 48, color: AppColors.textSecondaryDark),
                          ),
                        )
                      : const Icon(Icons.group,
                          size: 48, color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 16),
                Text(
                  data['name'] ?? 'Chat',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${members.length} members',
                  style: const TextStyle(
                      color: AppColors.textSecondaryDark, fontSize: 14),
                ),
                const SizedBox(height: 24),
                const Divider(),
                // Members list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 20, color: AppColors.textSecondaryDark),
                      const SizedBox(width: 12),
                      Text('Members',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...members.map((member) {
                  final user = member['user'] as Map<String, dynamic>?;
                  
                  final isAdmin = member['role'] == 'admin';

                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceDark,
                      ),
                      child: user?['avatar_url'] != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user!['avatar_url'],
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Icon(Icons.person,
                                    color: AppColors.textSecondaryDark),
                                errorWidget: (_, __, ___) => const Icon(
                                    Icons.person,
                                    color: AppColors.textSecondaryDark),
                              ),
                            )
                          : const Icon(Icons.person,
                              color: AppColors.textSecondaryDark),
                    ),
                    title: Text(
                      user?['display_name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      isAdmin ? 'Admin' : 'Member',
                      style: const TextStyle(
                          color: AppColors.textSecondaryDark, fontSize: 12),
                    ),
                    trailing: user?['is_online'] == true
                        ? const Icon(Icons.circle,
                            size: 8, color: AppColors.online)
                        : null,
                  );
                }),
                const Divider(),
                const SizedBox(height: 8),
                // Leave group
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: AppColors.error),
                  title: const Text('Leave Group',
                      style: TextStyle(color: AppColors.error)),
                  onTap: () => _showLeaveDialog(context, ref),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => const Center(child: Text('Failed to load details')),
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Leave', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
