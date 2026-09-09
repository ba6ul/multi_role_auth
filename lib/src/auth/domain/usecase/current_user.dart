import 'package:fpdart/fpdart.dart';
import '../entities/user_profile.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../repository/auth_repository.dart';

/// Fetches the currently signed-in user via [AuthRepository.currentUser].
class CurrentUser implements UseCase<UserProfile, NoParams> {
  /// The repository this use case delegates to.
  final AuthRepository authRepository;

  /// Creates the use case.
  CurrentUser(this.authRepository);

  @override
  Future<Either<Failure, UserProfile>> call(NoParams params) async {
    return await authRepository.currentUser();
  }
}
