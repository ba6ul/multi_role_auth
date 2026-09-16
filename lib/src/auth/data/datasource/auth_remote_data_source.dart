import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../config/supabase_schema.dart';
import '../../../core/error/network_exceptions.dart';
import '../model/user_model.dart';
import '../../domain/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Low-level Supabase operations used by `AuthRepositoryImpl`.
///
/// Works in [UserModel]s (the data-layer type) and throws [NetworkException]
/// on failure; the repository translates these into domain entities and
/// [Failure]s. Most host apps depend on the repository/use cases rather than
/// this directly.
abstract interface class AuthRemoteDataSource {
  Session? get currentUserSession;

  Future<UserModel> signUpWithEmailPassword({
    required String username,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  });

  /// Signs in with the native Google account picker (via `google_sign_in`)
  /// and exchanges the resulting ID token for a Supabase session.
  ///
  /// [redirectTo] is vestigial — kept for signature compatibility with the
  /// old browser-based OAuth flow — and is ignored by the native flow.
  Future<UserModel> signInWithGoogle({
    String? redirectTo,
    Duration timeout = const Duration(minutes: 3),
  });

  Future<UserModel?> getCurrentUserData();
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<void> sendPasswordResetEmail(String email);
}

/// Supabase-backed implementation of [AuthRemoteDataSource].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  /// The Supabase client all calls go through.
  final SupabaseClient supabaseClient;

  /// The "Web application" OAuth client ID from Google Cloud Console — used
  /// as `serverClientId` so the ID token `google_sign_in` returns has an
  /// audience Supabase can verify. Must match the Client ID configured for
  /// the Google provider in the Supabase dashboard. Required to call
  /// [signInWithGoogle]; other methods work without it.
  final String? googleWebClientId;

  bool _googleSignInInitialized = false;

  /// Creates the data source over [supabaseClient].
  AuthRemoteDataSourceImpl(this.supabaseClient, {this.googleWebClientId});

  @override
  Session? get currentUserSession => supabaseClient.auth.currentSession;

  @override
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        password: password,
        email: email,
      );
      if (response.user == null) {
        throw const ServerException('User is null!');
      }
      return _fetchProfile(response.user!);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String username,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final response = await supabaseClient.auth.signUp(
        password: password,
        email: email,
        data: {'username': username, SupabaseSchema.roleColumn: role.dbValue},
      );
      if (response.user == null) {
        throw const ServerException('User is null!');
      }
      if (response.session == null) {
        // Email confirmation is required and pending - the account exists
        // but there's no session yet, so this is not actually a successful
        // login. Surface this distinctly instead of faking success.
        throw const ServerException(
          'Account created! Check your email to confirm your account before logging in.',
        );
      }
      // No user_profiles row exists yet at signup time (that's created by
      // ProfileSetupPage) — the role picked just now lives in auth metadata.
      return UserModel.fromAuthUser(response.user!);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle({
    String? redirectTo,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final webClientId = googleWebClientId;
    if (webClientId == null) {
      throw const ServerException(
        'Google sign-in is not configured: no web client ID was provided.',
      );
    }
    try {
      if (!_googleSignInInitialized) {
        await GoogleSignIn.instance.initialize(serverClientId: webClientId);
        _googleSignInInitialized = true;
      }
      // The native account picker replaces the whole browser round-trip —
      // it returns the signed-in account (or throws/cancels) directly, no
      // deep-link redirect or auth-state polling needed.
      final googleUser = await GoogleSignIn.instance.authenticate().timeout(
        timeout,
        onTimeout: () =>
            throw const ServerException('Google sign-in timed out.'),
      );
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const ServerException(
          'Google sign-in did not return an ID token.',
        );
      }
      final response = await supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      if (response.user == null) {
        throw const ServerException('User is null!');
      }
      _oauthLog('session acquired for user ${response.user!.id}');
      return await _fetchProfile(response.user!);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const ServerException('Google sign-in was canceled.');
      }
      throw ServerException(e.description ?? e.code.toString());
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    try {
      final session = currentUserSession;
      if (session == null) {
        return null;
      }
      return await _fetchProfile(session.user);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final userId = currentUserSession?.user.id;
      if (userId == null) {
        throw const ServerException('User is null!');
      }
      // Deleting the auth.users row needs the service role, which the
      // client never has - the Edge Function does that server-side.
      final response = await supabaseClient.functions.invoke(
        SupabaseSchema.deleteAccountFunction,
      );
      if (response.status != 200) {
        throw ServerException('Failed to delete account (${response.status}).');
      }
      // Best-effort: schema.sql's user_profiles.user_id has ON DELETE
      // CASCADE, so this is normally already gone. Only matters for a
      // host project whose schema doesn't cascade - swallow errors since
      // the account itself is already deleted at this point either way.
      try {
        await supabaseClient
            .from(SupabaseSchema.userProfilesTable)
            .delete()
            .eq(SupabaseSchema.userIdColumn, userId);
      } catch (_) {}
      await supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// The authoritative role/profile data lives in [SupabaseSchema.userProfilesTable],
  /// updated by ProfileSetupPage — not in auth metadata, which is only set
  /// once at signup and never updated afterward. Falls back to auth metadata
  /// if no profile row exists yet (e.g. user signed up but skipped/hasn't
  /// reached profile setup).
  Future<UserModel> _fetchProfile(User authUser) async {
    final rows = await supabaseClient
        .from(SupabaseSchema.userProfilesTable)
        .select()
        .eq(SupabaseSchema.userIdColumn, authUser.id);

    if (rows.isEmpty) {
      return UserModel.fromAuthUser(authUser);
    }
    return UserModel.fromProfileRow(rows.first).copyWith(email: authUser.email);
  }
}

/// Debug-only trace of the Google sign-in round-trip, visible in `flutter logs`.
/// Silent in release; no-op unless running in debug mode.
void _oauthLog(String message) {
  if (kDebugMode) debugPrint('[multi_role_auth] Google sign-in: $message');
}
