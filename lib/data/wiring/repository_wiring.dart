import 'package:hvac_admin/core/messaging/message_sender.dart';
import 'package:hvac_admin/core/messaging/supabase_message_sender.dart';
import 'package:hvac_admin/core/translate/translate_repository.dart';
import 'package:hvac_admin/core/translate/supabase_translate_repository.dart';
import 'package:hvac_admin/core/audit/in_memory_audit_log.dart';

import 'package:hvac_admin/core/media/admin_media_storage.dart';

import 'package:hvac_admin/core/media/secure_media_access.dart';

import 'package:hvac_admin/data/datasources/supabase_admin_media_storage.dart';

import 'package:hvac_admin/data/datasources/hvac_realtime_service.dart';

import 'package:hvac_admin/data/datasources/supabase_realtime_service.dart';

import 'package:hvac_admin/data/datasources/management_auth_service.dart';

import 'package:hvac_admin/data/datasources/mock_management_auth_service.dart';

import 'package:hvac_admin/data/datasources/supabase_management_auth_service.dart';

import 'package:hvac_admin/data/datasources/supabase_audit_log.dart';

import 'package:hvac_admin/data/repositories/audit_repository.dart';

import 'package:hvac_admin/data/repositories/billing_repository.dart';

import 'package:hvac_admin/data/repositories/communication_repository.dart';

import 'package:hvac_admin/data/repositories/customer_repository.dart';

import 'package:hvac_admin/data/repositories/document_template_repository.dart';

import 'package:hvac_admin/data/repositories/mock_audit_log_repository.dart';

import 'package:hvac_admin/data/repositories/mock_document_template_repository.dart';

import 'package:hvac_admin/data/datasources/mock_document_templates.dart';

import 'package:hvac_admin/data/repositories/fleet_repository.dart';

import 'package:hvac_admin/data/repositories/internal_messaging_repository.dart';

import 'package:hvac_admin/data/repositories/mock_internal_messaging_repository.dart';

import 'package:hvac_admin/data/repositories/supabase_internal_messaging_repository.dart';

import 'package:hvac_admin/data/repositories/inventory_repository.dart';

import 'package:hvac_admin/data/repositories/job_repository.dart';

import 'package:hvac_admin/data/repositories/maintenance_agreement_repository.dart';

import 'package:hvac_admin/data/datasources/mock_seed_data.dart';

import 'package:hvac_admin/data/datasources/mock_settings_data.dart';

import 'package:hvac_admin/data/repositories/mock_settings_repository.dart';

import 'package:hvac_admin/data/repositories/mock_reports_repository.dart';

import 'package:hvac_admin/data/repositories/mock_repositories.dart';

import 'package:hvac_admin/data/repositories/reports_repository.dart';

import 'package:hvac_admin/data/repositories/settings_repository.dart';

import 'package:hvac_admin/data/repositories/portal_repository.dart';

import 'package:hvac_admin/data/repositories/mock_portal_repository.dart';

import 'package:hvac_admin/data/repositories/supabase_portal_repository.dart';

import 'package:hvac_admin/data/repositories/office_personnel_repository.dart';

import 'package:hvac_admin/data/repositories/mock_office_personnel_repository.dart';

import 'package:hvac_admin/data/repositories/supabase_office_personnel_repository.dart';

import 'package:hvac_admin/data/repositories/supabase_audit_log_repository.dart';

import 'package:hvac_admin/data/repositories/supabase_repositories.dart';

import 'package:hvac_admin/data/repositories/mock_technician_location_repository.dart';

import 'package:hvac_admin/data/repositories/technician_location_repository.dart';

import 'package:hvac_admin/data/repositories/technician_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';



/// All repository + datasource instances for [HvacAdminApp].

class HvacAdminRepositoryBundle {

  const HvacAdminRepositoryBundle({

    required this.managementAuth,

    required this.customers,

    required this.jobs,

    required this.technicians,

    required this.fleet,

    required this.reports,

    required this.billing,

    required this.communication,

    required this.internalMessaging,

    required this.inventory,

    required this.maintenanceAgreements,

    required this.settings,

    required this.officePersonnel,

    required this.documentTemplates,

    required this.locations,

    required this.realtime,

    required this.messageSender,

    required this.translate,

    required this.portal,

    required this.audit,

    required this.secureMedia,

  });



  final ManagementAuthService managementAuth;

  final CustomerRepository customers;

  final JobRepository jobs;

  final TechnicianRepository technicians;

  final FleetRepository fleet;

  final ReportsRepository reports;

