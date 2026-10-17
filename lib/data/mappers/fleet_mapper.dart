import 'package:hvac_admin/core/models/fleet_asset.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';

abstract final class FleetMapper {
  static FleetAsset assetFromRow(Map<String, dynamic> row) {
    return FleetAsset(
      id: MapperHelpers.uuid(row['id']),
      kind: EnumDb.fleetAssetKindFromDb(MapperHelpers.str(row['kind'])),
      label: MapperHelpers.str(row['label']),
      identifier: MapperHelpers.str(row['identifier']),
      inventoryLocationId: MapperHelpers.strOrNull(row['inventory_location_id']),
      currentTechnicianId: MapperHelpers.strOrNull(row['current_technician_id']),
      isActive: row['is_active'] != false,
    );
  }

  static Map<String, dynamic> assetToRow(FleetAsset asset) => {
        if (MapperHelpers.isUuid(asset.id)) 'id': asset.id,
        'kind': EnumDb.fleetAssetKind(asset.kind),
        'label': asset.label.trim(),
        'identifier': asset.identifier.trim(),
        if (asset.inventoryLocationId != null && MapperHelpers.isUuid(asset.inventoryLocationId!))
          'inventory_location_id': asset.inventoryLocationId,
        if (asset.currentTechnicianId != null && MapperHelpers.isUuid(asset.currentTechnicianId!))
          'current_technician_id': asset.currentTechnicianId,
        'is_active': asset.isActive,
      };

  static FleetAssignment assignmentFromRow(Map<String, dynamic> row) {
    return FleetAssignment(
      id: MapperHelpers.uuid(row['id']),
      fleetAssetId: MapperHelpers.uuid(row['fleet_asset_id']),
      technicianId: MapperHelpers.uuid(row['technician_id']),
      assignedAt: MapperHelpers.isoTimestamp(row['assigned_at']),
      unassignedAt: MapperHelpers.strOrNull(row['unassigned_at']) == null
          ? null
          : MapperHelpers.isoTimestamp(row['unassigned_at']),
      notes: MapperHelpers.str(row['notes']),
    );
  }
}
