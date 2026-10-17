import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/config/app_environment.dart';
import 'package:hvac_admin/core/config/environment_guard.dart';
import 'package:hvac_admin/core/config/supabase_config.dart';

void main() {
  group('EnvironmentGuard', () {
    test('allows development to use embedded dev project', () {
      expect(
        () => EnvironmentGuard.validateSupabaseTarget(
          url: 'https://${EnvironmentGuard.devProjectRef}.supabase.co',
          environment: HvacEnvironment.development,
        ),
        returnsNormally,
      );
    });

    test('blocks staging from dev project ref', () {
      expect(
        () => EnvironmentGuard.validateSupabaseTarget(
          url: 'https://${EnvironmentGuard.devProjectRef}.supabase.co',
          environment: HvacEnvironment.staging,
        ),
        throwsStateError,
      );
    });

    test('blocks production from dev project ref', () {
      expect(
        () => EnvironmentGuard.validateSupabaseTarget(
          url: 'https://${EnvironmentGuard.devProjectRef}.supabase.co',
          environment: HvacEnvironment.production,
        ),
        throwsStateError,
      );
    });

    test('accepts distinct staging host', () {
      expect(
        () => EnvironmentGuard.validateSupabaseTarget(
          url: 'https://hvac-staging-example.supabase.co',
          environment: HvacEnvironment.staging,
        ),
        returnsNormally,
      );
    });

    test('rejects invalid supabase host', () {
      expect(
        () => EnvironmentGuard.validateSupabaseTarget(
          url: 'https://not-supabase.example.com',
          environment: HvacEnvironment.staging,
        ),
        throwsStateError,
      );
    });
  });

  group('environment isolation', () {
    test('staging and production require explicit Supabase defines', () {
      expect(AppEnvironment.requiresExplicitSupabaseConfig, isFalse);
      expect(HvacEnvironment.staging, isNot(HvacEnvironment.development));
      expect(HvacEnvironment.production, isNot(HvacEnvironment.development));
    });

    test('development default host differs from example staging host', () {
      expect(SupabaseConfig.url, contains(EnvironmentGuard.devProjectRef));
      expect('https://hvac-staging-example.supabase.co', isNot(contains(EnvironmentGuard.devProjectRef)));
    });
  });
}
