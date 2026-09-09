import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_profile.dart';

part 'app_user_state.dart';

/// Holds the currently signed-in [UserProfile] app-wide, independent of the
/// transient [AuthBloc] flow.
///
/// [AuthBloc] handles the *actions* (login, signup, logout) and their loading
/// states; this cubit holds the resulting *identity* so any widget can read
/// "who is logged in" via a `BlocBuilder<AppUserCubit, AppUserState>` without
/// caring whether an auth action is currently in flight.
class AppUserCubit extends Cubit<AppUserState> {
  /// Creates the cubit in the signed-out [AppUserInitial] state.
  AppUserCubit() : super(AppUserInitial());

  /// Sets the current user, or clears it when [user] is `null`.
  ///
  /// Emits [AppUserLoggedIn] with the profile, or [AppUserInitial] when signed
  /// out. Called by [AuthBloc] on successful login/signup and on logout.
  void updateUser(UserProfile? user) {
    if (user == null) {
      emit(AppUserInitial());
    } else {
      emit(AppUserLoggedIn(user));
    }
  }
}
