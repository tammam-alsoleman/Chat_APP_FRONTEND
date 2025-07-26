/// A base class for all failure types that can be handled and displayed by the UI.
/// A failure represents a predictable, user-facing error state.
abstract class Failure {
  final String message;
  const Failure(this.message);
}

/// Represents a failure originating from the server.
class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

/// Represents a failure originating from network connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

/// Represents a failure related to user authentication.
class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message);
}