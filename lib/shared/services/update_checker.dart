import 'package:flutter/material.dart';
import 'package:gapshap/shared/services/update_service.dart';
import 'package:gapshap/shared/widgets/update_dialog.dart';

/// Checks for app updates on app start and provides manual check.
class UpdateChecker {
  /// Check for updates silently at app startup.
  ///
  /// If an update is available, shows the [UpdateDialog].
  /// This should be called after the app is fully loaded (e.g., after splash).
  static Future<void> checkOnStartup(BuildContext context) async {
    try {
      final service = UpdateService();
      final release = await service.checkForUpdate();

      if (release != null && context.mounted) {
        // Show after a short delay so the UI is ready
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            UpdateDialog.show(context, release);
          }
        });
      }
    } catch (e) {
      // Silently fail on startup check — don't interrupt the user
      debugPrint('Startup update check failed: $e');
    }
  }

  /// Manually check for updates (called from Settings or Profile).
  ///
  /// Shows a snackbar if no update is available, or the dialog if one is.
  static Future<void> checkManually(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking for updates...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final service = UpdateService();
      final release = await service.checkForUpdate();

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      if (release != null) {
        UpdateDialog.show(context, release);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are on the latest version! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to check for updates'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
