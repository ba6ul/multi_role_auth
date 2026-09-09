import 'package:fpdart/fpdart.dart';
import '../entities/user_profile.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../repository/auth_repository.dart';

/// Logs in via [AuthRepository.loginWithEmailPassword].
class UserLogin implements UseCase<UserProfile, UserLoginParams> {
  /// The repository this use case delegates to.
  final AuthRepository authRepository;

  /// Creates the use case.
  const UserLogin(this.authRepository);

  @override
  Future<Either<Failure, UserProfile>> call(UserLoginParams params) async {
    return await authRepository.loginWithEmailPassword(
      email: params.email,
      password: params.password,
    );
  }
}

/// Input for [UserLogin].
class UserLoginParams {
  /// Account email address.
  final String email;

  /// Account password.
  final String password;

  /// Creates the params.
  UserLoginParams({required this.email, required this.password});
}
