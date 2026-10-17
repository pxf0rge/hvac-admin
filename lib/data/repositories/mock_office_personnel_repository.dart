import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/models/office_user.dart';
import 'package:hvac_admin/data/datasources/mock_settings_data.dart';
import 'package:hvac_admin/data/repositories/office_personnel_repository.dart';

class MockOfficePersonnelRepository implements OfficePersonnelRepository {
  MockOfficePersonnelRepository(this._data);

  final MockSettingsData _data;
  var _nextId = 100;

  @override
  Future<List<OfficeUser>> getOfficeUsers() async => List.unmodifiable(_data.officeUsers);

  @override
  Future<OfficeUser> inviteOfficeUser({
    required String email,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) async {
    if (role == UserRole.technician) {
      throw OfficePersonnelException('invalid_role', 'Technician invites are not allowed here');
    }
    final normalized = email.trim().toLowerCase();
    if (_data.officeUsers.any((u) => u.email?.toLowerCase() == normalized)) {
      throw OfficePersonnelException('invite_failed', 'A user with this email already exists');
    }
    final user = OfficeUser(
      id: 'mgr_new_${_nextId++}',
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: normalized,
      role: role,
      isActive: true,
    );
    _data.officeUsers = [..._data.officeUsers, user];
    return user;
  }

  @override
  Future<OfficeUser> setRole({required String userId, required UserRole role}) async {
    final index = _data.officeUsers.indexWhere((u) => u.id == userId);
    if (index < 0) throw OfficePersonnelException('not_found', 'Profile not found');
    final updated = _data.officeUsers[index].copyWith(role: role);
    final next = [..._data.officeUsers];
    next[index] = updated;
    _data.officeUsers = next;
    return updated;
  }

  @override
  Future<OfficeUser> setActive({required String userId, required bool isActive}) async {
    final index = _data.officeUsers.indexWhere((u) => u.id == userId);
    if (index < 0) throw OfficePersonnelException('not_found', 'Profile not found');
    final updated = _data.officeUsers[index].copyWith(isActive: isActive);
    final next = [..._data.officeUsers];
    next[index] = updated;
    _data.officeUsers = next;
    return updated;
  }
}
