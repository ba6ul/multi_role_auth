import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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

  /// Launches the Google OAuth flow and resolves once the resulting Supabase
  /// session arrives back via the deep-link redirect.
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

  /// Creates the data source over [supabaseClient].
  AuthRemoteDataSourceImpl(this.supabaseClient);

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
    // `signInWithOAuth` only *launches* the external browser; the session
    // itself arrives asynchronously once the redirect deep-links back into the
    // app and supabase_flutter exchanges the OAuth code for a session (a
    // network round-trip), then emits a `signedIn` event. So we resolve the
    // profile only when a real session exists — never on launch alone.
    final completer = Completer<Session>();

    void completeWith(Session session) {
      if (!completer.isCompleted) completer.complete(session);
    }

    void failWith(Object error) {
      if (!completer.isCompleted) completer.completeError(error);
    }

    final authSub = supabaseClient.auth.onAuthStateChange.listen(
      (data) {
        _oauthLog('authState=${data.event} hasSession=${data.session != null}');
        if (data.event == AuthChangeEvent.signedIn && data.session != null) {
          completeWith(data.session!);
        }
      },
      // A callback URL carrying an OAuth error, or a failed code exchange,
      // surfaces here — propagate its real message instead of masking it as a
      // cancellation.
      onError: (Object e) {
        _oauthLog('authState error: $e');
        failWith(ServerException(e.toString()));
      },
    );

    // Distinguishing a real cancellation from a slow success: the browser tab
    // launches over the app (a lifecycle pause), and closing it — whether by a
    // successful redirect or by the user backing out — returns here (resumed).
    // These can't be told apart synchronously, so after the return we poll for
    // a session for a generous window (the code exchange can be slow on a poor
    // connection) and only report "not completed" if none ever appears. This
    // replaces a fixed short grace that could fire before a genuine (but slow)
    // session had a chance to land.
    final returnObserver = _OAuthReturnObserver(
      isSettled: () => completer.isCompleted,
      currentSession: () => supabaseClient.auth.currentSession,
      onSession: completeWith,
      onNoSession: () => failWith(
        const ServerException(
          'Google sign-in did not complete — no session was returned. '
          'Please try again.',
        ),
      ),
    );
    WidgetsBinding.instance.addObserver(returnObserver);

    try {
      final launched = await supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );
      _oauthLog('signInWithOAuth launched=$launched redirectTo=$redirectTo');
      if (!launched) {
        throw const ServerException('Could not open Google sign-in.');
      }
      final session = await completer.future.timeout(
        timeout,
        onTimeout: () =>
            throw const ServerException('Google sign-in timed out.'),
      );
      _oauthLog('session acquired for user ${session.user.id}');
      return await _fetchProfile(session.user);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    } finally {
      await authSub.cancel();
      WidgetsBinding.instance.removeObserver(returnObserver);
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

/// Debug-only trace of the Google OAuth round-trip, visible in `flutter logs`.
/// Silent in release; no-op unless running in debug mode.
void _oauthLog(String message) {
  if (kDebugMode) debugPrint('[multi_role_auth] Google OAuth: $message');
}

/// Watches the app lifecycle across an OAuth round-trip to tell a real
/// cancellation apart from a slow-but-genuine sign-in.
///
/// The provider's browser tab launches over the app (a pause); closing it —
/// by a successful redirect or by backing out — returns to the foreground
/// (resume). Since a genuine redirect still needs a network code-exchange
/// before a session exists, we don't judge on resume alone: we poll for a
/// session for a generous window, calling [onSession] the moment one appears
/// and [onNoSession] only if the whole window elapses empty. Nothing here
/// fires if the sign-in already settled ([isSettled]) via the auth stream.
class _OAuthReturnObserver with WidgetsBindingObserver {
  _OAuthReturnObserver({
    required this.isSettled,
    required this.currentSession,
    required this.onSession,
    required this.onNoSession,
  });

  /// Whether the sign-in already produced a result (success or error).
  final bool Function() isSettled;

  /// The current Supabase session, if the code exchange has completed.
  final Session? Function() currentSession;

  /// Called with the session once one materializes after the return.
  final void Function(Session session) onSession;

  /// Called when the return yields no session within the polling window.
  final VoidCallback onNoSession;

  /// The browser only shows after the app has actually left the foreground, so
  /// we ignore resumes until we've seen the launch-time pause, and handle only
  /// the first return.
  bool _sawPause = false;
  bool _handledReturn = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _sawPause = true;
    } else if (state == AppLifecycleState.resumed &&
        _sawPause &&
        !_handledReturn) {
      _handledReturn = true;
      _watchForSession();
    }
  }

  Future<void> _watchForSession() async {
    const interval = Duration(milliseconds: 400);
    const maxWait = Duration(seconds: 15);
    final deadline = DateTime.now().add(maxWait);
    _oauthLog('returned to foreground — waiting for session…');
    while (DateTime.now().isBefore(deadline)) {
      if (isSettled()) return;
      final session = currentSession();
      if (session != null) {
        _oauthLog('session present on return');
        onSession(session);
        return;
      }
      await Future<void>.delayed(interval);
    }
    if (!isSettled()) {
      _oauthLog(
        'no session after ${maxWait.inSeconds}s — reporting incomplete',
      );
      onNoSession();
    }
  }
}
