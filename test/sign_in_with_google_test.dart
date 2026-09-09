import 'package:flutter_test/flutter_test.dart';
import 'package:multi_role_auth/src/auth/data/datasource/auth_remote_data_source.dart';
import 'package:multi_role_auth/src/auth/data/model/user_model.dart';
import 'package:multi_role_auth/src/auth/data/repositories/auth_repository_impl.dart';
import 'package:multi_role_auth/src/auth/domain/user_role.dart';
import 'package:multi_role_auth/src/core/error/network_exceptions.dart';

/// Minimal hand-written fake — mirrors the reset-email test. Only
/// [AuthRemoteDataSource.signInWithGoogle] is exercised here; everything else
/// falls through to [noSuchMethod]. The live OAuth round-trip itself (browser
/// launch + deep-link redirect) needs a real Supabase client, so this covers
/// the repository's success/error mapping, not the transport.
class _FakeRemoteDataSource implements AuthRemoteDataSource {
  _FakeRemoteDataSource({this.result, this.throwThis});
  final UserModel? result;
  final Object? throwThis;

  @override
  Future<UserModel> signInWithGoogle({
    String? redirectTo,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    if (throwThis != null) throw throwThis!;
    return result!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('AuthRepositoryImpl.signInWithGoogle', () {
    test('returns Right(profile) when the data source succeeds', () async {
      final user = UserModel(
        id: 'id-1',
        email: 'user@example.com',
        name: 'User',
        username: 'user',
        role: UserRole.member,
      );
      final repo = AuthRepositoryImpl(_FakeRemoteDataSource(result: user));

      final result = await repo.signInWithGoogle(
        redirectTo: 'com.example.app://login-callback',
      );

      expect(result.isRight(), isTrue);
      final email = result.fold((_) => null, (u) => u.email);
      expect(email, 'user@example.com');
    });

    test('maps a ServerException to Left(Failure) with its message', () async {
      final repo = AuthRepositoryImpl(
        _FakeRemoteDataSource(
          throwThis: const ServerException('Google sign-in was cancelled.'),
        ),
      );

      final result = await repo.signInWithGoogle();

      expect(result.isLeft(), isTrue);
      final message = result.fold((failure) => failure.message, (_) => null);
      expect(message, 'Google sign-in was cancelled.');
    });
  });
}
