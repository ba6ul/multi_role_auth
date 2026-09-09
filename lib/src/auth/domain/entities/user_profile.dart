import '../user_role.dart';

/// A signed-in user's profile, as surfaced to the host app.
///
/// This is the domain entity exposed throughout the package (via [AuthState],
/// [AppUserState], and the use cases). Data-layer types extend it internally.
class UserProfile {
  /// Supabase auth user id.
  final String id;

  /// Account email address.
  final String email;

  /// Display name, from the `user_profiles` row or auth metadata.
  final String name;

  /// Username chosen at signup.
  final String username;

  /// The user's role.
  final UserRole role;

  /// Creates a user profile.
  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.username,
    required this.role,
  });
}
