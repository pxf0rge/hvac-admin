/// Authorization role source of truth for the admin app.
abstract final class AuthRolePolicy {
  AuthRolePolicy._();

  /// Server reads `public.profiles.role` — never JWT `user_metadata`.
  static const roleSourceTable = 'profiles';

  static const roleSourceColumn = 'role';

  /// Keys that must never be trusted from client-controlled auth metadata.
  static bool isPrivilegedMetadataKey(String key) {
    final normalized = key.trim().toLowerCase();
    return normalized == 'role' ||
        normalized == 'app_role' ||
        normalized == 'user_role' ||
        normalized == 'is_admin' ||
        normalized == 'is_owner';
  }
}
