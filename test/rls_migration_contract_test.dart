import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/security/web_security_policy.dart';
import 'package:hvac_admin/core/security/web_security_policy.dart';

/// CI-safe contract tests against shared Supabase migrations in `../hvac_client`.
void main() {
  const clientRoot = '../hvac_client';
  final policies = File('$clientRoot/supabase/migrations/20260824180500_hvac_rls_policies.sql');
  final fileHardening = File('$clientRoot/supabase/migrations/20260829260000_hvac_security_file_hardening.sql');
  final authTests = File('$clientRoot/supabase/sql/rls_authorization_tests.sql');
  final audit = File('$clientRoot/supabase/sql/security_audit_checks.sql');
  final verifyScript = File('$clientRoot/tool/verify_rls.sh');

  test('RLS policy migration gates financial tables', () {
    final sql = policies.readAsStringSync();
    for (final table in ['estimates', 'invoices', 'estimate_line_items', 'invoice_line_items']) {
      expect(sql, contains('on public.$table'));
      expect(sql, contains('app.can_view_financials()'), reason: 'financial gate for $table');
    }
  });

  test('file hardening migration keeps HVAC buckets private', () {
    final sql = fileHardening.readAsStringSync();
    expect(sql, contains("'job_photos', 'job_photos', false"));
    expect(sql, contains('storage_objects_deny_anon'));
    expect(sql, contains('revoke insert, update, delete on public.audit_log'));
  });

  test('authorization SQL suite covers technician financial denial', () {
    final sql = authTests.readAsStringSync();
    expect(sql, contains('technician read estimates'));
    expect(sql, contains('technician read invoices'));
    expect(sql, contains('guessed job uuid'));
  });

  test('security audit SQL asserts structural guarantees', () {
    final sql = audit.readAsStringSync();
    expect(sql, contains('RLS_AUDIT_FAIL'));
    expect(sql, contains('HVAC storage bucket is public'));
    expect(sql, contains('validate_technician_job_activity executable by authenticated'));
  });

  test('shared verify_rls script exists for staging/production', () {
    expect(verifyScript.existsSync(), isTrue);
    expect(verifyScript.readAsStringSync(), contains('security_audit_checks.sql'));
  });

  test('deployment environment isolation migration exists in shared backend', () {
    final migration = File('../hvac_client/supabase/migrations/20260829270000_hvac_environment_isolation.sql');
    expect(migration.existsSync(), isTrue);
    final sql = migration.readAsStringSync();
    expect(sql, contains('app.deployment_config'));
    expect(sql, contains('demo_seed_blocked'));
    expect(sql, contains('lock_production_environment'));
  });

  test('production cutover SQL exists for go-live', () {
    expect(File('../hvac_client/supabase/sql/production_cutover.sql').existsSync(), isTrue);
  });

  test('admin web CSP policy blocks framing and limits connect-src', () {
    expect(WebSecurityPolicy.contentSecurityPolicy, contains("frame-ancestors 'none'"));
    expect(WebSecurityPolicy.contentSecurityPolicy, contains('connect-src'));
    expect(WebSecurityPolicy.contentSecurityPolicy, contains('supabase.co'));
  });
}
