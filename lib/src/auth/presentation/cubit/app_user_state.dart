part of 'app_user_cubit.dart';

/// Base type for [AppUserCubit] states.
@immutable
sealed class AppUserState {}

/// No user is signed in.
final class AppUserInitial extends AppUserState {}

/// A user is signed in; [user] is their current profile.
final class AppUserLoggedIn extends AppUserState {
  /// The signed-in user's profile.
  final UserProfile user;

  /// Creates the state for the signed-in [user].
  AppUserLoggedIn(this.user);
}
