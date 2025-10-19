import 'failures.dart';

/// A union type that represents either a successful value of type [T] or an error.
sealed class Result<T> {
  const Result();

  /// Creates a successful result containing [data].
  const factory Result.success(T data) = Success<T>;

  /// Creates an error result containing [failure].
  const factory Result.error(Failure failure) = Error<T>;

  /// Whether this result represents a success.
  bool get isSuccess => this is Success<T>;

  /// Whether this result represents an error.
  bool get isError => this is Error<T>;

  /// Returns the success value if this is a success, null otherwise.
  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;

  /// Returns the error if this is an error, null otherwise.
  Failure? get failureOrNull =>
      this is Error<T> ? (this as Error<T>).failure : null;

  /// Returns the success value if available, otherwise returns [defaultValue].
  T getOrElse(T Function() defaultValue) =>
      this is Success<T> ? (this as Success<T>).data : defaultValue();

  /// Pattern matches on the success and error cases.
  R fold<R>(R Function(T data) onSuccess, R Function(Failure failure) onError) {
    return switch (this) {
      Success(data: final d) => onSuccess(d),
      Error(failure: final f) => onError(f),
    };
  }
}

/// Represents a successful result containing [data].
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

/// Represents an error result containing [failure].
final class Error<T> extends Result<T> {
  const Error(this.failure);

  final Failure failure;
}
