import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/models/management_session.dart';

/// Mirrors server-side financial matrix (UI gating only — not a substitute for RLS).
void main() {
  group('canAccessAdminModule (financial UI gate)', () {
    test('owner and admin can open financial modules', () {
      for (final role in [UserRole.owner, UserRole.admin]) {
        expect(canAccessAdminModule(role, AdminModule.estimates), isTrue);
        expect(canAccessAdminModule(role, AdminModule.invoices), isTrue);
        expect(canAccessAdminModule(role, AdminModule.reports), isTrue);
      }
    });

    test('office_staff and technician denied financial modules', () {
      for (final role in [UserRole.officeStaff, UserRole.technician]) {
        expect(canAccessAdminModule(role, AdminModule.estimates), isFalse);
        expect(canAccessAdminModule(role, AdminModule.invoices), isFalse);
        expect(canAccessAdminModule(role, AdminModule.reports), isFalse);
      }
    });

    test('all management roles can open non-financial modules', () {
      for (final role in [UserRole.owner, UserRole.admin, UserRole.officeStaff]) {
        expect(canAccessAdminModule(role, AdminModule.customers), isTrue);
        expect(canAccessAdminModule(role, AdminModule.dispatch), isTrue);
        expect(canAccessAdminModule(role, AdminModule.jobs), isTrue);
        expect(canAccessAdminModule(role, AdminModule.inventory), isTrue);
      }
    });
  });

  group('ManagementSession.canViewFinancials', () {
    test('matches owner/admin only', () {
      expect(
        const ManagementSession(
          userId: '1',
          email: 'o@x.com',
          firstName: 'O',
          lastName: 'W',
          role: UserRole.owner,
        ).canViewFinancials,
        isTrue,
      );
      expect(
        const ManagementSession(
          userId: '2',
          email: 's@x.com',
          firstName: 'S',
          lastName: 'T',
          role: UserRole.officeStaff,
        ).canViewFinancials,
        isFalse,
      );
    });
  });
}
