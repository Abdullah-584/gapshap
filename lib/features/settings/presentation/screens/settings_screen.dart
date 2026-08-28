import '../../../../core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/services/update_checker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Account
          _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Account',
            subtitle: 'Manage your account',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Security',
            subtitle: 'Change password, 2FA',
            onTap: () => _showChangePasswordDialog(context, ref),
          ),
          const SizedBox(height: 16),

          // Privacy
          _SectionHeader(title: 'Privacy'),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
            subtitle: 'Who can see your info',
            onTap: () => context.push(RouteNames.privacySettings),
          ),
          _SettingsTile(
            icon: Icons.block,
            title: 'Blocked Users',
            subtitle: 'Manage blocked users',
            onTap: () => context.push(RouteNames.blockedUsers),
          ),
          const SizedBox(height: 16),

          // Notifications
          _SectionHeader(title: 'Notifications'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Push notification settings',
            onTap: () {},
          ),
          const SizedBox(height: 16),

          // Appearance
          _SectionHeader(title: 'Appearance'),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Appearance',
            subtitle: 'Dark mode',
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Data & Storage
          _SectionHeader(title: 'Data & Storage'),
          _SettingsTile(
            icon: Icons.storage_outlined,
            title: 'Data & Storage',
            subtitle: 'Manage storage, auto-download',
            onTap: () {},
          ),
          const SizedBox(height: 16),

          // Help
          _SectionHeader(title: 'Help'),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help',
            subtitle: 'FAQ, contact support',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.system_update_outlined,
            title: 'Check for Updates',
            subtitle: 'See if a new version is available',
            onTap: () => UpdateChecker.checkManually(context),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version 1.0.0',
            onTap: () {},
          ),
          const SizedBox(height: 32),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context, ref),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Logout',
                  style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Delete Account
          TextButton(
            onPressed: () => _showDeleteAccountDialog(context, ref),
            child: const Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'New password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.length >= 8) {
                await ref
                    .read(currentProfileProvider.notifier)
                    .updatePassword(controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  context.showSuccessSnackBar('Password updated');
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(currentProfileProvider.notifier).signOut();
            },
            child:
                const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(currentProfileProvider.notifier).deleteAccount();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondaryDark)),
      trailing: trailing ??
          const Icon(Icons.arrow_forward_ios,
              size: 14, color: AppColors.textSecondaryDark),
    );
  }
}
