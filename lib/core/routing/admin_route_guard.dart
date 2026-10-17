import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';

/// Resolves the longest matching [AdminModule] for a route path.
AdminModule? adminModuleForPath(String path) {
  AdminModule? match;
  var best = 0;
  for (final module in AdminModule.values) {
    if (path == module.path || path.startsWith('${module.path}/')) {
      if (module.path.length >= best) {
        best = module.path.length;
        match = module;
      }
    }
  }
  return match;
}

bool requiresOwnerAdminAccess(String path) {
  return path == '/settings/audit' || path.startsWith('/settings/audit/');
}

/// Returns whether [auth] may open [path]. Unknown paths are allowed (e.g. `/access-denied`).
bool canOpenAdminPath(ManagementAuthController auth, String path) {
  if (requiresOwnerAdminAccess(path) && !auth.canViewFinancials) return false;
  final module = adminModuleForPath(path);
  return module == null || auth.canOpen(module);
}
