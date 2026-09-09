part of 'auth_bloc.dart';

/// Base type for states emitted by [AuthBloc].
@immutable
sealed class AuthState {}

/// Idle / signed-out state.
class AuthInitial extends AuthState {}

/// An auth action is in progress.
class AuthLoading extends AuthState {}

/// An auth action succeeded; [user] is the resulting profile.
class AuthSuccess extends AuthState {
  /// The signed-in user's profile.
  final UserProfile user;

  /// Creates a success state for [user].
  AuthSuccess(this.user);
}

/// An auth action failed; [message] is a human-readable reason.
class AuthFailure extends AuthState {
  /// Human-readable failure reason, suitable for showing to the user.
  final String message;

  /// Creates a failure state with [message].
  AuthFailure(this.message);
}
