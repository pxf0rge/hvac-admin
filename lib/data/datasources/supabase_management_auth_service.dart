import 'package:hvac_admin/core/audit/audit_actions.dart';
import 'package:hvac_admin/core/audit/audit_metadata.dart';
import 'package:hvac_admin/core/auth/management_sign_in_result.dart';
import 'package:hvac_admin/core/config/supabase_config.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/logging/hvac_log.dart';
import 'package:hvac_admin/core/models/management_session.dart';
import 'package:hvac_admin/data/datasources/management_auth_service.dart';
import 'package:hvac_admin/data/datasources/supabase_audit_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManagementAuthService implements ManagementAuthService {
  SupabaseManagementAuthService(this._client, {SupabaseAuditLog? audit}) : _audit = audit;

  final SupabaseClient _client;
  final SupabaseAuditLog? _audit;

  @override
  Future<ManagementSignInResult> signIn({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final sw = Stopwatch()..start();
    HvacLog.info('auth.sign_in.start', fields: {
      'supabase_host': SupabaseConfig.host,
      'email': normalizedEmail,
      'password_length': password.length,
    });

    try {
      final result = await _client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      sw.stop();
      final user = result.user;
      HvacLog.info('auth.sign_in.supabase_ok', fields: {
        'supabase_host': SupabaseConfig.host,
        'elapsed_ms': sw.elapsedMilliseconds,
        'has_user': user != null,
        'has_session': result.session != null,
        'user_id': user?.id,
      });

      if (user == null) {
        HvacLog.warn('auth.sign_in.no_user', fields: {
          'supabase_host': SupabaseConfig.host,
          'email': normalizedEmail,
        });
        return ManagementSignInResult.failure(ManagementSignInError.invalidCredentials);
      }

      final sessionResult = await _sessionFor(user.id, user.email ?? email, signOutOnRoleMismatch: true);
      final session = sessionResult.session;
      if (session != null) {
        await _audit?.record(
          action: AuditActions.authLogin,
          entityType: 'session',
          entityId: session.userId,
          metadata: AuditMetadata.authLogin(email: session.email),
        );
        HvacLog.info('auth.sign_in.success', fields: {
          'user_id': session.userId,
          'role': session.role.name,
        });
      } else {
        HvacLog.warn('auth.sign_in.session_rejected', fields: {
          'user_id': user.id,
          'error': sessionResult.error?.name,
        });
      }
      return sessionResult;
    } on AuthException catch (e) {
      sw.stop();
      // AuthException means Supabase Auth responded (credentials / auth rule).
      HvacLog.warn('auth.sign_in.auth_exception', fields: {
        'supabase_host': SupabaseConfig.host,
        'email': normalizedEmail,
        'elapsed_ms': sw.elapsedMilliseconds,
        'reached_supabase': true,
        'status_code': e.statusCode,
        'code': e.code,
        'message': e.message,
      });
      return ManagementSignInResult.failure(ManagementSignInError.invalidCredentials);
    } catch (e, st) {
      sw.stop();
      // Network / DNS / TLS — request likely never reached Auth successfully.
      HvacLog.error(
        'auth.sign_in.transport_error',
        fields: {
          'supabase_host': SupabaseConfig.host,
          'email': normalizedEmail,
          'elapsed_ms': sw.elapsedMilliseconds,
          'reached_supabase': false,
          'error_type': e.runtimeType.toString(),
        },
        error: e,
        stack: st,
      );
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<ManagementSession?> restore() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final result = await _sessionFor(user.id, user.email ?? '', signOutOnRoleMismatch: false);
    return result.session;
  }

  Future<ManagementSignInResult> _sessionFor(
    String userId,
    String email, {
    required bool signOutOnRoleMismatch,
  }) async {
    final profile = await _client
        .from('profiles')
        .select('role, first_name, last_name, email, is_active')
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) {
      if (signOutOnRoleMismatch) await _client.auth.signOut();
      return ManagementSignInResult.failure(ManagementSignInError.profileNotFound);
    }

    if (profile['is_active'] == false) {
      if (signOutOnRoleMismatch) await _client.auth.signOut();
      return ManagementSignInResult.failure(ManagementSignInError.accountDisabled);
    }

    final role = UserRoleDbX.fromDb(profile['role'] as String);
    if (!role.isManagement) {
      if (signOutOnRoleMismatch) await _client.auth.signOut();
      return ManagementSignInResult.failure(ManagementSignInError.technicianNotAllowed);
    }

    return ManagementSignInResult.success(
      ManagementSession(
        userId: userId,
        email: (profile['email'] as String?) ?? email,
        firstName: profile['first_name'] as String,
        lastName: profile['last_name'] as String,
        role: role,
      ),
    );
  }
}
