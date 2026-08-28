import '../../../../core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  late String _onlineStatusVisibility;
  late String _lastSeenVisibility;
  late String _profilePhotoVisibility;
  late bool _readReceiptsEnabled;
  late bool _typingIndicatorEnabled;
  late String _storyVisibility;
  late String _messagePermission;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider).valueOrNull;
    _onlineStatusVisibility = profile?.onlineStatusVisibility ?? 'everyone';
    _lastSeenVisibility = profile?.lastSeenVisibility ?? 'everyone';
    _profilePhotoVisibility = profile?.profilePhotoVisibility ?? 'everyone';
    _readReceiptsEnabled = profile?.readReceiptsEnabled ?? true;
    _typingIndicatorEnabled = profile?.typingIndicatorEnabled ?? true;
    _storyVisibility = profile?.storyVisibility ?? 'everyone';
    _messagePermission = profile?.messagePermission ?? 'everyone';
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(currentProfileProvider.notifier).updatePrivacySettings(
            onlineStatusVisibility: _onlineStatusVisibility,
            lastSeenVisibility: _lastSeenVisibility,
            profilePhotoVisibility: _profilePhotoVisibility,
            readReceiptsEnabled: _readReceiptsEnabled,
            typingIndicatorEnabled: _typingIndicatorEnabled,
            storyVisibility: _storyVisibility,
            messagePermission: _messagePermission,
          );

      if (mounted) {
        context.showSuccessSnackBar('Privacy settings updated');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to update settings');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Privacy'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Who can see your...'),
          const SizedBox(height: 8),

          _DropdownTile(
            title: 'Online Status',
            value: _onlineStatusVisibility,
            onChanged: (v) => setState(() => _onlineStatusVisibility = v!),
          ),
          _DropdownTile(
            title: 'Last Seen',
            value: _lastSeenVisibility,
            onChanged: (v) => setState(() => _lastSeenVisibility = v!),
          ),
          _DropdownTile(
            title: 'Profile Photo',
            value: _profilePhotoVisibility,
            onChanged: (v) => setState(() => _profilePhotoVisibility = v!),
          ),

          const SizedBox(height: 24),
          _SectionTitle('Messaging'),
          const SizedBox(height: 8),

          _SwitchTile(
            title: 'Read Receipts',
            subtitle: 'Let others know when you\'ve read their messages',
            value: _readReceiptsEnabled,
            onChanged: (v) => setState(() => _readReceiptsEnabled = v),
          ),
          _SwitchTile(
            title: 'Typing Indicator',
            subtitle: 'Show when you\'re typing',
            value: _typingIndicatorEnabled,
            onChanged: (v) => setState(() => _typingIndicatorEnabled = v),
          ),
          _DropdownTile(
            title: 'Who can message you',
            value: _messagePermission,
            onChanged: (v) => setState(() => _messagePermission = v!),
          ),

          const SizedBox(height: 24),
          _SectionTitle('Stories'),
          const SizedBox(height: 8),

          _DropdownTile(
            title: 'Who can see your stories',
            value: _storyVisibility,
            onChanged: (v) => setState(() => _storyVisibility = v!),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final String title;
  final String value;
  final ValueChanged<String?> onChanged;

  const _DropdownTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      contentPadding: EdgeInsets.zero,
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: AppColors.surfaceDark,
        style: const TextStyle(color: AppColors.textPrimaryDark),
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'everyone', child: Text('Everyone')),
          DropdownMenuItem(value: 'contacts', child: Text('Contacts')),
          DropdownMenuItem(value: 'nobody', child: Text('Nobody')),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondaryDark)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}
