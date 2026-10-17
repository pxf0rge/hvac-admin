import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/models/company_settings.dart';
import 'package:hvac_admin/core/models/integration_credentials.dart';
import 'package:hvac_admin/core/models/office_user.dart';

class MockSettingsData {
  MockSettingsData() {
    company = CompanySettings.defaults().copyWith(
      companyName: 'Arctic HVAC Solutions',
      phone: '(217) 555-0100',
      addressLine: '1200 Commerce Blvd',
      city: 'Springfield',
      state: 'IL',
      zip: '62704',
    );
    integrations = IntegrationCredentials.empty();
  }

  late CompanySettings company;
  late IntegrationCredentials integrations;

  List<OfficeUser> officeUsers = [
    const OfficeUser(
      id: 'mgr_owner_1',
      firstName: 'Diana',
      lastName: 'Walsh',
      email: 'diana@hvacpro.com',
      role: UserRole.owner,
    ),
    const OfficeUser(
      id: 'mgr_staff_1',
      firstName: 'Marcus',
      lastName: 'Bennett',
      email: 'marcus@hvacpro.com',
      role: UserRole.officeStaff,
    ),
    const OfficeUser(
      id: 'mgr_admin_1',
      firstName: 'Alex',
      lastName: 'Rivera',
      email: 'alex@hvacpro.com',
      role: UserRole.admin,
    ),
  ];
}
