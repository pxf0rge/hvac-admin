import 'package:hvac_admin/core/models/company_settings.dart';
import 'package:hvac_admin/core/models/integration_credentials.dart';
import 'package:hvac_admin/core/models/office_user.dart';

abstract class SettingsRepository {
  Future<CompanySettings> getCompanySettings();
  Future<CompanySettings> saveCompanySettings(CompanySettings settings);
  Future<IntegrationCredentials> getIntegrationCredentials();
  Future<IntegrationCredentials> saveIntegrationCredentials(IntegrationCredentials credentials);
  Future<List<OfficeUser>> getOfficeUsers();
}
