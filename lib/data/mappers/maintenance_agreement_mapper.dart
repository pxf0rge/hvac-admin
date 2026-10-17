import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/maintenance_agreement.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';

abstract final class MaintenanceAgreementMapper {
  static MaintenanceAgreement fromRow(
    Map<String, dynamic> row, {
    double? annualAmount,
  }) {
    return MaintenanceAgreement(
      id: MapperHelpers.uuid(row['id']),
      customerId: MapperHelpers.uuid(row['customer_id']),
      propertyId: MapperHelpers.uuid(row['property_id']),
      title: MapperHelpers.str(row['title']),
      status: EnumDb.maintenanceAgreementStatusFromDb(MapperHelpers.str(row['status'])),
      frequency: EnumDb.maintenanceAgreementFrequencyFromDb(MapperHelpers.str(row['frequency'])),
      startOn: MapperHelpers.dateOnly(row['start_on']),
      endOn: MapperHelpers.dateOnly(row['end_on']),
      nextServiceOn: MapperHelpers.strOrNull(row['next_service_on']) == null
          ? null
          : MapperHelpers.dateOnly(row['next_service_on']),
      renewalReminderOn: MapperHelpers.dateOnly(row['renewal_reminder_on']),
      annualAmount: annualAmount,
      notes: MapperHelpers.str(row['notes']),
    );
  }

  static Map<String, dynamic> toRow(MaintenanceAgreement agreement) => {
        if (MapperHelpers.isUuid(agreement.id)) 'id': agreement.id,
        'customer_id': agreement.customerId,
        'property_id': agreement.propertyId,
        'title': agreement.title,
        'status': EnumDb.maintenanceAgreementStatus(agreement.status),
        'frequency': EnumDb.maintenanceAgreementFrequency(agreement.frequency),
        'start_on': agreement.startOn,
        'end_on': agreement.endOn,
        if (agreement.nextServiceOn != null) 'next_service_on': agreement.nextServiceOn,
        'renewal_reminder_on': agreement.renewalReminderOn,
        'notes': agreement.notes,
      };
}
