import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';

abstract final class PropertyMapper {
  static OfficeProperty fromRow(Map<String, dynamic> row) {
    return OfficeProperty(
      id: MapperHelpers.uuid(row['id']),
      customerId: MapperHelpers.uuid(row['customer_id']),
      address: MapperHelpers.str(row['address']),
      city: MapperHelpers.str(row['city']),
      state: MapperHelpers.str(row['state']),
      zip: MapperHelpers.str(row['zip']),
      type: EnumDb.propertyTypeFromDb(MapperHelpers.str(row['type'])),
      label: MapperHelpers.strOrNull(row['label']),
      latitude: MapperHelpers.dblOrNull(row['latitude']),
      longitude: MapperHelpers.dblOrNull(row['longitude']),
    );
  }

  static Map<String, dynamic> toRow(OfficeProperty property) => {
        'id': property.id,
        'customer_id': property.customerId,
        'address': property.address,
        'city': property.city,
        'state': property.state,
        'zip': property.zip,
        'type': EnumDb.propertyType(property.type),
        if (property.label != null) 'label': property.label,
        if (property.latitude != null) 'latitude': property.latitude,
        if (property.longitude != null) 'longitude': property.longitude,
      };
}

abstract final class TechnicianMapper {
  static OfficeTechnician fromRow(Map<String, dynamic> row) {
    return OfficeTechnician(
      id: MapperHelpers.uuid(row['id']),
      firstName: MapperHelpers.str(row['first_name']),
      lastName: MapperHelpers.str(row['last_name']),
      status: EnumDb.technicianStatusFromDb(MapperHelpers.str(row['status'])),
      latitude: MapperHelpers.dbl(row['latitude']),
      longitude: MapperHelpers.dbl(row['longitude']),
      lastAddress: MapperHelpers.str(row['last_address']),
      lastUpdated: MapperHelpers.isoTimestamp(row['last_updated']),
      profileId: MapperHelpers.strOrNull(row['profile_id']),
      phone: MapperHelpers.str(row['phone']),
      email: MapperHelpers.strOrNull(row['profile_email']) ?? MapperHelpers.str(row['email']),
      accountEnabled: row['account_enabled'] != false,
    );
  }

  static Map<String, dynamic> toRow(OfficeTechnician technician) => {
        if (technician.id.isNotEmpty) 'id': technician.id,
        'first_name': technician.firstName,
        'last_name': technician.lastName,
        'status': EnumDb.technicianStatus(technician.status),
        'latitude': technician.latitude,
        'longitude': technician.longitude,
        'last_address': technician.lastAddress,
        'last_updated': technician.lastUpdated,
        'phone': technician.phone,
        'account_enabled': technician.accountEnabled,
        if (technician.profileId != null) 'profile_id': technician.profileId,
      };
}
