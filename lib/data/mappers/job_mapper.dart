import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';

abstract final class JobMapper {
  static HistoryJob historyFromRow(
    Map<String, dynamic> row, {
    String technicianName = '',
    String? technicianId,
  }) {
    return HistoryJob(
      id: MapperHelpers.uuid(row['id']),
      propertyId: MapperHelpers.uuid(row['property_id']),
      jobNumber: MapperHelpers.str(row['job_number']),
      type: EnumDb.jobTypeFromDb(MapperHelpers.str(row['type'])),
      status: EnumDb.jobStatusFromDb(MapperHelpers.str(row['status'])),
      priority: EnumDb.jobPriorityFromDb(MapperHelpers.str(row['priority'])),
      date: MapperHelpers.dateOnly(row['scheduled_date']),
      startTime: MapperHelpers.timeHm(row['start_time']),
      endTime: MapperHelpers.timeHm(row['end_time']),
      technicianName: technicianName,
      technicianId: technicianId ?? MapperHelpers.strOrNull(row['technician_id']),
      truckAssetId: MapperHelpers.strOrNull(row['truck_asset_id']),
      description: MapperHelpers.str(row['description']),
      notes: MapperHelpers.str(row['notes']),
      partsUsed: MapperHelpers.str(row['parts_used']),
    );
  }

  static Map<String, dynamic> historyToRow(HistoryJob job) => {
        'id': job.id,
        'property_id': job.propertyId,
        'job_number': job.jobNumber,
        'type': EnumDb.jobType(job.type),
        'status': EnumDb.jobStatus(job.status),
        'priority': EnumDb.jobPriority(job.priority),
        'scheduled_date': job.date,
        'start_time': job.startTime,
        'end_time': job.endTime,
        'description': job.description,
        'notes': job.notes,
        'parts_used': job.partsUsed,
        if (job.technicianId != null) 'technician_id': job.technicianId,
        'truck_asset_id': job.truckAssetId,
      };
}
