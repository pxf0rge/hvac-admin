import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/models/office_user.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';

abstract final class OfficeUserMapper {
  static OfficeUser fromRow(Map<String, dynamic> row) {
    return OfficeUser(
      id: MapperHelpers.uuid(row['id']),
      firstName: MapperHelpers.str(row['first_name']),
      lastName: MapperHelpers.str(row['last_name']),
      email: MapperHelpers.strOrNull(row['email']),
      role: UserRoleDbX.fromDb(MapperHelpers.str(row['role'])),
      isActive: row['is_active'] is bool ? row['is_active'] as bool : true,
    );
  }
}
