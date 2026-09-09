import 'package:flutter_test/flutter_test.dart';
import 'package:multi_role_auth/src/auth/data/datasource/auth_remote_data_source.dart';
import 'package:multi_role_auth/src/auth/data/repositories/auth_repository_impl.dart';
import 'package:multi_role_auth/src/core/error/network_exceptions.dart';

/// Minimal hand-written fake — the package has no mock framework, and the
/// reset path only touches [AuthRemoteDataSource.sendPasswordResetEmail], so
/// everything else is left to [noSuchMethod]. [throwThis], when set, is what
/// the reset call throws, to exercise the repository's error mapping.
class _FakeRemoteDataSource implements AuthRemoteDataSource {
  _FakeRemoteDataSource({this.throwThis});
  final Object? throwThis;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (throwThis != null) throw throwThis!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('AuthRepositoryImpl.sendPasswordResetEmail', () {
    test('returns Right(null) when the data source succeeds', () async {
      final repo = AuthRepositoryImpl(_FakeRemoteDataSource());

      final result = await repo.sendPasswordResetEmail('user@example.com');

      expect(result.isRight(), isTrue);
    });

    test('maps a ServerException to Left(Failure) with its message', () async {
      final repo = AuthRepositoryImpl(
        _FakeRemoteDataSource(throwThis: const ServerException('reset failed')),
      );

      final result = await repo.sendPasswordResetEmail('user@example.com');

      expect(result.isLeft(), isTrue);
      final message = result.fold((failure) => failure.message, (_) => null);
      expect(message, 'reset failed');
    });
  });
}
