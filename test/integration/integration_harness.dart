import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/config/app_environment.dart';
import 'package:hvac_admin/core/config/environment_guard.dart';
import 'package:hvac_admin/core/config/supabase_config.dart';
import 'package:hvac_admin/data/datasources/supabase_management_auth_service.dart';
import 'package:hvac_admin/data/repositories/supabase_repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Boots a single Supabase client for admin integration tests.
class IntegrationTestHarness {
  IntegrationTestHarness._(this.client);

  final SupabaseClient client;

  late final SupabaseManagementAuthService managementAuth = SupabaseManagementAuthService(client);
  late final SupabaseCustomerRepository customers = SupabaseCustomerRepository(client);
  late final SupabaseJobRepository jobs = SupabaseJobRepository(client);
  late final SupabaseTechnicianRepository technicians = SupabaseTechnicianRepository(client);
  late final SupabaseBillingRepository billing = SupabaseBillingRepository(client);

  static Future<IntegrationTestHarness> boot() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final url = SupabaseConfig.url;
    EnvironmentGuard.validateSupabaseTarget(url: url, environment: AppEnvironment.current);
    await Supabase.initialize(
      url: url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    return IntegrationTestHarness._(Supabase.instance.client);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> signInOwner({
    String email = 'diana@hvacpro.com',
    String password = 'OfficeLead!',
  }) async {
    await signOut();
    final result = await managementAuth.signIn(email: email, password: password);
    expect(result.isSuccess, isTrue, reason: 'owner sign-in failed for $email');
  }

  Future<void> signInOfficeStaff({
    String email = 'marcus@hvacpro.com',
    String password = 'FrontDesk!',
  }) async {
    await signOut();
    final result = await managementAuth.signIn(email: email, password: password);
    expect(result.isSuccess, isTrue, reason: 'office_staff sign-in failed for $email');
  }
}
