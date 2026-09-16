## 0.4.0

* **Breaking behavior change:** `signInWithGoogle` now uses the native
  `google_sign_in` account picker + `supabase.auth.signInWithIdToken`
  instead of the browser-based `signInWithOAuth` flow. This fixes Google's
  consent screen showing the raw Supabase project domain ("to continue to
  `<ref>.supabase.co`") instead of the host app's name — the native picker
  shows the app's own identity instead.
  - Add `AuthRemoteDataSourceImpl({googleWebClientId})`: the "Web
    application" OAuth client ID from Google Cloud Console, required to
    call `signInWithGoogle`. Must be the same Client ID configured for the
    Google provider in the Supabase dashboard.
  - `signInWithGoogle`'s `redirectTo` parameter is now vestigial (kept only
    for signature compatibility with the old flow) — the native picker
    doesn't use a redirect.
  - Host apps also need an **Android**-type OAuth client in Google Cloud
    Console registered with the app's package name and signing certificate
    SHA-1 (one client per signing key — e.g. separate entries for a debug
    keystore and Play App Signing). Its value isn't referenced in code;
    Android matches it automatically at runtime.
  - Removes the deep-link-return/auth-state-polling machinery
    (`_OAuthReturnObserver`, the `Completer`-based wait) that only existed
    to work around the browser flow's async redirect — the native flow
    resolves directly.
* Add `google_sign_in: ^7.2.0` dependency.

## 0.3.1

* Fix Google sign-in falsely reporting cancellation on slow connections. The
  return-from-browser handler now polls for a session for up to 15s (the PKCE
  code exchange is a network round-trip) instead of giving up after a fixed
  1.5s, and succeeds as soon as a session appears.
* Surface real OAuth callback / code-exchange errors: the auth-state stream's
  errors are now propagated with their actual message instead of being masked
  as a cancellation.
* Add debug-only logging of the OAuth round-trip (visible in `flutter logs`).

## 0.3.0

* Add Google sign-in via Supabase OAuth: new `SignInWithGoogle` use case and
  `AuthGoogleSignIn` bloc event, routed through `AuthRepository` /
  `AuthRemoteDataSource` like the other auth operations. The flow only resolves
  (emitting `AuthSuccess`) once the deep-link redirect yields a real session,
  so it drives the same navigation/state path as email/password login.
  The redirect URL is supplied by the host app (`redirectTo`) — no app-specific
  scheme is baked into the package.
* BREAKING: `AuthBloc`'s constructor gains a required `signInWithGoogle`
  parameter.

## 0.2.1

* Add dartdoc comments across the public API (bloc/cubit, events/states,
  domain entities, use cases, repository, and errors).
* Add a runnable `example/` app showing DI wiring and a login screen.
* No API changes.

## 0.2.0

* Add password reset by email via the `SendPasswordResetEmail` use case,
  routed through `AuthRepository` / `AuthRemoteDataSource` like the other
  auth operations. Kept as a use case (not an `AuthBloc` event) so it suits
  a "forgot password" dialog with its own loading state.

## 0.1.0

Initial real release, extracted from and validated against
[multi-role-flutter-auth](https://github.com/ba6ul/multi-role-flutter-auth).

* Supabase-backed email/password auth: sign up, log in, session-restore,
  sign-out, account deletion
* Per-user roles via `UserRole`, configurable table/column names via
  `SupabaseSchema`
* `AuthBloc` + `AppUserCubit` for state management, with optional
  `onLogout` / `onAccountDeleted` host-app hooks
* No UI - screens are expected to stay app-owned
