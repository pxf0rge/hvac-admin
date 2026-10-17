import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/auth/permission_service.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/user_role.dart';

void main() {
  group('PermissionService', () {
    test('owner and admin can open financial modules', () {
      for (final role in [UserRole.owner, UserRole.admin]) {
        expect(PermissionService.canOpenModule(role, AdminModule.invoices), isTrue);
        expect(PermissionService.canOpenModule(role, AdminModule.estimates), isTrue);
        expect(PermissionService.canOpenModule(role, AdminModule.reports), isTrue);
      }
    });

    test('office staff cannot open financial modules', () {
      expect(PermissionService.canOpenModule(UserRole.officeStaff, AdminModule.invoices), isFalse);
      expect(PermissionService.canOpenModule(UserRole.officeStaff, AdminModule.estimates), isFalse);
      expect(PermissionService.canOpenModule(UserRole.officeStaff, AdminModule.reports), isFalse);
    });

    test('office staff can open operational modules', () {
      expect(PermissionService.canOpenModule(UserRole.officeStaff, AdminModule.customers), isTrue);
      expect(PermissionService.canOpenModule(UserRole.officeStaff, AdminModule.dispatch), isTrue);
      expect(PermissionService.canOpenModule(UserRole.officeStaff, AdminModule.settings), isTrue);
    });

    test('visibleModules excludes financials for office staff', () {
      final modules = PermissionService.visibleModules(UserRole.officeStaff);
      expect(modules, isNot(contains(AdminModule.invoices)));
      expect(modules, isNot(contains(AdminModule.estimates)));
      expect(modules, isNot(contains(AdminModule.reports)));
      expect(modules, contains(AdminModule.customers));
    });

    test('null role cannot open any module', () {
      expect(PermissionService.canOpenModule(null, AdminModule.dashboard), isFalse);
    });
  });
}
