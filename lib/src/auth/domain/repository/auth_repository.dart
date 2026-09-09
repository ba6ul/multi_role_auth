import 'package:fpdart/fpdart.dart';
import '../entities/user_profile.dart';
import '../../../core/error/failures.dart';
import '../user_role.dart';

/// Contract for the auth backend, returning `Either<Failure, T>` so callers
/// handle errors without exceptions.
///
/// The package ships an implementation backed by Supabase
/// (`AuthRepositoryImpl`); the use cases depend on this interface, not the
/// implementation.
abstract interface class AuthRepository {
  /// Registers a new account and returns the resulting profile.
  Future<Either<Failure, UserProfile>> signUpWithEmailPassword({
    required String username,
    required String email,
    required String password,
    required UserRole role,
  });

  /// Logs in with email/password and returns the resulting profile.
  Future<Either<Failure, UserProfile>> loginWithEmailPassword({
    required String email,
    required String password,
  });

  /// Launches the Google OAuth flow and returns the resulting profile once the
  /// redirect completes and a Supabase session is established.
  ///
  /// [redirectTo] is the host app's deep-link callback URL (e.g.
  /// `com.example.app://login-callback`); it must also be allow-listed in the
  /// Supabase project's URL configuration. Pass `null` to use Supabase's
  /// default (web). [timeout] bounds how long to wait for the browser
  /// round-trip before failing.
  Future<Either<Failure, UserProfile>> signInWithGoogle({
    String? redirectTo,
    Duration timeout = const Duration(minutes: 3),
  });

  /// Returns the currently signed-in user's profile, or a [Failure] if none.
  Future<Either<Failure, UserProfile>> currentUser();

  /// Signs the current user out.
  Future<Either<Failure, void>> signOut();

  /// Permanently deletes the current user's account.
  Future<Either<Failure, void>> deleteAccount();

  /// Sends a password-reset email to [email].
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
}
