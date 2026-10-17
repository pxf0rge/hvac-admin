import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/models/management_session.dart';

/// Single source of truth for admin UI module access (RLS is authoritative on server).
abstract final class PermissionService {
  PermissionService._();

  static bool canOpenModule(UserRole? role, AdminModule module) {
    if (role == null) return false;
    return canAccessAdminModule(role, module);
  }

  static List<AdminModule> visibleModules(UserRole? role) => [
        for (final module in AdminModule.values)
          if (canOpenModule(role, module)) module,
      ];
}
