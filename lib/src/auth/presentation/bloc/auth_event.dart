part of 'auth_bloc.dart';

/// Base type for events handled by [AuthBloc].
@immutable
sealed class AuthEvent {}

/// Registers a new account with email/password and the given [role].
final class AuthSignup extends AuthEvent {
  /// Display/username chosen at signup.
  final String username;

  /// Account email address.
  final String email;

  /// Account password.
  final String password;

  /// Role assigned to the new user.
  final UserRole role;

  /// Creates a signup event.
  AuthSignup({
    required this.username,
    required this.email,
    required this.password,
    required this.role,
  });
}

/// Logs in with email/password.
final class AuthLogin extends AuthEvent {
  /// Account email address.
  final String email;

  /// Account password.
  final String password;

  /// Creates a login event.
  AuthLogin({required this.email, required this.password});
}

/// Signs in with Google via OAuth. The resulting [AuthState] mirrors the
/// email/password flow — [AuthLoading] then [AuthSuccess]/[AuthFailure] — and
/// is only emitted once the deep-link redirect yields a real Supabase session.
final class AuthGoogleSignIn extends AuthEvent {
  /// The host app's deep-link callback URL for the OAuth redirect. Leave
  /// `null` to use Supabase's default (web).
  final String? redirectTo;

  /// Creates a Google sign-in event.
  AuthGoogleSignIn({this.redirectTo});
}

/// Restores the session on app launch, if a signed-in user exists.
final class AuthIsUserLoggedIn extends AuthEvent {}

/// Signs the current user out.
final class AuthLogout extends AuthEvent {}

/// Permanently deletes the current user's account.
final class AuthDeleteAccount extends AuthEvent {}
