/// The left side of every `Either` returned by the repository and use cases:
/// a failed operation carrying a human-readable [message].
class Failure {
  /// Human-readable failure reason, suitable for showing to the user.
  final String message;

  /// Creates a failure with an optional [message].
  const Failure([this.message = 'An unexpected error occurred']);
}
