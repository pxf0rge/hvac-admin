import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/config/app_environment.dart';
import 'package:hvac_admin/core/config/supabase_config.dart';

void main() {
  group('HvacEnvironment.parse', () {
    test('accepts aliases', () {
      expect(HvacEnvironment.parse('production'), HvacEnvironment.production);
      expect(HvacEnvironment.parse('prod'), HvacEnvironment.production);
      expect(HvacEnvironment.parse('staging'), HvacEnvironment.staging);
      expect(HvacEnvironment.parse('stage'), HvacEnvironment.staging);
      expect(HvacEnvironment.parse('development'), HvacEnvironment.development);
      expect(HvacEnvironment.parse(''), HvacEnvironment.development);
    });
  });

  group('development defaults', () {
    test('boots without dart-defines', () {
      expect(AppEnvironment.isDevelopment, isTrue);
      expect(AppEnvironment.requiresExplicitSupabaseConfig, isFalse);
      expect(SupabaseConfig.isConfigured, isTrue);
      expect(SupabaseConfig.url, contains('supabase.co'));
      expect(SupabaseConfig.publishableKey, isNotEmpty);
      expect(SupabaseConfig.host, isNotEmpty);
    });
  });
}
