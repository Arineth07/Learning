class ConnectivityFailure extends Failure {
  const ConnectivityFailure(super.message, {super.cause, super.stackTrace});
}

/// Represents data conflicts during sync (HTTP 409)
class ConflictFailure extends Failure {
  const ConflictFailure(super.message, {super.cause, super.stackTrace});
}

/// Represents authentication/authorization failures (HTTP 401/403)
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, {super.cause, super.stackTrace});
}

/// Represents server-side failures (HTTP 5xx)
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.cause, super.stackTrace});
}

/// Represents rate-limiting errors (HTTP 429)
class RateLimitFailure extends Failure {
  const RateLimitFailure(super.message, {super.cause, super.stackTrace});
}

/// Base class for all domain-specific failures.
sealed class Failure {
  const Failure(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (cause != null) buffer.write('\nCause: $cause');
    if (stackTrace != null) buffer.write('\nStack trace:\n$stackTrace');
    return buffer.toString();
  }
}

/// Represents general database operation failures.
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.cause, super.stackTrace});
}

/// Represents when an entity is not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.cause, super.stackTrace});
}

/// Represents when an entity already exists (duplicate key/conflict).
class AlreadyExistsFailure extends Failure {
  const AlreadyExistsFailure(super.message, {super.cause, super.stackTrace});
}

/// Represents data corruption errors.
class CorruptionFailure extends Failure {
  const CorruptionFailure(super.message, {super.cause, super.stackTrace});
}

/// Represents JSON/Hive serialization errors.
class SerializationFailure extends Failure {
  const SerializationFailure(super.message, {super.cause, super.stackTrace});
}

/// Represents file system permission errors.
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.cause, super.stackTrace});
}

/// Represents operation timeout errors.
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message, {super.cause, super.stackTrace});
}

/// Represents data validation errors.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause, super.stackTrace});
}

/// Represents unexpected errors not covered by other failure types.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.cause, super.stackTrace});
}
