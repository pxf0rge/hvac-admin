import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';

abstract final class CustomerMapper {
  static OfficeCustomer fromRow(Map<String, dynamic> row) {
    return OfficeCustomer(
      id: MapperHelpers.uuid(row['id']),
      firstName: MapperHelpers.str(row['first_name']),
      lastName: MapperHelpers.str(row['last_name']),
      phone: MapperHelpers.str(row['phone']),
      email: MapperHelpers.str(row['email']),
      city: MapperHelpers.str(row['city']),
      state: MapperHelpers.str(row['state']),
      preferredLanguage: PreferredLanguageX.fromCode(MapperHelpers.str(row['preferred_language'])),
    );
  }

  static Map<String, dynamic> toRow(OfficeCustomer customer) => {
        'id': customer.id,
        'first_name': customer.firstName,
        'last_name': customer.lastName,
        'phone': customer.phone,
        'email': customer.email,
        'city': customer.city,
        'state': customer.state,
        'preferred_language': customer.preferredLanguage.code,
      };
}
