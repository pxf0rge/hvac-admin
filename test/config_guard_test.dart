import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/config/app_environment.dart';
import 'package:hvac_admin/core/config/supabase_config.dart';

const _hvacEnv = String.fromEnvironment('HVAC_ENV', defaultValue: 'development');

bool get _isStagingOrProduction {
  switch (_hvacEnv.trim().toLowerCase()) {
    case 'staging':
    case 'stage':
    case 'production':
    case 'prod':
      return true;
    default:
      return false;
  }
}

/// Run in isolation with --dart-define=HVAC_ENV=staging|production (no Supabase defines).
void main() {
  test('staging/production without defines fail fast', () {
    if (!_isStagingOrProduction) return;
    expect(AppEnvironment.requiresExplicitSupabaseConfig, isTrue);
    expect(() => SupabaseConfig.url, throwsStateError);
    expect(() => SupabaseConfig.publishableKey, throwsStateError);
    expect(SupabaseConfig.isConfigured, isFalse);
  });
}
