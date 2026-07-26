/// Custom exception hierarchy for the AI Treasure Hunt app.
///
/// Every exception carries a user-friendly [message] plus an optional
/// [code] and [cause] to aid logging and debugging. Repositories/services
/// should translate low-level errors (FirebaseAuthException, DioException,
/// PlatformException, etc.) into these types so the presentation layer only
/// ever deals with a single, predictable error surface.
abstract class AppException implements Exception {
  const AppException(
    this.message, {
    this.code,
    this.cause,
    this.stackTrace,
  });

  /// Human-readable message safe to show to the user.
  final String message;

  /// Optional machine-readable error code (e.g. 'invalid-email').
  final String? code;

  /// The original error that triggered this exception, if any.
  final Object? cause;

  /// Stack trace captured when the exception was created/rethrown.
  final StackTrace? stackTrace;

  String get prefix => 'AppException';

  @override
  String toString() {
    final buffer = StringBuffer('$prefix: $message');
    if (code != null) buffer.write(' (code: $code)');
    if (cause != null) buffer.write('\nCaused by: $cause');
    return buffer.toString();
  }
}

/// Thrown when a network request fails or the device is offline.
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });

  factory NetworkException.offline() => const NetworkException(
        'No internet connection. Please check your network and try again.',
        code: 'offline',
      );

  factory NetworkException.timeout() => const NetworkException(
        'The request timed out. Please try again.',
        code: 'timeout',
      );

  @override
  String get prefix => 'NetworkException';
}

/// Thrown when the server responds with an error status code.
class ServerException extends AppException {
  const ServerException(
    super.message, {
    this.statusCode,
    super.code,
    super.cause,
    super.stackTrace,
  });

  final int? statusCode;

  @override
  String get prefix => 'ServerException';

  @override
  String toString() {
    final base = super.toString();
    return statusCode != null ? '$base [status: $statusCode]' : base;
  }
}

/// Thrown for authentication / authorization failures.
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });

  /// Maps a FirebaseAuth error code to a friendly [AuthException].
  factory AuthException.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return const AuthException('The email address is badly formatted.',
            code: 'invalid-email');
      case 'user-disabled':
        return const AuthException('This account has been disabled.',
            code: 'user-disabled');
      case 'user-not-found':
        return const AuthException('No account found for this email.',
            code: 'user-not-found');
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException('Incorrect email or password.',
            code: 'invalid-credential');
      case 'email-already-in-use':
        return const AuthException('An account already exists for this email.',
            code: 'email-already-in-use');
      case 'weak-password':
        return const AuthException('The password is too weak.',
            code: 'weak-password');
      case 'operation-not-allowed':
        return const AuthException('This sign-in method is not enabled.',
            code: 'operation-not-allowed');
      case 'too-many-requests':
        return const AuthException(
            'Too many attempts. Please try again later.',
            code: 'too-many-requests');
      case 'network-request-failed':
        return const AuthException(
            'Network error. Please check your connection.',
            code: 'network-request-failed');
      case 'requires-recent-login':
        return const AuthException(
            'Please sign in again to complete this action.',
            code: 'requires-recent-login');
      default:
        return AuthException('Authentication failed. Please try again.',
            code: code);
    }
  }

  @override
  String get prefix => 'AuthException';
}

/// Thrown when input validation fails.
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.cause,
    super.stackTrace,
  });

  /// Optional map of field name -> error message.
  final Map<String, String>? fieldErrors;

  @override
  String get prefix => 'ValidationException';
}

/// Thrown for local cache / database (Hive, SharedPreferences) failures.
class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });

  @override
  String get prefix => 'CacheException';
}

/// Thrown when a requested resource does not exist.
class NotFoundException extends AppException {
  const NotFoundException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });

  @override
  String get prefix => 'NotFoundException';
}

/// Thrown when location services or permissions are unavailable.
class LocationException extends AppException {
  const LocationException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });

  factory LocationException.serviceDisabled() => const LocationException(
        'Location services are disabled. Please enable them to continue.',
        code: 'service-disabled',
      );

  factory LocationException.permissionDenied() => const LocationException(
        'Location permission denied. Please grant access to play.',
        code: 'permission-denied',
      );

  factory LocationException.permissionDeniedForever() =>
      const LocationException(
        'Location permission permanently denied. Enable it from settings.',
        code: 'permission-denied-forever',
      );

  @override
  String get prefix => 'LocationException';
}

/// Thrown when a camera / media capture operation fails.
class MediaException extends AppException {
  const MediaException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });

  @override
  String get prefix => 'MediaException';
}

/// Thrown when a permission (camera, storage, notifications) is denied.
class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });

  @override
  String get prefix => 'PermissionException';
}

/// Thrown for errors originating from the Gemini AI service.
class AIServiceException extends AppException {
  const AIServiceException(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });

  factory AIServiceException.quotaExceeded() => const AIServiceException(
        'AI request limit reached. Please try again later.',
        code: 'quota-exceeded',
      );

  factory AIServiceException.emptyResponse() => const AIServiceException(
        'The AI did not return a response. Please try again.',
        code: 'empty-response',
      );

  @override
  String get prefix => 'AIServiceException';
}

/// Fallback for unexpected, unclassified errors.
class UnknownException extends AppException {
  const UnknownException([
    String message = 'Something went wrong. Please try again.',
    Object? cause,
    StackTrace? stackTrace,
  ]) : super(message, code: 'unknown', cause: cause, stackTrace: stackTrace);

  @override
  String get prefix => 'UnknownException';
}
