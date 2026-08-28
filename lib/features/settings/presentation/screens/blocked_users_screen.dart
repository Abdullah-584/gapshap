import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../contacts/presentation/providers/contacts_provider.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  List<dynamic> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    try {
      final users =
          await ref.read(contactsProvider.notifier).getBlockedUsers();
      setState(() {
        _blockedUsers = users;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Blocked Users'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64,
                          color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text('No blocked users',
                          style: TextStyle(color: AppColors.textSecondaryDark)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _blockedUsers.length,
                  itemBuilder: (context, index) {
                    final user = _blockedUsers[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceDark,
                        ),
                        child: user.avatarUrl != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: user.avatarUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Icon(
                                      Icons.person,
                                      color: AppColors.textSecondaryDark),
                                  errorWidget: (_, __, ___) => const Icon(
                                      Icons.person,
                                      color: AppColors.textSecondaryDark),
                                ),
                              )
                            : const Icon(Icons.person,
                                color: AppColors.textSecondaryDark),
                      ),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}',
                          style: const TextStyle(
                              color: AppColors.textSecondaryDark)),
                      trailing: TextButton(
                        onPressed: () async {
                          await ref
                              .read(contactsProvider.notifier)
                              .unblockUser(user.id);
                          _loadBlockedUsers();
                        },
                        child: const Text('Unblock',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    );
                  },
                ),
    );
  }
}
