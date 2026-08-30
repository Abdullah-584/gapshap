import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';

/// Full-screen image viewer
class MediaViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;
  final bool isLocal;

  const MediaViewerScreen({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo View
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity!.abs() > 200) {
                Navigator.of(context).pop();
              }
            },
            child: PhotoViewGallery.builder(
              itemCount: 1,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: isLocal
                      ? FileImage(File(imageUrl))
                      : CachedNetworkImageProvider(imageUrl),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  heroAttributes: heroTag != null
                      ? PhotoViewHeroAttributes(tag: heroTag!)
                      : null,
                );
              },
              backgroundDecoration:
                  const BoxDecoration(color: Colors.black),
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => _shareImage(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () => _downloadImage(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareImage() {
    SharePlus.instance.share(ShareParams(text: imageUrl));
  }

  void _downloadImage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saving image...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // In production, download the image to the device gallery
  }
}

/// Attachment preview for chat messages
class AttachmentPreview extends StatelessWidget {
  final String? url;
  final String? thumbnailUrl;
  final String? name;
  final String? mimeType;
  final int? size;
  final double? duration;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const AttachmentPreview({
    super.key,
    this.url,
    this.thumbnailUrl,
    this.name,
    this.mimeType,
    this.size,
    this.duration,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null) return const SizedBox.shrink();

    final isImage = mimeType?.startsWith('image') == true;
    final isVideo = mimeType?.startsWith('video') == true;
    final isAudio = mimeType?.startsWith('audio') == true;

    if (isImage) {
      return _buildImagePreview(context);
    } else if (isVideo) {
      return _buildVideoPreview(context);
    } else if (isAudio) {
      return _buildAudioPreview();
    } else {
      return _buildFilePreview();
    }
  }

  Widget _buildImagePreview(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MediaViewerScreen(imageUrl: url!),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: thumbnailUrl ?? url!,
          width: width ?? 220,
          height: height ?? 160,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(
            width: width ?? 220,
            height: height ?? 160,
            color: AppColors.surfaceDark,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
          errorWidget: (_, _, _) => Container(
            width: width ?? 220,
            height: height ?? 160,
            color: AppColors.surfaceDark,
            child: const Icon(Icons.broken_image, color: AppColors.textSecondaryDark),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: thumbnailUrl ?? url!,
              width: width ?? 220,
              height: height ?? 160,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                width: width ?? 220,
                height: height ?? 160,
                color: AppColors.surfaceDark,
              ),
              errorWidget: (_, _, _) => Container(
                width: width ?? 220,
                height: height ?? 160,
                color: AppColors.surfaceDark,
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.6),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
            ),
            if (duration != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(duration!),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPreview() {
    return Container(
      width: width ?? 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: const Icon(Icons.mic, color: AppColors.textOnPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform placeholder
                Row(
                  children: List.generate(20, (i) {
                    return Container(
                      width: 2,
                      height: (4 + (i % 3) * 3).toDouble(),
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondaryDark,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
                if (duration != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(duration!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    final icon = _getFileIcon(mimeType);

    return Container(
      width: width ?? 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'File',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (size != null)
                  Text(
                    _formatFileSize(size!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) return Icons.description;
    if (mimeType.contains('sheet') || mimeType.contains('excel')) return Icons.table_chart;
    if (mimeType.contains('presentation')) return Icons.slideshow;
    if (mimeType.contains('zip') || mimeType.contains('archive')) return Icons.archive;
    return Icons.insert_drive_file;
  }

  String _formatDuration(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
