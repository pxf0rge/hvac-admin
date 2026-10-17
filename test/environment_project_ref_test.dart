import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/config/app_environment.dart';
import 'package:hvac_admin/core/config/environment_guard.dart';

void main() {
  group('EnvironmentGuard.projectRefFromUrl', () {
    test('extracts ref from supabase host', () {
      expect(
        EnvironmentGuard.projectRefFromUrl('https://hvac-staging-example.supabase.co'),
        'hvac-staging-example',
      );
    });
  });

  group('validateProjectRefRules', () {
    const stagingRef = 'hvac-staging-abc';
    const productionRef = 'hvac-production-xyz';

    test('production rejects staging ref when STAGING_PROJECT_REF is set', () {
      expect(
        () => EnvironmentGuard.validateProjectRefRules(
          environment: HvacEnvironment.production,
          projectRef: stagingRef,
          stagingProjectRef: stagingRef,
          productionProjectRef: productionRef,
        ),
        throwsStateError,
      );
    });

    test('staging rejects production ref when PRODUCTION_PROJECT_REF is set', () {
      expect(
        () => EnvironmentGuard.validateProjectRefRules(
          environment: HvacEnvironment.staging,
          projectRef: productionRef,
          stagingProjectRef: stagingRef,
          productionProjectRef: productionRef,
        ),
        throwsStateError,
      );
    });

    test('production requires production ref when PRODUCTION_PROJECT_REF is set', () {
      expect(
        () => EnvironmentGuard.validateProjectRefRules(
          environment: HvacEnvironment.production,
          projectRef: stagingRef,
          stagingProjectRef: stagingRef,
          productionProjectRef: productionRef,
        ),
        throwsStateError,
      );

      expect(
        () => EnvironmentGuard.validateProjectRefRules(
          environment: HvacEnvironment.production,
          projectRef: productionRef,
          stagingProjectRef: stagingRef,
          productionProjectRef: productionRef,
        ),
        returnsNormally,
      );
    });

    test('staging requires staging ref when STAGING_PROJECT_REF is set', () {
      expect(
        () => EnvironmentGuard.validateProjectRefRules(
          environment: HvacEnvironment.staging,
          projectRef: productionRef,
          stagingProjectRef: stagingRef,
          productionProjectRef: productionRef,
        ),
        throwsStateError,
      );

      expect(
        () => EnvironmentGuard.validateProjectRefRules(
          environment: HvacEnvironment.staging,
          projectRef: stagingRef,
          stagingProjectRef: stagingRef,
          productionProjectRef: productionRef,
        ),
        returnsNormally,
      );
    });

    test('SUPABASE_PROJECT_REF must match URL host ref', () {
      expect(
        () => EnvironmentGuard.validateProjectRefRules(
          environment: HvacEnvironment.staging,
          projectRef: stagingRef,
          expectedProjectRef: productionRef,
        ),
        throwsStateError,
      );
    });
  });
}
