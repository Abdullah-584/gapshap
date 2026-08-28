import 'package:flutter/material.dart';
import 'package:gapshap/core/theme/app_colors.dart';
import 'package:gapshap/core/theme/app_typography.dart';
import 'package:gapshap/shared/services/update_service.dart';

/// Shows a dialog when a new version is available from GitHub Releases.
class UpdateDialog extends StatefulWidget {
  final GitHubRelease release;

  const UpdateDialog({super.key, required this.release});

  /// Convenience method to show the dialog.
  static Future<void> show(BuildContext context, GitHubRelease release) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(release: release),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  double _progress = 0.0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Update icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Update Available',
              style: AppTypography.darkHeadlineMedium,
            ),
            const SizedBox(height: 8),

            // Version info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.release.versionLabel,
                style: AppTypography.darkLabelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Size
            Text(
              widget.release.sizeLabel,
              style: AppTypography.darkBodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),

            // Release notes
            if (widget.release.releaseNotes.isNotEmpty) ...[
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 150),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.release.releaseNotes,
                    style: AppTypography.darkBodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Error message
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: AppTypography.darkBodySmall.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Progress or buttons
            if (_downloading) ...[
              // Download progress
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: AppColors.backgroundLight,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: AppTypography.darkBodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Later',
                        style: AppTypography.darkTitleMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _downloadAndInstall,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Update',
                        style: AppTypography.darkTitleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAndInstall() async {
    setState(() {
      _downloading = true;
      _progress = 0.0;
      _error = null;
    });

    try {
      final service = UpdateService();

      // Download
      final file = await service.downloadApk(
        widget.release.apkDownloadUrl,
        widget.release.apkFileName,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );

      // Install
      if (mounted) {
        await service.installApk(file.path);
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = 'Download failed. Please check your connection and try again.';
        });
      }
    }
  }
}
