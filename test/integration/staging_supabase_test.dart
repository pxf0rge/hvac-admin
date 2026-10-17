import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/auth/management_sign_in_result.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'integration_config.dart';
import 'integration_harness.dart';

/// Live Supabase integration (staging/dev). Skipped unless RUN_INTEGRATION_TESTS=true.
/// Requires migrations + demo/RLS seed (`hvac_auth_seed_data`, `hvac_rls_verification_seed`).
void main() {
  IntegrationTestHarness? harness;

  setUpAll(() async {
    if (!IntegrationConfig.enabled) return;
    harness = await IntegrationTestHarness.boot();
  });

  tearDown(() async {
    await harness?.signOut();
  });

  group('staging Supabase — security denials', () {
    test('technician credentials rejected at management login', () async {
      if (!IntegrationConfig.enabled) return;
      await harness!.signOut();
      final result = await harness!.managementAuth.signIn(
        email: 'carlos@hvacpro.com',
        password: 'FieldReady!',
      );
      expect(result.isSuccess, isFalse);
      expect(result.error, ManagementSignInError.technicianNotAllowed);
      expect(harness!.client.auth.currentUser, isNull);
    }, skip: IntegrationConfig.skipReason);

    test('office_staff financial tables return zero rows (RLS DENIED)', () async {
      if (!IntegrationConfig.enabled) return;
      await harness!.signInOfficeStaff();

      final estimates = await harness!.client.from('estimates').select('id');
      final invoices = await harness!.client.from('invoices').select('id');
      final payments = await harness!.client.from('payments').select('id');

      expect(estimates, isEmpty, reason: 'office_staff must not read estimates');
      expect(invoices, isEmpty, reason: 'office_staff must not read invoices');
      expect(payments, isEmpty, reason: 'office_staff must not read payments');
    }, skip: IntegrationConfig.skipReason);

    test('technician guessed job UUID returns zero rows (IDOR DENIED)', () async {
      if (!IntegrationConfig.enabled) return;
      await harness!.signOut();
      await harness!.client.auth.signInWithPassword(
        email: 'carlos@hvacpro.com',
        password: 'FieldReady!',
      );

      final rows = await harness!.client
          .from('jobs')
          .select('id')
          .eq('id', RlsTestFixtures.guessedJobUuid);

      expect(rows, isEmpty, reason: 'guessed job UUID must not leak rows');
    }, skip: IntegrationConfig.skipReason);
  });

  group('staging Supabase — dispatch flow', () {
    test('owner creates customer, property, job, and assigns technician', () async {
      if (!IntegrationConfig.enabled) return;
      await harness!.signInOwner();

      final suffix = DateTime.now().millisecondsSinceEpoch;
      final customer = await harness!.customers.saveCustomer(
        OfficeCustomer(
          id: '',
          firstName: 'E2E',
          lastName: 'Admin$suffix',
          phone: '5550100',
          email: 'e2e.admin.$suffix@hvacpro.com',
          city: 'Springfield',
          state: 'IL',
        ),
      );
      expect(customer.id, isNotEmpty);

      final property = await harness!.customers.saveProperty(
        OfficeProperty(
          id: '',
          customerId: customer.id,
          address: '$suffix Integration Lane',
          city: 'Springfield',
          state: 'IL',
          zip: '62704',
          type: PropertyType.residential,
        ),
      );
      expect(property.id, isNotEmpty);

      final job = await harness!.jobs.createJob(
        propertyId: property.id,
        type: JobType.diagnostic,
        date: '2026-10-15',
        startTime: '09:00',
        endTime: '11:00',
        description: 'Phase 35 integration job $suffix',
      );
      expect(job.status, JobStatus.unassigned);

      final techs = await harness!.technicians.getTechnicians();
      expect(techs, isNotEmpty);
      final technicianId = techs.first.id;

      final assigned = await harness!.jobs.assignJob(jobId: job.id, technicianId: technicianId);
      expect(assigned.technicianId, technicianId);
      expect(assigned.status, JobStatus.assigned);
    }, skip: IntegrationConfig.skipReason);

    test('owner can read invoices via billing repository', () async {
      if (!IntegrationConfig.enabled) return;
      await harness!.signInOwner();

      final invoices = await harness!.billing.getInvoices();
      expect(invoices, isA<List>());
    }, skip: IntegrationConfig.skipReason);
  });
}
