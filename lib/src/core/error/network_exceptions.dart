// core/error/network_exceptions.dart
// ----------------------------------
// Generic, backend-agnostic network/server exceptions. Nothing here should
// name a specific provider (Supabase, REST, etc.) - provider-specific error
// handling belongs in that feature's own data layer.

/// Base class for backend-agnostic network/server errors thrown by the data
/// layer. The repository maps these to [Failure] values.
abstract class NetworkException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Creates the exception with [message].
  const NetworkException(this.message);

  @override
  String toString() => message;
}

/// No internet connection is available.
class NoConnectionException extends NetworkException {
  /// Creates the exception.
  const NoConnectionException() : super('No Internet connection available.');
}

/// The request exceeded its time budget.
class RequestTimeoutException extends NetworkException {
  /// Creates the exception.
  const RequestTimeoutException()
    : super('Request timed out. Please try again.');
}

/// The server responded with an error; [message] describes it.
class ServerException extends NetworkException {
  /// Creates the exception with an optional [message].
  const ServerException([super.message = 'Server responded with an error.']);
}

/// An unclassified network error.
class UnknownNetworkException extends NetworkException {
  /// Creates the exception with an optional [message].
  const UnknownNetworkException([
    super.message = 'An unknown network error occurred.',
  ]);
}
