import '../../../../core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';

import '../providers/chat_provider.dart';

class ForwardMessageScreen extends ConsumerStatefulWidget {
  final String messageId;
  final String content;
  const ForwardMessageScreen({
    super.key,
    required this.messageId,
    required this.content,
  });

  @override
  ConsumerState<ForwardMessageScreen> createState() =>
      _ForwardMessageScreenState();
}

class _ForwardMessageScreenState extends ConsumerState<ForwardMessageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsProvider.notifier).loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Forward to...'),
      ),
      body: Column(
        children: [
          // Preview of message being forwarded
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.forward,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Conversations list
          Expanded(
            child: conversations.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text('No conversations to forward to',
                        style: TextStyle(color: AppColors.textSecondaryDark)),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final convo = list[index];
                    final name = convo.type.name == 'group'
                        ? (convo.name ?? 'Group')
                        : (convo.otherDisplayName ??
                            convo.otherUsername ??
                            'Unknown');
                    final avatar = convo.type.name == 'group'
                        ? convo.avatarUrl
                        : convo.otherAvatarUrl;

                    return ListTile(
                      onTap: () => _forwardTo(convo.id, name),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceDark,
                        ),
                        child: avatar != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: avatar,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => const Icon(
                                      Icons.person,
                                      color: AppColors.textSecondaryDark),
                                  errorWidget: (_, _, _) => const Icon(
                                      Icons.person,
                                      color: AppColors.textSecondaryDark),
                                ),
                              )
                            : const Icon(Icons.person,
                                color: AppColors.textSecondaryDark),
                      ),
                      title: Text(name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  },
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) =>
                  const Center(child: Text('Failed to load conversations')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _forwardTo(String conversationId, String name) async {
    try {
      // Get the messages notifier for the target conversation
      final notifier = ref.read(messagesProvider(conversationId).notifier);
      await notifier.forwardMessage(content: widget.content);

      if (mounted) {
        context.showSuccessSnackBar('Message forwarded to $name');
        context.go('/chat/$conversationId');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to forward: $e');
      }
    }
  }
}
