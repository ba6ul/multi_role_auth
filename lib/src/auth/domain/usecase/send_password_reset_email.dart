import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../repository/auth_repository.dart';

/// Sends a password-reset email to the given address (the [String] param).
///
/// Deliberately a use case rather than an [AuthBloc] event: reset is usually
/// triggered from a small "forgot password" dialog with its own local loading
/// state, so it shouldn't flip the global auth state to `AuthLoading` (which a
/// host app typically maps to a full-screen loader). Call it directly and fold
/// the result: `right(null)` on success, `left(Failure)` with a message on
/// failure.
class SendPasswordResetEmail implements UseCase<void, String> {
  final AuthRepository authRepository;
  const SendPasswordResetEmail(this.authRepository);

  @override
  Future<Either<Failure, void>> call(String email) async {
    return await authRepository.sendPasswordResetEmail(email);
  }
}
