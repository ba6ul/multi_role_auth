Reusable multi-role auth logic for Flutter apps, backed by Supabase.

Ships the bloc/cubit, domain entities/usecases, and repository for
email/password auth with per-user roles, session-restore, sign-out, and
account deletion. It deliberately has **no UI** — login/signup/profile
screens stay app-owned, since they're expected to look completely
different per app. This package covers the part that shouldn't need
rewriting each time: talking to Supabase and managing auth state.

## Features

- Sign up / log in with email and password
- Per-user roles via a `UserRole` enum, backed by a `user_profiles` table
- Session-restore on app launch (`AuthIsUserLoggedIn`)
- Sign-out and account deletion, each with an optional host-app hook
  (`onLogout` / `onAccountDeleted`) for clearing local data the package
  doesn't know about
- Password reset by email (`SendPasswordResetEmail`) — a use case rather
  than a bloc event, so it fits a "forgot password" dialog with its own
  loading state without flipping the global auth state
- Configurable table/column names via `SupabaseSchema`, so it isn't tied
  to one project's exact schema

## Getting started

Requires a Supabase project with a `user_profiles` table. See the demo
app at [multi-role-flutter-auth](https://github.com/ba6ul/multi-role-flutter-auth)
(specifically its `schema.sql` and `SUPABASE_SETUP.md`) for the schema
this was built against.

## Usage

Register the pieces with your DI container of choice ([get_it](https://pub.dev/packages/get_it)
in the example below), then provide `AuthBloc` and `AppUserCubit` to
your widget tree:

```dart
final serviceLocator = GetIt.instance;

void initAuth(SupabaseClient client) {
  serviceLocator.registerLazySingleton(() => AppUserCubit());

  serviceLocator.registerFactory<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client),
  );

  serviceLocator.registerFactory<AuthRepository>(
    () => AuthRepositoryImpl(serviceLocator()),
  );

  serviceLocator
    ..registerFactory(() => UserSignUp(serviceLocator()))
    ..registerFactory(() => UserLogin(serviceLocator()))
    ..registerFactory(() => CurrentUser(serviceLocator()))
    ..registerFactory(() => UserSignOut(serviceLocator()))
    ..registerFactory(() => DeleteAccount(serviceLocator()))
    ..registerFactory(() => SendPasswordResetEmail(serviceLocator()));

  serviceLocator.registerLazySingleton(
    () => AuthBloc(
      userSignUp: serviceLocator(),
      userLogin: serviceLocator(),
      currentUser: serviceLocator(),
      userSignOut: serviceLocator(),
      deleteAccount: serviceLocator(),
      appUserCubit: serviceLocator(),
      // Optional - clear local app data on sign-out/deletion. The
      // package doesn't know what this data is, so it's opt-in.
      onLogout: () async { /* ... */ },
      onAccountDeleted: () async { /* ... */ },
    ),
  );
}
```

Then dispatch events from your own screens:

```dart
context.read<AuthBloc>().add(AuthLogin(email: email, password: password));
context.read<AuthBloc>().add(AuthSignup(username: username, email: email, password: password, role: UserRole.member));
context.read<AuthBloc>().add(AuthIsUserLoggedIn());
context.read<AuthBloc>().add(AuthLogout());
context.read<AuthBloc>().add(AuthDeleteAccount());
```

and react to `AuthState` (`AuthInitial`, `AuthLoading`, `AuthSuccess(user)`,
`AuthFailure(message)`) with your own `BlocListener`/`BlocConsumer`.

Password reset is a use case you call directly (so a "forgot password"
dialog keeps its own loading state instead of triggering `AuthLoading`):

```dart
final result = await serviceLocator<SendPasswordResetEmail>()(email);
result.fold(
  (failure) => showError(failure.message),
  (_) => showInfo('Password reset email sent'),
);
```

Account deletion also needs a `delete-account` Supabase Edge Function
deployed on your project (deleting an `auth.users` row requires the
service role, which the client never has) — see
[ba6ul/multi-role-flutter-auth#34](https://github.com/ba6ul/multi-role-flutter-auth/issues/34).

## Additional information

Issues and feature requests: [github.com/ba6ul/flutter_auth_kit/issues](https://github.com/ba6ul/flutter_auth_kit/issues).
