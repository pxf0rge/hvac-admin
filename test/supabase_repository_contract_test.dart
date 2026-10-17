import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CI-safe source contracts for all Supabase-backed admin repositories.
void main() {
  final repos = File('lib/data/repositories/supabase_repositories.dart').readAsStringSync();
  final audit = File('lib/data/repositories/supabase_audit_log_repository.dart').readAsStringSync();
  final auth = File('lib/data/datasources/supabase_management_auth_service.dart').readAsStringSync();
  final wiring = File('lib/data/wiring/repository_wiring.dart').readAsStringSync();

  group('Supabase repository wiring', () {
    test('_createSupabaseBundle maps every domain to Supabase implementation', () {
      const expected = [
        'SupabaseManagementAuthService',
        'SupabaseCustomerRepository',
        'SupabaseJobRepository',
        'SupabaseTechnicianRepository',
        'SupabaseFleetRepository',
        'SupabaseReportsRepository',
        'SupabaseBillingRepository',
        'SupabaseCommunicationRepository',
        'SupabaseInventoryRepository',
        'SupabaseMaintenanceAgreementRepository',
        'SupabaseSettingsRepository',
        'SupabaseDocumentTemplateRepository',
        'SupabaseTechnicianLocationRepository',
        'SupabaseAuditLogRepository',
      ];
      for (final type in expected) {
        expect(wiring, contains(type), reason: 'wiring must use $type');
      }
    });
  });

  group('Supabase repository interfaces', () {
    final cases = <String, String>{
      'SupabaseCustomerRepository': 'CustomerRepository',
      'SupabaseJobRepository': 'JobRepository',
      'SupabaseTechnicianRepository': 'TechnicianRepository',
      'SupabaseFleetRepository': 'FleetRepository',
      'SupabaseReportsRepository': 'ReportsRepository',
      'SupabaseBillingRepository': 'BillingRepository',
      'SupabaseCommunicationRepository': 'CommunicationRepository',
      'SupabaseInventoryRepository': 'InventoryRepository',
      'SupabaseMaintenanceAgreementRepository': 'MaintenanceAgreementRepository',
      'SupabaseSettingsRepository': 'SettingsRepository',
      'SupabaseDocumentTemplateRepository': 'DocumentTemplateRepository',
      'SupabaseTechnicianLocationRepository': 'TechnicianLocationRepository',
    };

    for (final entry in cases.entries) {
      test('${entry.key} implements ${entry.value}', () {
        expect(repos, contains('class ${entry.key} implements ${entry.value}'));
      });
    }

    test('SupabaseAuditLogRepository implements AuditRepository', () {
      expect(audit, contains('class SupabaseAuditLogRepository implements AuditRepository'));
    });

    test('SupabaseManagementAuthService implements ManagementAuthService', () {
      expect(auth, contains('class SupabaseManagementAuthService implements ManagementAuthService'));
    });
  });

  group('Supabase repository table coverage', () {
    final tableByRepo = <String, String>{
      'SupabaseCustomerRepository': "from('customers')",
      'SupabaseJobRepository': "from('jobs')",
      'SupabaseTechnicianRepository': "from('technicians')",
      'SupabaseBillingRepository': "from('invoices')",
      'SupabaseCommunicationRepository': "from('messages')",
      'SupabaseInventoryRepository': "from('inventory_items')",
      'SupabaseFleetRepository': "from('fleet_assets')",
      'SupabaseMaintenanceAgreementRepository': "from('maintenance_agreements')",
      'SupabaseSettingsRepository': "from('company_settings')",
      'SupabaseDocumentTemplateRepository': "from('document_templates')",
      'SupabaseTechnicianLocationRepository': "from('technician_locations')",
    };

    for (final entry in tableByRepo.entries) {
      test('${entry.key} queries ${entry.value}', () {
        expect(repos, contains(entry.value));
      });
    }

    test('SupabaseAuditLogRepository queries audit_log', () {
      expect(audit, contains("from('audit_log')"));
    });

    test('SupabaseReportsRepository aggregates operational data', () {
      expect(repos, contains('class SupabaseReportsRepository implements ReportsRepository'));
      expect(repos, contains("from('jobs')"));
    });
  });
}
