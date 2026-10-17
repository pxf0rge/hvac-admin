import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/models/office_user.dart';

abstract class OfficePersonnelRepository {
  Future<List<OfficeUser>> getOfficeUsers();

  Future<OfficeUser> inviteOfficeUser({
    required String email,
    required String firstName,
    required String lastName,
    required UserRole role,
  });

  Future<OfficeUser> setRole({
    required String userId,
    required UserRole role,
  });

  Future<OfficeUser> setActive({
    required String userId,
    required bool isActive,
  });
}

class OfficePersonnelException implements Exception {
  OfficePersonnelException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}