  final BillingRepository billing;

  final CommunicationRepository communication;

  final InternalMessagingRepository internalMessaging;

  final InventoryRepository inventory;

  final MaintenanceAgreementRepository maintenanceAgreements;

  final SettingsRepository settings;

  final OfficePersonnelRepository officePersonnel;

  final DocumentTemplateRepository documentTemplates;

  final TechnicianLocationRepository locations;

  final HvacRealtimeService realtime;

  final MessageSender messageSender;

  final TranslateRepository translate;

  final PortalRepository portal;

  final AuditRepository audit;

  final SecureMediaAccess secureMedia;

}



/// Central wiring: Supabase when [client] is non-null; mocks for widget tests only.

abstract final class RepositoryWiring {

  static HvacAdminRepositoryBundle create({SupabaseClient? client, ManagementAuthService? managementAuth}) {

    if (client == null) {

      return _createMockBundle(managementAuth: managementAuth);

    }

    return _createSupabaseBundle(client, managementAuth: managementAuth);

  }



  static HvacAdminRepositoryBundle _createMockBundle({ManagementAuthService? managementAuth}) {

    final auditLog = InMemoryAuditLog();

    // One seed per bundle so each app instance (and each widget test) starts

    // from pristine fixtures instead of mutating shared state.

    final seed = MockSeedData();

    final customers = MockCustomerRepository(seed: seed);

    final jobs = MockJobRepository(seed: seed, auditLog: auditLog);

    final technicians = MockTechnicianRepository(seed: seed);

    final billing = MockBillingRepository(seed: seed, auditLog: auditLog);

    final settingsData = MockSettingsData();

    return HvacAdminRepositoryBundle(

      managementAuth: managementAuth ?? MockManagementAuthService(auditLog: auditLog),

      customers: customers,

      jobs: jobs,

      technicians: technicians,

      fleet: MockFleetRepository(),

      reports: MockReportsRepository(

        jobs: jobs,

        technicians: technicians,

        billing: billing,

      ),

      billing: billing,

      communication: MockCommunicationRepository(seed: seed),

      internalMessaging: MockInternalMessagingRepository(),

      inventory: MockInventoryRepository(seed: seed),

      maintenanceAgreements: MockMaintenanceAgreementRepository(seed: seed),

      settings: MockSettingsRepository(settingsData, auditLog: auditLog),

      officePersonnel: MockOfficePersonnelRepository(settingsData),

      documentTemplates: MockDocumentTemplateRepository(

        MockDocumentTemplates.seedLibrary(),

        auditLog: auditLog,

      ),

      locations: MockTechnicianLocationRepository(),

      realtime: NoopRealtimeService(),

      messageSender: MockMessageSender(),

      translate: MockTranslateRepository(),

      portal: MockPortalRepository(),

      audit: MockAuditLogRepository(auditLog),

      secureMedia: SecureMediaAccess(LocalAdminMediaStorage()),

    );

  }



  static HvacAdminRepositoryBundle _createSupabaseBundle(SupabaseClient client, {ManagementAuthService? managementAuth}) {

    final auditWriter = SupabaseAuditLog(client);

    return HvacAdminRepositoryBundle(

      managementAuth: managementAuth ?? SupabaseManagementAuthService(client, audit: auditWriter),

      customers: SupabaseCustomerRepository(client),

      jobs: SupabaseJobRepository(client, audit: auditWriter),

      technicians: SupabaseTechnicianRepository(client),

      fleet: SupabaseFleetRepository(client),

      reports: SupabaseReportsRepository(client),

      billing: SupabaseBillingRepository(client, audit: auditWriter),

      communication: SupabaseCommunicationRepository(client),

      internalMessaging: SupabaseInternalMessagingRepository(client),

      inventory: SupabaseInventoryRepository(client),

      maintenanceAgreements: SupabaseMaintenanceAgreementRepository(client),

      settings: SupabaseSettingsRepository(client, audit: auditWriter),

      officePersonnel: SupabaseOfficePersonnelRepository(client),

      documentTemplates: SupabaseDocumentTemplateRepository(client, audit: auditWriter),

      locations: SupabaseTechnicianLocationRepository(client),

      realtime: SupabaseRealtimeService(client),

      messageSender: SupabaseMessageSender(client),

      translate: SupabaseTranslateRepository(client),

      portal: SupabasePortalRepository(client),

      audit: SupabaseAuditLogRepository(client, writer: auditWriter),

      secureMedia: SecureMediaAccess(SupabaseAdminMediaStorage(client)),

    );

  }

}

