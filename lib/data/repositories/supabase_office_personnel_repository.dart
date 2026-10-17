import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/logging/hvac_log.dart';
import 'package:hvac_admin/core/models/office_user.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';
import 'package:hvac_admin/data/mappers/office_user_mapper.dart';
import 'package:hvac_admin/data/repositories/office_personnel_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseOfficePersonnelRepository implements OfficePersonnelRepository {
  SupabaseOfficePersonnelRepository(this._client);

  final SupabaseClient _client;

  static const _columns = 'id, first_name, last_name, email, role, is_active';

  @override
  Future<List<OfficeUser>> getOfficeUsers() async {
    final rows = await _client
        .from('profiles')
        .select(_columns)
        .neq('role', UserRole.technician.dbValue)
        .order('role')
        .order('last_name');
    return [
      for (final row in rows) OfficeUserMapper.fromRow(MapperHelpers.row(row)),
    ];
  }

  @override
  Future<OfficeUser> inviteOfficeUser({
    required String email,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) {
    return _invoke({
      'action': 'invite',
      'email': email.trim().toLowerCase(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'role': role.dbValue,
    });
  }

  @override
  Future<OfficeUser> setRole({required String userId, required UserRole role}) {
    return _invoke({
      'action': 'set_role',
      'user_id': userId,
      'role': role.dbValue,
    });
  }

  @override
  Future<OfficeUser> setActive({required String userId, required bool isActive}) {
    return _invoke({
      'action': 'set_active',
      'user_id': userId,
      'is_active': isActive,
    });
  }

  Future<OfficeUser> _invoke(Map<String, Object?> body) async {
    try {
      final response = await _client.functions.invoke('manage-office-user', body: body);
      final status = response.status;
      final data = response.data;
      if (status >= 400) {
        final code = data is Map ? data['error']?.toString() ?? 'manage_failed' : 'manage_failed';
        final message = data is Map
            ? data['message']?.toString() ?? 'Office user management failed'
            : 'Office user management failed';
        HvacLog.warn('office_user.manage_failed', fields: {'code': code, 'status': status});
        throw OfficePersonnelException(code, message);
      }
      if (data is! Map || data['user'] is! Map) {
        throw OfficePersonnelException('invalid_response', 'Unexpected manage-office-user response');
      }
      return OfficeUserMapper.fromRow(MapperHelpers.row(Map<String, dynamic>.from(data['user'] as Map)));
    } on OfficePersonnelException {
      rethrow;
    } catch (error, stack) {
      HvacLog.error('office_user.manage_failed', error: error, stack: stack);
      throw OfficePersonnelException('manage_failed', error.toString());
    }
  }
}
