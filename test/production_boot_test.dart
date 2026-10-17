import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/config/app_environment.dart';
import 'package:hvac_admin/core/config/production_boot_guard.dart';
import 'package:hvac_admin/data/datasources/hvac_realtime_service.dart';
import 'package:hvac_admin/data/datasources/mock_management_auth_service.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';
import 'package:hvac_admin/data/wiring/repository_wiring.dart';

void main() {
  group('RepositoryWiring', () {
    test('widget-test path (client null) uses Mock* repositories', () {
      final bundle = RepositoryWiring.create(client: null);

      expect(bundle.managementAuth, isA<MockManagementAuthService>());
      expect(bundle.customers, isA<MockCustomerRepository>());
      expect(bundle.jobs, isA<MockJobRepository>());
      expect(bundle.billing, isA<MockBillingRepository>());
      expect(bundle.realtime, isA<NoopRealtimeService>());
    });

    test('production wiring source maps domains to Supabase when client set', () {
      final wiring = File('lib/data/wiring/repository_wiring.dart').readAsStringSync();
      expect(wiring, contains('static HvacAdminRepositoryBundle _createSupabaseBundle'));
      expect(wiring, contains('SupabaseCustomerRepository(client)'));
      expect(wiring, contains('SupabaseBillingRepository(client,'));
      expect(wiring, isNot(contains('MockCustomerRepository(client)')));
    });
  });

  group('ProductionBootGuard', () {
    test('skips validation in development even without Supabase', () {
      expect(AppEnvironment.isDevelopment, isTrue);
      final bundle = RepositoryWiring.create(client: null);
      expect(
        () => ProductionBootGuard.validate(bundle: bundle, supabaseConnected: false),
        returnsNormally,
      );
    });
  });
}
