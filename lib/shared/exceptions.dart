/// Base class for all custom exceptions in the application.
/// An exception represents a technical, unexpected error.
class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

/// Thrown for server-related errors (e.g., status codes 5xx, 404, etc.).
class ServerException extends AppException {
  ServerException(String message) : super(message);
}

/// Thrown for authentication-specific errors (e.g., status code 401 Unauthorized, 403 Forbidden).
class AuthException extends AppException {
  AuthException(String message) : super(message);
}

/// Thrown for client-side validation errors returned by the server (e.g., status code 400).
class BadFormatException extends AppException {
  BadFormatException(String message) : super(message);
}

/// Thrown when there's a device network issue, like no internet connection.
class NetworkException extends AppException {
  NetworkException(String message) : super(message);
}