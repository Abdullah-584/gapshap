import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../providers/contacts_provider.dart';

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  ConsumerState<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _search(query);
      } else {
        setState(() {
          _results = [];
          _hasSearched = false;
        });
      }
    });
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    try {
      final results =
          await ref.read(contactsProvider.notifier).searchUsers(query);
      setState(() {
        _results = results;
        _isLoading = false;
        _hasSearched = true;
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
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search by username or name...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 16,
            ),
          ),
          style: const TextStyle(fontSize: 16),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            if (value.isNotEmpty) _search(value);
          },
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _results.isEmpty && _hasSearched
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 64,
                          color: AppColors.textSecondaryDark
                              .withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No users found',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    return ListTile(
                      onTap: () =>
                          context.push('/user/${user.id}'),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      title: Text(user.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('@${user.username}',
                          style: const TextStyle(
                              color: AppColors.textSecondaryDark)),
                    );
                  },
                ),
    );
  }
}
