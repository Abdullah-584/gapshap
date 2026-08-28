import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';

import '../providers/contacts_provider.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contactsProvider.notifier).loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Contacts',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ).animate().fadeIn(),

            // Search
            Padding(
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
                        'Search users...',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Contacts list
            Expanded(
              child: contacts.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64,
                              color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No contacts yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppColors.textSecondaryDark),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Search for users to add',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondaryDark),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final contact = list[index];
                      return _ContactTile(contact: contact);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      const Text('Failed to load contacts'),
                      TextButton(
                        onPressed: () => ref
                            .read(contactsProvider.notifier)
                            .loadContacts(),
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

class _ContactTile extends StatelessWidget {
  final dynamic contact;
  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push('/user/${contact.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Stack(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceDark,
            ),
            child: contact.avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: contact.avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Icon(Icons.person,
                          color: AppColors.textSecondaryDark),
                      errorWidget: (_, __, ___) => const Icon(Icons.person,
                          color: AppColors.textSecondaryDark),
                    ),
                  )
                : const Icon(Icons.person, color: AppColors.textSecondaryDark),
          ),
          if (contact.isOnline == true)
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
        contact.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        '@${contact.username}',
        style: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 13,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.chat_bubble_outline, size: 20),
        onPressed: () async {
          // Start or open chat with this contact
          // This would use the conversations provider
        },
        color: AppColors.primary,
      ),
    );
  }
}
