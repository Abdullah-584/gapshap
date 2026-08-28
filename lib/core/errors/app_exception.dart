/// Centralized app exceptions
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';

  factory AppException.network() => const AppException(
        message: 'No internet connection. Please check your network.',
        code: 'NETWORK_ERROR',
      );

  factory AppException.timeout() => const AppException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
      );

  factory AppException.unauthorized() => const AppException(
        message: 'Your session has expired. Please log in again.',
        code: 'UNAUTHORIZED',
      );

  factory AppException.forbidden() => const AppException(
        message: 'You do not have permission to perform this action.',
        code: 'FORBIDDEN',
      );

  factory AppException.notFound([String? resource]) => AppException(
        message: resource != null
            ? '$resource not found.'
            : 'The requested resource was not found.',
        code: 'NOT_FOUND',
      );

  factory AppException.conflict([String? detail]) => AppException(
        message: detail ?? 'This action conflicts with existing data.',
        code: 'CONFLICT',
      );

  factory AppException.server([String? detail]) => AppException(
        message: detail ?? 'A server error occurred. Please try again later.',
        code: 'SERVER_ERROR',
      );

  factory AppException.storage([String? detail]) => AppException(
        message: detail ?? 'Failed to save or retrieve data.',
        code: 'STORAGE_ERROR',
      );

  factory AppException.fileTooLarge([int? maxSizeMB]) => AppException(
        message:
            'File is too large. Maximum size is ${maxSizeMB ?? 50}MB.',
        code: 'FILE_TOO_LARGE',
      );

  factory AppException.invalidFile([String? detail]) => AppException(
        message: detail ?? 'Invalid file format.',
        code: 'INVALID_FILE',
      );

  factory AppException.permissionDenied() => const AppException(
        message: 'Permission denied. Please grant the required permissions.',
        code: 'PERMISSION_DENIED',
      );

  factory AppException.realtimeDisconnect() => const AppException(
        message: 'Connection lost. Attempting to reconnect...',
        code: 'REALTIME_DISCONNECT',
      );

  factory AppException.uploadFailed([String? detail]) => AppException(
        message: detail ?? 'Upload failed. Please try again.',
        code: 'UPLOAD_FAILED',
      );

  factory AppException.auth(String detail) => AppException(
        message: detail,
        code: 'AUTH_ERROR',
      );

  factory AppException.unknown([dynamic error]) => AppException(
        message: 'An unexpected error occurred. Please try again.',
        code: 'UNKNOWN_ERROR',
        originalError: error,
      );
}
