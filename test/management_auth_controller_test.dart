import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/auth/management_sign_in_result.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/data/datasources/mock_management_auth_service.dart';

void main() {
  group('AppManagementAuthController', () {
    late ManagementAuthController auth;

    setUp(() {
      auth = AppManagementAuthController(MockManagementAuthService());
    });

    tearDown(() => auth.dispose());

    test('owner sign-in succeeds', () async {
      final ok = await auth.signIn(email: 'diana@hvacpro.com', password: 'OfficeLead!');
      expect(ok, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.role, UserRole.owner);
      expect(auth.canViewFinancials, isTrue);
    });

    test('office staff sign-in succeeds', () async {
      final ok = await auth.signIn(email: 'marcus@hvacpro.com', password: 'FrontDesk!');
      expect(ok, isTrue);
      expect(auth.role, UserRole.officeStaff);
      expect(auth.canViewFinancials, isFalse);
    });

    test('technician sign-in is rejected', () async {
      final ok = await auth.signIn(email: 'carlos@hvacpro.com', password: 'FieldReady!');
      expect(ok, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.lastSignInError, ManagementSignInError.technicianNotAllowed);
    });

    test('office staff cannot open financial modules', () async {
      await auth.signIn(email: 'marcus@hvacpro.com', password: 'FrontDesk!');
      expect(auth.canOpen(AdminModule.customers), isTrue);
      expect(auth.canOpen(AdminModule.invoices), isFalse);
      expect(auth.canOpen(AdminModule.reports), isFalse);
    });

    test('owner can open financial modules', () async {
      await auth.signIn(email: 'diana@hvacpro.com', password: 'OfficeLead!');
      expect(auth.canOpen(AdminModule.invoices), isTrue);
      expect(auth.canOpen(AdminModule.reports), isTrue);
    });

    test('invalid credentials fail', () async {
      final ok = await auth.signIn(email: 'diana@hvacpro.com', password: 'wrong');
      expect(ok, isFalse);
      expect(auth.lastSignInError, ManagementSignInError.invalidCredentials);
    });

    test('sign-out clears session', () async {
      await auth.signIn(email: 'diana@hvacpro.com', password: 'OfficeLead!');
      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.session, isNull);
    });

    test('restore returns persisted mock session', () async {
      final service = MockManagementAuthService();
      final signedIn = AppManagementAuthController(service);
      await signedIn.signIn(email: 'diana@hvacpro.com', password: 'OfficeLead!');
      signedIn.dispose();

      final restored = AppManagementAuthController(service);
      await restored.restore();
      expect(restored.isAuthenticated, isTrue);
      expect(restored.session?.displayName, 'Diana Walsh');
      restored.dispose();
    });
  });
}
