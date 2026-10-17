import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/user_role.dart';

class ManagementSession {
  const ManagementSession({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;

  String get displayName => '$firstName $lastName';

  bool get canViewFinancials => role.canViewFinancials;
}

bool canAccessAdminModule(UserRole role, AdminModule module) {
  if (!module.isFinancial) return true;
  return role.canViewFinancials;
}
