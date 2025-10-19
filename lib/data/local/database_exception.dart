/// Custom exception for database-related errors.
class DatabaseException implements Exception {
  final String message;

  const DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
