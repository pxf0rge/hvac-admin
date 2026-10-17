import 'package:hvac_admin/core/config/app_environment.dart';
import 'package:hvac_admin/core/config/supabase_config.dart';

/// Opt-in live Supabase tests: pass `--dart-define=RUN_INTEGRATION_TESTS=true`
/// plus `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` (staging or local dev project).
abstract final class IntegrationConfig {
  static const _runFlag = bool.fromEnvironment('RUN_INTEGRATION_TESTS', defaultValue: false);

  static bool get enabled {
    if (!_runFlag) return false;
    if (AppEnvironment.isProduction) return false;
    try {
      return SupabaseConfig.isConfigured;
    } catch (_) {
      return false;
    }
  }

  static String? get skipReason {
    if (!_runFlag) {
      return 'Pass --dart-define=RUN_INTEGRATION_TESTS=true to run live Supabase integration tests.';
    }
    if (AppEnvironment.isProduction) {
      return 'Integration tests must not run against production (HVAC_ENV=production). Use staging.';
    }
    if (!SupabaseConfig.isConfigured) {
      return 'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be set for integration tests.';
    }
    return null;
  }
}

/// UUID used in `hvac_client/supabase/sql/rls_authorization_tests.sql` for IDOR denial.
abstract final class RlsTestFixtures {
  static const guessedJobUuid = '00000000-0000-4000-8000-000000000099';
  static const assignedJobNumber = 'JOB-RLS-21';
  static const unassignedJobNumber = 'JOB-RLS-UNASSIGNED';
}
