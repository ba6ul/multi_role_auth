/// Table/column names for the Supabase `user_profiles` table used by the
/// auth flow. Change these in one place when reusing the auth module in a
/// project with a differently-named schema — no need to hunt through
/// individual data/service files for hardcoded strings.
class SupabaseSchema {
  /// Name of the profiles table.
  static const String userProfilesTable = 'user_profiles';

  /// Column holding the Supabase auth user id.
  static const String userIdColumn = 'user_id';

  /// Column holding an app-generated custom user id, if used.
  static const String customUserIdColumn = 'custom_user_id';

  /// Column holding the user's role.
  static const String roleColumn = 'role';

  /// Column flagging whether profile setup is complete.
  static const String profileCompletedColumn = 'profile_completed';

  /// Edge Function that deletes the auth.users row (requires the service
  /// role, so this can't be done from the client directly). Deploy it
  /// under this name, or change this constant to match.
  static const String deleteAccountFunction = 'delete-account';
}
