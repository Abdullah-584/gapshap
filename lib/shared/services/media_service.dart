import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';

/// Upload progress callback
typedef UploadProgress = void Function(double progress);

/// Media service provider
final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService();
});

/// Media upload result
class MediaUploadResult {
  final String url;
  final String path;
  final String? thumbnailUrl;
  final int fileSize;
  final String mimeType;

  const MediaUploadResult({
    required this.url,
    required this.path,
    this.thumbnailUrl,
    required this.fileSize,
    required this.mimeType,
  });
}

/// Media service for file operations
class MediaService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Validate file before upload
  void validateFile(File file, {int? maxSizeBytes, List<String>? allowedMimeTypes}) {
    if (!file.existsSync()) {
      throw AppException.invalidFile('File does not exist');
    }

    final fileSize = file.lengthSync();
    final maxBytes = maxSizeBytes ?? AppConfig.maxFileSizeMB * 1024 * 1024;
    if (fileSize > maxBytes) {
      throw AppException.fileTooLarge(maxBytes ~/ (1024 * 1024));
    }

    if (allowedMimeTypes != null && allowedMimeTypes.isNotEmpty) {
      final mimeType = lookupMimeType(file.path);
      if (mimeType == null || !allowedMimeTypes.contains(mimeType)) {
        throw AppException.invalidFile('File type not allowed');
      }
    }
  }

  /// Compress image
  Future<File> compressImage(File file, {int quality = 80, int? maxWidth, int? maxHeight}) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw AppException.invalidFile('Could not decode image');
    }

    // Resize if needed
    if (maxWidth != null && image.width > maxWidth) {
      image = img.copyResize(image, width: maxWidth);
    }
    if (maxHeight != null && image.height > maxHeight) {
      image = img.copyResize(image, height: maxHeight);
    }

    // Compress
    final compressedBytes = img.encodeJpg(image, quality: quality);

    // Write to temp file
    final tempDir = Directory.systemTemp;
    final ext = path.extension(file.path);
    final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}$ext');
    await tempFile.writeAsBytes(compressedBytes);

    return tempFile;
  }

  /// Upload image to Supabase Storage
  Future<MediaUploadResult> uploadImage(
    File file, {
    String bucket = AppConfig.chatMediaBucket,
    String? conversationId,
    UploadProgress? onProgress,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AppException.unauthorized();

    // Validate
    validateFile(
      file,
      maxSizeBytes: AppConfig.maxImageSizeMB * 1024 * 1024,
      allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
    );

    // Compress
    final compressed = await compressImage(file, quality: 80, maxWidth: 1920);

    // Generate path
    final ext = path.extension(compressed.path).replaceAll('.', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/${conversationId ?? "misc"}/$timestamp.$ext';

    // Upload
    try {
      await _client.storage.from(bucket).upload(
            storagePath,
            compressed,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$ext',
            ),
          );

      final url = _client.storage.from(bucket).getPublicUrl(storagePath);
      final mimeType = lookupMimeType(compressed.path) ?? 'image/$ext';

      return MediaUploadResult(
        url: url,
        path: storagePath,
        fileSize: compressed.lengthSync(),
        mimeType: mimeType,
      );
    } catch (e) {
      throw AppException.uploadFailed('Failed to upload image');
    }
  }

  /// Upload file to Supabase Storage
  Future<MediaUploadResult> uploadFile(
    File file, {
    String bucket = AppConfig.documentsBucket,
    String? conversationId,
    UploadProgress? onProgress,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AppException.unauthorized();

    // Validate
    validateFile(file, maxSizeBytes: AppConfig.maxFileSizeMB * 1024 * 1024);

    // Generate path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = path.basename(file.path);
    final storagePath = '$userId/${conversationId ?? "misc"}/$timestamp-$fileName';

    try {
      await _client.storage.from(bucket).upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: lookupMimeType(file.path),
            ),
          );

      final url = _client.storage.from(bucket).getPublicUrl(storagePath);
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      return MediaUploadResult(
        url: url,
        path: storagePath,
        fileSize: file.lengthSync(),
        mimeType: mimeType,
      );
    } catch (e) {
      throw AppException.uploadFailed('Failed to upload file');
    }
  }

  /// Upload voice message
  Future<MediaUploadResult> uploadVoiceMessage(
    File file, {
    String? conversationId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw AppException.unauthorized();

    validateFile(
      file,
      maxSizeBytes: AppConfig.maxImageSizeMB * 1024 * 1024, // 10MB for voice
      allowedMimeTypes: ['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/aac'],
    );

    final ext = path.extension(file.path).replaceAll('.', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/${conversationId ?? "misc"}/voice_$timestamp.$ext';

    try {
      await _client.storage.from(AppConfig.voiceMessagesBucket).upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'audio/$ext',
            ),
          );

      final url = _client.storage
          .from(AppConfig.voiceMessagesBucket)
          .getPublicUrl(storagePath);
      final mimeType = lookupMimeType(file.path) ?? 'audio/$ext';

      return MediaUploadResult(
        url: url,
        path: storagePath,
        fileSize: file.lengthSync(),
        mimeType: mimeType,
      );
    } catch (e) {
      throw AppException.uploadFailed('Failed to upload voice message');
    }
  }

  /// Delete file from storage
  Future<void> deleteFile(String bucket, String filePath) async {
    try {
      await _client.storage.from(bucket).remove([filePath]);
    } catch (_) {
      // Silent fail - cleanup is best effort
    }
  }

  /// Get signed URL for private files
  Future<String> getSignedUrl(String bucket, String filePath, {Duration expiry = const Duration(hours: 1)}) async {
    try {
      return await _client.storage.from(bucket).createSignedUrl(
            filePath,
            expiry.inSeconds,
          );
    } catch (e) {
      throw AppException.storage('Failed to get signed URL');
    }
  }
}
