import 'package:fpdart/fpdart.dart';
import '../entities/user_profile.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../repository/auth_repository.dart';
import '../user_role.dart';

/// Registers a new account via [AuthRepository.signUpWithEmailPassword].
class UserSignUp implements UseCase<UserProfile, UserSignUpParams> {
  /// The repository this use case delegates to.
  final AuthRepository authRepository;

  /// Creates the use case.
  const UserSignUp(this.authRepository);

  @override
  Future<Either<Failure, UserProfile>> call(UserSignUpParams params) async {
    return await authRepository.signUpWithEmailPassword(
      username: params.username,
      email: params.email,
      password: params.password,
      role: params.role,
    );
  }
}

/// Input for [UserSignUp].
class UserSignUpParams {
  /// Account email address.
  final String email;

  /// Account password.
  final String password;

  /// Username chosen at signup.
  final String username;

  /// Role assigned to the new user.
  final UserRole role;

  /// Creates the params.
  UserSignUpParams({
    required this.email,
    required this.password,
    required this.username,
    required this.role,
  });
}
