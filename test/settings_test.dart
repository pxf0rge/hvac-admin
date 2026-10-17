import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/settings_controller.dart';
import 'package:hvac_admin/core/models/company_settings.dart';
import 'package:hvac_admin/core/models/integration_credentials.dart';
import 'package:hvac_admin/data/datasources/mock_settings_data.dart';
import 'package:hvac_admin/data/mappers/company_settings_mapper.dart';
import 'package:hvac_admin/data/repositories/mock_settings_repository.dart';

void main() {
  test('CompanySettingsMapper round-trips row fields', () {
    const settings = CompanySettings(
      companyName: 'Arctic HVAC Solutions',
      phone: '(217) 555-0100',
      addressLine: '1200 Commerce Blvd',
      city: 'Springfield',
      state: 'IL',
      zip: '62704',
      logoStoragePath: 'documents/logo.png',
      gpsWorkdayStartMinutes: 8 * 60,
      gpsWorkdayEndMinutes: 17 * 60,
      gpsTimezone: 'America/Chicago',
      gpsTimezoneNote: 'Central Time',
    );
    final row = CompanySettingsMapper.toRow(settings);
    final parsed = CompanySettingsMapper.fromRow(row);
    expect(parsed.companyName, settings.companyName);
    expect(parsed.phone, settings.phone);
    expect(parsed.formattedAddress, contains('Springfield'));
    expect(parsed.documentVariables['company_name'], 'Arctic HVAC Solutions');
    expect(parsed.gpsWorkdayStartMinutes, 8 * 60);
    expect(parsed.gpsWorkdayEndMinutes, 17 * 60);
    expect(parsed.gpsTimezone, 'America/Chicago');
  });

  test('CompanySettings rejects invalid GPS window', () {
    expect(
      CompanySettings.validateGpsHours(startMinutes: 18 * 60, endMinutes: 7 * 60),
      isNotNull,
    );
    expect(
      CompanySettings.validateGpsHours(startMinutes: 7 * 60, endMinutes: 18 * 60),
      isNull,
    );
    final bad = const CompanySettings(
      companyName: 'X',
      phone: '',
      addressLine: '',
      city: '',
      state: '',
      zip: '',
      gpsWorkdayStartMinutes: 20 * 60,
      gpsWorkdayEndMinutes: 8 * 60,
    );
    expect(bad.normalizedGpsWindow.$1, CompanySettings.defaultGpsStartMinutes);
    expect(bad.normalizedGpsWindow.$2, CompanySettings.defaultGpsEndMinutes);
  });

  test('MockSettingsRepository persists company settings', () async {
    final data = MockSettingsData();
    final repo = MockSettingsRepository(data);
    final saved = await repo.saveCompanySettings(
      data.company.copyWith(companyName: 'Updated HVAC'),
    );
    expect(saved.companyName, 'Updated HVAC');
    expect((await repo.getCompanySettings()).companyName, 'Updated HVAC');
  });

  test('SettingsController blocks save when canEdit is false', () async {
    final controller = SettingsController(MockSettingsRepository(MockSettingsData()));
    await controller.load();
    final before = controller.company!.companyName;
    final ok = await controller.saveCompany(
      controller.company!.copyWith(companyName: 'Blocked'),
      canEdit: false,
    );
    expect(ok, isFalse);
    expect(controller.company!.companyName, before);
  });

  test('SettingsController loads office users', () async {
    final controller = SettingsController(MockSettingsRepository(MockSettingsData()));
    await controller.load();
    expect(controller.officeUsers.length, 3);
    expect(controller.officeUsers.any((user) => user.email == 'diana@hvacpro.com'), isTrue);
    expect(controller.documentVariables['company_name'], isNotEmpty);
  });

  test('SettingsController persists integration credentials', () async {
    final controller = SettingsController(MockSettingsRepository(MockSettingsData()));
    await controller.load();
    expect(controller.integrations?.hasTwilio, isFalse);

    final ok = await controller.saveIntegrations(
      const IntegrationCredentials(
        twilioAccountSid: 'ACtest',
        twilioAuthToken: 'token',
        twilioFromNumber: '+15551234567',
        resendApiKey: 're_test',
        resendFromEmail: 'onboarding@resend.dev',
      ),
      canEdit: true,
    );
    expect(ok, isTrue);
    expect(controller.integrations?.hasTwilio, isTrue);
    expect(controller.integrations?.hasResend, isTrue);
  });
}
