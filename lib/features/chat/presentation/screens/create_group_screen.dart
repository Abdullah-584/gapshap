import '../../../../core/extensions/context_extensions.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../contacts/presentation/providers/contacts_provider.dart';
import '../providers/chat_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final Set<String> _selectedMemberIds = {};
  File? _avatarFile;
  bool _isLoading = false;
  List<dynamic> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadContacts() async {
    final contacts = ref.read(contactsProvider).valueOrNull ?? [];
    setState(() => _contacts = contacts);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _avatarFile = File(image.path));
    }
  }

  Future<String?> _uploadAvatar() async {
    if (_avatarFile == null) return null;
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final ext = _avatarFile!.path.split('.').last;
    final path = '$userId/groups/${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await client.storage.from(AppConfig.avatarsBucket).upload(
            path,
            _avatarFile!,
            fileOptions: const FileOptions(upsert: true),
          );
      return client.storage.from(AppConfig.avatarsBucket).getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      context.showErrorSnackBar('Please enter a group name');
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      context.showErrorSnackBar('Please select at least one member');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await _uploadAvatar();
      }

      final conversationId = await ref
          .read(conversationsProvider.notifier)
          .createGroupConversation(
            name: _nameController.text.trim(),
            memberIds: _selectedMemberIds.toList(),
            avatarUrl: avatarUrl,
          );

      if (mounted) {
        context.go('/chat/$conversationId');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to create group');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = _searchController.text.isEmpty
        ? _contacts
        : _contacts.where((c) {
            final query = _searchController.text.toLowerCase();
            return (c.displayName?.toLowerCase().contains(query) ?? false) ||
                (c.username?.toLowerCase().contains(query) ?? false);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('New Group'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroup,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Create (${_selectedMemberIds.length})',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Group info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceDark,
                        ),
                        child: _avatarFile != null
                            ? ClipOval(
                                child: Image.file(_avatarFile!,
                                    fit: BoxFit.cover))
                            : const Icon(Icons.group,
                                color: AppColors.textSecondaryDark, size: 28),
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
                          child: const Icon(Icons.camera_alt,
                              size: 12, color: AppColors.textOnPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Group name',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondaryDark),
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Selected members
          if (_selectedMemberIds.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedMemberIds.length,
                itemBuilder: (context, index) {
                  final memberId = _selectedMemberIds.elementAt(index);
                  final member = _contacts.firstWhere(
                    (c) => c.id == memberId,
                    orElse: () => null,
                  );
                  if (member == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceDark,
                              ),
                              child: member.avatarUrl != null
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: member.avatarUrl,
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
                            Positioned(
                              top: -2,
                              right: -2,
                              child: GestureDetector(
                                onTap: () {
                                  setState(
                                      () => _selectedMemberIds.remove(memberId));
                                },
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.error,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.displayName?.split(' ').first ?? '',
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Contacts list
          Expanded(
            child: filteredContacts.isEmpty
                ? const Center(
                    child: Text('No contacts found',
                        style: TextStyle(color: AppColors.textSecondaryDark)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      final isSelected =
                          _selectedMemberIds.contains(contact.id);

                      return ListTile(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedMemberIds.remove(contact.id);
                            } else {
                              _selectedMemberIds.add(contact.id);
                            }
                          });
                        },
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceDark,
                          ),
                          child: contact.avatarUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: contact.avatarUrl,
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
                        title: Text(contact.displayName ?? 'Unknown'),
                        subtitle: Text('@${contact.username ?? ''}',
                            style: const TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontSize: 13)),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color:
                              isSelected ? AppColors.primary : AppColors.textSecondaryDark,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
