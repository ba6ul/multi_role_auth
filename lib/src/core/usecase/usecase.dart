import 'package:fpdart/fpdart.dart';
import '../error/failures.dart';

/// A single application action, callable like a function.
///
/// Implementations take [Params] and return `Either<Failure, SuccessType>`.
/// Use [NoParams] for actions that take no input.
abstract interface class UseCase<SuccessType, Params> {
  /// Runs the use case with [params].
  Future<Either<Failure, SuccessType>> call(Params params);
}

/// Placeholder params for use cases that take no input.
class NoParams {}
