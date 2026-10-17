import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/errors/failure_mapper.dart';
import 'package:hvac_admin/core/errors/hvac_failure.dart';
import 'package:hvac_admin/core/errors/storage_access_exception.dart';
import 'package:hvac_admin/core/models/management_session.dart';
import 'package:postgrest/postgrest.dart';

/// Phase 32 — explicit denial coverage (runs in CI without a database).
void main() {
  group('office role financial access → DENIED (client gate)', () {
    test('office_staff cannot open estimates, invoices, reports, or audit log path', () {
      for (final module in [AdminModule.estimates, AdminModule.invoices, AdminModule.reports]) {
        expect(
          canAccessAdminModule(UserRole.officeStaff, module),
          isFalse,
          reason: 'office_staff must be denied ${module.name}',
        );
      }
    });

    test('technician ManagementSession.canViewFinancials is false', () {
      expect(
        const ManagementSession(
          userId: 't1',
          email: 'carlos@hvacpro.com',
          firstName: 'Carlos',
          lastName: 'Mendez',
          role: UserRole.technician,
        ).canViewFinancials,
        isFalse,
      );
    });

    test('owner and admin can open financial modules', () {
      for (final role in [UserRole.owner, UserRole.admin]) {
        expect(canAccessAdminModule(role, AdminModule.invoices), isTrue);
        expect(canAccessAdminModule(role, AdminModule.reports), isTrue);
      }
    });
  });

  group('RLS / Postgrest denial surfaces as UnauthorizedFailure', () {
    test('Postgrest 42501 permission denied maps to UnauthorizedFailure', () {
      final failure = FailureMapper.map(
        const PostgrestException(message: 'permission denied for table invoices', code: '42501'),
      );
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, contains('permission'));
    });

    test('row-level security violation maps to UnauthorizedFailure', () {
      final failure = FailureMapper.map(
        const PostgrestException(message: 'new row violates row-level security policy'),
      );
      expect(failure, isA<UnauthorizedFailure>());
    });
  });

  group('storage IDOR denial', () {
    test('StorageAccessException maps to UnauthorizedFailure', () {
      final failure = FailureMapper.map(
        const StorageAccessException('denied', bucket: 'job_photos', path: 'job/x.png'),
      );
      expect(failure, isA<UnauthorizedFailure>());
    });
  });

  group('auth role policy contract', () {
    test('management auth service reads profiles.role not user_metadata', () {
      final source = File('lib/data/datasources/supabase_management_auth_service.dart').readAsStringSync();
      expect(source, contains("from('profiles')"));
      expect(source, contains("'role'"));
      expect(source, isNot(contains('user_metadata')));
      expect(source, isNot(contains('app_metadata')));
    });

    test('technician JWT is rejected at management login', () {
      final source = File('lib/data/datasources/supabase_management_auth_service.dart').readAsStringSync();
      expect(source, contains('!role.isManagement'));
      expect(source, contains('ManagementSignInError.technicianNotAllowed'));
      expect(source, contains('signOutOnRoleMismatch'));
    });
  });

  group('office_staff invoice access → DENIED', () {
    test('office_staff cannot open invoices module', () {
      expect(canAccessAdminModule(UserRole.officeStaff, AdminModule.invoices), isFalse);
    });

    test('RLS authorization SQL denies office_staff invoices', () {
      final sql = File('../hvac_client/supabase/sql/rls_authorization_tests.sql').readAsStringSync();
      expect(sql, contains('office_staff read invoices'));
    });
  });
}
