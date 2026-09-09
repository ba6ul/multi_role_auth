import 'package:fpdart/fpdart.dart';
import '../entities/user_profile.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../repository/auth_repository.dart';

/// Signs in with Google via [AuthRepository.signInWithGoogle].
class SignInWithGoogle implements UseCase<UserProfile, SignInWithGoogleParams> {
  /// The repository this use case delegates to.
  final AuthRepository authRepository;

  /// Creates the use case.
  const SignInWithGoogle(this.authRepository);

  @override
  Future<Either<Failure, UserProfile>> call(
    SignInWithGoogleParams params,
  ) async {
    return await authRepository.signInWithGoogle(
      redirectTo: params.redirectTo,
      timeout: params.timeout,
    );
  }
}

/// Input for [SignInWithGoogle].
class SignInWithGoogleParams {
  /// Deep-link callback URL the OAuth redirect returns to. Must be registered
  /// as a platform deep link and allow-listed in Supabase. Pass `null` to use
  /// Supabase's default (web).
  final String? redirectTo;

  /// How long to wait for the browser round-trip before failing.
  final Duration timeout;

  /// Creates the params.
  const SignInWithGoogleParams({
    this.redirectTo,
    this.timeout = const Duration(minutes: 3),
  });
}
