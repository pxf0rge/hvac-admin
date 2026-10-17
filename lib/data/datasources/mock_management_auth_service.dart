import 'package:hvac_admin/core/audit/audit_actions.dart';

import 'package:hvac_admin/core/audit/audit_metadata.dart';

import 'package:hvac_admin/core/audit/audit_recording.dart';

import 'package:hvac_admin/core/audit/in_memory_audit_log.dart';

import 'package:hvac_admin/core/auth/management_sign_in_result.dart';

import 'package:hvac_admin/core/enums/user_role.dart';

import 'package:hvac_admin/core/models/management_session.dart';

import 'package:hvac_admin/data/datasources/management_auth_service.dart';



class MockManagementAuthService implements ManagementAuthService {

  MockManagementAuthService({InMemoryAuditLog? auditLog}) : _auditLog = auditLog;



  final InMemoryAuditLog? _auditLog;



  static const _accounts = [

    (

      email: 'diana@hvacpro.com',

      password: 'OfficeLead!',

      userId: 'mgr_owner_1',

      firstName: 'Diana',

      lastName: 'Walsh',

      role: UserRole.owner,

    ),

    (

      email: 'marcus@hvacpro.com',

      password: 'FrontDesk!',

      userId: 'mgr_staff_1',

      firstName: 'Marcus',

      lastName: 'Bennett',

      role: UserRole.officeStaff,

    ),

    (

      email: 'carlos@hvacpro.com',

      password: 'FieldReady!',

      userId: 'tech_1',

      firstName: 'Carlos',

      lastName: 'Mendez',

      role: UserRole.technician,

    ),

  ];



  ManagementSession? _session;



  @override

  Future<ManagementSignInResult> signIn({

    required String email,

    required String password,

  }) async {

    await Future<void>.delayed(const Duration(milliseconds: 100));

    final normalized = email.trim().toLowerCase();

    for (final account in _accounts) {

      if (account.email == normalized && account.password == password) {

        if (!account.role.isManagement) {

          return ManagementSignInResult.failure(ManagementSignInError.technicianNotAllowed);

        }

        _session = ManagementSession(

          userId: account.userId,

          email: account.email,

          firstName: account.firstName,

          lastName: account.lastName,

          role: account.role,

        );

        recordMockAudit(

          _auditLog,

          action: AuditActions.authLogin,

          entityType: 'session',

          entityId: account.userId,

          metadata: AuditMetadata.authLogin(email: account.email),

          actorUserId: account.userId,

          actorName: '${account.firstName} ${account.lastName}',

          actorRole: account.role.dbValue,

        );

        return ManagementSignInResult.success(_session!);

      }

    }

    return ManagementSignInResult.failure(ManagementSignInError.invalidCredentials);

  }



  @override

  Future<void> signOut() async {

    _session = null;

  }



  @override

  Future<ManagementSession?> restore() async => _session;

}

