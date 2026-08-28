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

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _usernameController;
  File? _avatarFile;
  bool _isLoading = false;
  
  

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider).valueOrNull;
    _displayNameController = TextEditingController(text: profile?.displayName ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _usernameController = TextEditingController(text: profile?.username ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
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
    final path = '$userId/avatar.$ext';

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await _uploadAvatar();
      }

      await ref.read(currentProfileProvider.notifier).updateProfile(
            displayName: _displayNameController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            avatarUrl: avatarUrl,
          );

      if (mounted) {
        context.showSuccessSnackBar('Profile updated');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to update profile');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Avatar
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceDark,
                      ),
                      child: _avatarFile != null
                          ? ClipOval(
                              child: Image.file(_avatarFile!, fit: BoxFit.cover),
                            )
                          : profile.valueOrNull?.avatarUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: profile.valueOrNull!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Icon(
                                        Icons.person,
                                        size: 48,
                                        color: AppColors.textSecondaryDark),
                                    errorWidget: (_, __, ___) => const Icon(
                                        Icons.person,
                                        size: 48,
                                        color: AppColors.textSecondaryDark),
                                  ),
                                )
                              : const Icon(Icons.person,
                                  size: 48, color: AppColors.textSecondaryDark),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 18, color: AppColors.textOnPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Display Name
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Display Name',
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(hintText: 'Your display name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your display name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Bio
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Bio', style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tell us about yourself...',
                ),
                validator: (value) {
                  if (value != null && value.length > 200) {
                    return 'Bio must be under 200 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
