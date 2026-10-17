import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/routing/admin_route_guard.dart';
import 'package:hvac_admin/data/datasources/mock_management_auth_service.dart';

void main() {
  group('admin_route_guard', () {
    test('adminModuleForPath resolves longest match', () {
      expect(adminModuleForPath('/invoices'), AdminModule.invoices);
      expect(adminModuleForPath('/customers/abc'), AdminModule.customers);
      expect(adminModuleForPath('/settings/audit'), AdminModule.settings);
      expect(adminModuleForPath('/unknown'), isNull);
    });

    test('canOpenAdminPath respects role', () async {
      final auth = AppManagementAuthController(MockManagementAuthService());
      await auth.signIn(email: 'marcus@hvacpro.com', password: 'FrontDesk!');

      expect(canOpenAdminPath(auth, '/customers'), isTrue);
      expect(canOpenAdminPath(auth, '/invoices'), isFalse);
      expect(canOpenAdminPath(auth, '/settings'), isTrue);
      expect(canOpenAdminPath(auth, '/settings/audit'), isFalse);

      auth.dispose();
    });

    test('owner can open audit log route', () async {
      final auth = AppManagementAuthController(MockManagementAuthService());
      await auth.signIn(email: 'diana@hvacpro.com', password: 'OfficeLead!');

      expect(canOpenAdminPath(auth, '/settings/audit'), isTrue);

      auth.dispose();
    });
  });
}
