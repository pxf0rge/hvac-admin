import 'package:hvac_admin/core/audit/audit_actions.dart';

import 'package:hvac_admin/core/audit/audit_metadata.dart';

import 'package:hvac_admin/core/audit/audit_recording.dart';

import 'package:hvac_admin/core/audit/in_memory_audit_log.dart';

import 'package:hvac_admin/core/models/company_settings.dart';

import 'package:hvac_admin/core/models/integration_credentials.dart';

import 'package:hvac_admin/core/models/office_user.dart';

import 'package:hvac_admin/data/datasources/mock_settings_data.dart';

import 'package:hvac_admin/data/repositories/settings_repository.dart';



class MockSettingsRepository implements SettingsRepository {

  MockSettingsRepository(this._data, {InMemoryAuditLog? auditLog}) : _auditLog = auditLog;



  final MockSettingsData _data;

  final InMemoryAuditLog? _auditLog;



  @override

  Future<CompanySettings> getCompanySettings() async => _data.company;



  @override

  Future<CompanySettings> saveCompanySettings(CompanySettings settings) async {

    final before = _data.company;

    _data.company = settings;

    recordMockAudit(

      _auditLog,

      action: AuditActions.settingsUpdate,

      entityType: 'company_settings',

      entityId: '1',

      metadata: AuditMetadata.settingsChange(

        beforeCompanyName: before.companyName,

        afterCompanyName: settings.companyName,

      ),

    );

    return settings;

  }



  @override

  Future<IntegrationCredentials> getIntegrationCredentials() async => _data.integrations;



  @override

  Future<IntegrationCredentials> saveIntegrationCredentials(
    IntegrationCredentials credentials,
  ) async {
    _data.integrations = credentials;
    recordMockAudit(
      _auditLog,
      action: AuditActions.integrationsUpdate,
      entityType: 'integration_credentials',
      entityId: '1',
      metadata: AuditMetadata.integrationsChange(
        twilioConfigured: credentials.hasTwilio,
        resendConfigured: credentials.hasResend,
      ),
    );
    return credentials;
  }



  @override

  Future<List<OfficeUser>> getOfficeUsers() async => List.unmodifiable(_data.officeUsers);

}

