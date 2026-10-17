import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/auth/permission_service.dart';
import 'package:hvac_admin/core/controllers/office_personnel_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/data/datasources/mock_settings_data.dart';
import 'package:hvac_admin/data/repositories/mock_office_personnel_repository.dart';

void main() {
  test('Office Personnel module is available to all office roles', () {
    for (final role in [UserRole.owner, UserRole.admin, UserRole.officeStaff]) {
      expect(PermissionService.canOpenModule(role, AdminModule.officePersonnel), isTrue);
    }
  });

  test('OfficePersonnelController loads office users only', () async {
    final controller = OfficePersonnelController(MockOfficePersonnelRepository(MockSettingsData()));
    await controller.load();
    expect(controller.users.length, 3);
    expect(controller.users.every((u) => u.role != UserRole.technician), isTrue);
    expect(controller.userById('mgr_owner_1')?.email, 'diana@hvacpro.com');
  });

  test('OfficePersonnelController invite and deactivate', () async {
    final controller = OfficePersonnelController(MockOfficePersonnelRepository(MockSettingsData()));
    await controller.load();
    final invited = await controller.invite(
      email: 'new.staff@hvacpro.com',
      firstName: 'Pat',
      lastName: 'Lee',
      role: UserRole.officeStaff,
    );
    expect(invited, isNotNull);
    expect(controller.users.any((u) => u.email == 'new.staff@hvacpro.com'), isTrue);

    final deactivated = await controller.setActive(userId: invited!.id, isActive: false);
    expect(deactivated?.isActive, isFalse);

    final roleChanged = await controller.changeRole(userId: invited.id, role: UserRole.admin);
    expect(roleChanged?.role, UserRole.admin);
  });

  test('AdminModule.officePersonnel has dedicated path and detail support', () {
    expect(AdminModule.officePersonnel.path, '/office-personnel');
    expect(AdminModule.officePersonnel.supportsDetailRoute, isTrue);
    expect(AdminModule.officePersonnel.label, 'Office Personnel');
  });
}
