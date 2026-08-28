import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

/// Service to check GitHub Releases for app updates and download APKs.
class UpdateService {
  /// GitHub API endpoint for releases.
  /// Format: https://api.github.com/repos/{owner}/{repo}/releases/latest
  static const String _releasesUrl =
      'https://api.github.com/repos/Abdullah-584/gapshap/releases/latest';

  final Dio _dio = Dio();

  /// Check if a newer version is available on GitHub Releases.
  ///
  /// Returns a [GitHubRelease] if an update is available, null otherwise.
  Future<GitHubRelease?> checkForUpdate() async {
    try {
      final response = await _dio.get(
        _releasesUrl,
        options: Options(
          headers: {
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'GAPSHAP-Android',
          },
        ),
      );

      if (response.statusCode != 200) return null;

      final data = response.data as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final body = data['body'] as String? ?? '';

      // Extract version code from tag (e.g., "v1.0.1+2" → name="1.0.1", buildNumber="2")
      final versionInfo = _parseVersion(tagName);
      if (versionInfo == null) return null;

      final currentInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(currentInfo.buildNumber) ?? 0;

      // Compare: if remote buildNumber > local buildNumber → update available
      final remoteBuildNumber = versionInfo.buildNumber;
      if (remoteBuildNumber <= currentBuildNumber) return null;

      // Find APK asset
      final assets = data['assets'] as List<dynamic>? ?? [];
      String? apkDownloadUrl;
      String? apkFileName;
      int? apkSize;

      for (final asset in assets) {
        final assetMap = asset as Map<String, dynamic>;
        final name = assetMap['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkDownloadUrl = assetMap['browser_download_url'] as String?;
          apkFileName = name;
          apkSize = assetMap['size'] as int?;
          break;
        }
      }

      if (apkDownloadUrl == null) return null;

      return GitHubRelease(
        versionName: versionInfo.versionName,
        buildNumber: remoteBuildNumber,
        releaseNotes: body,
        apkDownloadUrl: apkDownloadUrl,
        apkFileName: apkFileName ?? 'gapshap.apk',
        apkSize: apkSize ?? 0,
      );
    } catch (e) {
      debugPrint('Update check failed: $e');
      return null;
    }
  }

  /// Download the APK to local storage and return the file path.
  ///
  /// Returns a stream of download progress (0.0 to 1.0).
  Future<File> downloadApk(
    String downloadUrl,
    String fileName, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);

    // Skip download if already exists
    if (await file.exists()) {
      onProgress?.call(1.0);
      return file;
    }

    await _dio.download(
      downloadUrl,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress?.call(received / total);
        }
      },
    );

    return File(filePath);
  }

  /// Open the APK file to trigger Android package installer.
  Future<void> installApk(String filePath) async {
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      debugPrint('Failed to open APK: ${result.message}');
    }
  }

  /// Parse version string like "v1.0.1+2" or "1.0.1+2".
  _ParsedVersion? _parseVersion(String tag) {
    // Remove leading 'v' if present
    final cleaned = tag.startsWith('v') ? tag.substring(1) : tag;

    final parts = cleaned.split('+');
    if (parts.length != 2) return null;

    final versionName = parts[0];
    final buildNumber = int.tryParse(parts[1]);
    if (buildNumber == null) return null;

    return _ParsedVersion(versionName: versionName, buildNumber: buildNumber);
  }

  /// Format file size for display.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Represents a parsed GitHub release.
class GitHubRelease {
  final String versionName;
  final int buildNumber;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String apkFileName;
  final int apkSize;

  const GitHubRelease({
    required this.versionName,
    required this.buildNumber,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.apkFileName,
    required this.apkSize,
  });

  String get versionLabel => 'v$versionName+$buildNumber';
  String get sizeLabel => UpdateService.formatFileSize(apkSize);
}

class _ParsedVersion {
  final String versionName;
  final int buildNumber;

  const _ParsedVersion({required this.versionName, required this.buildNumber});
}
