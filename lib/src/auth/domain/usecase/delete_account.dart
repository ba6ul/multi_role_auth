import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../repository/auth_repository.dart';

/// Permanently deletes the current account via
/// [AuthRepository.deleteAccount].
class DeleteAccount implements UseCase<void, NoParams> {
  /// The repository this use case delegates to.
  final AuthRepository authRepository;

  /// Creates the use case.
  DeleteAccount(this.authRepository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await authRepository.deleteAccount();
  }
}
