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
