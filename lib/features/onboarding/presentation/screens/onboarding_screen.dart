import '../../../../core/extensions/context_extensions.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  File? _avatarFile;
  

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
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

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
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

      final url =
          client.storage.from(AppConfig.avatarsBucket).getPublicUrl(path);
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> _checkUsername(String username) async {
    if (username.length < 3) {
      setState(() => _isUsernameAvailable = null);
      return;
    }

    setState(() => _isCheckingUsername = true);

    try {
      final available =
          await ref.read(currentProfileProvider.notifier).isUsernameAvailable(
                username,
              );
      if (mounted) {
        setState(() => _isUsernameAvailable = available);
      }
    } catch (_) {
      if (mounted) setState(() => _isUsernameAvailable = null);
    } finally {
      if (mounted) setState(() => _isCheckingUsername = false);
    }
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await _uploadAvatar();
      }

      await ref.read(currentProfileProvider.notifier).createProfile(
            username: _usernameController.text.trim(),
            displayName: _displayNameController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            avatarUrl: avatarUrl,
          );

      if (mounted) {
        context.go('/chats');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),

                Text(
                  'Set up your profile',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ).animate().fadeIn(),
                const SizedBox(height: 8),
                Text(
                  'Choose a username and avatar',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 40),

                // Avatar
                GestureDetector(
                  onTap: () => _showAvatarPicker(),
                  child: Stack(
                    children: [
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
                          image: _avatarFile != null
                              ? DecorationImage(
                                  image: FileImage(_avatarFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _avatarFile == null
                            ? const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: AppColors.textSecondaryDark,
                              )
                            : null,
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
                          child: const Icon(
                            Icons.edit,
                            size: 18,
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(),

                const SizedBox(height: 40),

                // Username
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Username',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    // Debounced check would go here
                    _checkUsername(value.trim());
                  },
                  decoration: InputDecoration(
                    hintText: 'Choose a username',
                    prefixIcon: const Icon(Icons.alternate_email),
                    suffixIcon: _isCheckingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _isUsernameAvailable == true
                            ? const Icon(Icons.check_circle, color: AppColors.success)
                            : _isUsernameAvailable == false
                                ? const Icon(Icons.cancel, color: AppColors.error)
                                : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Only letters, numbers, and underscores';
                    }
                    if (_isUsernameAvailable == false) {
                      return 'Username is already taken';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // Display Name
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Display Name',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _displayNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Your display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your display name';
                    }
                    if (value.length > 50) {
                      return 'Display name is too long';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // Bio
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Bio (optional)',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Tell us about yourself...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.info_outline),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.length > 200) {
                      return 'Bio must be under 200 characters';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                const SizedBox(height: 40),

                // Complete button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _complete,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : const Text('Complete Setup'),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),

                TextButton(
                  onPressed: () => context.go('/chats'),
                  child: const Text('Skip for now'),
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
