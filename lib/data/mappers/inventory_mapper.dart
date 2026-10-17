import 'package:hvac_admin/core/models/office_inventory.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';

abstract final class InventoryMapper {
  static InventoryItem itemFromRow(Map<String, dynamic> row) {
    return InventoryItem(
      id: MapperHelpers.uuid(row['id']),
      sku: MapperHelpers.str(row['sku']),
      name: MapperHelpers.str(row['name']),
      category: MapperHelpers.str(row['category']),
      unit: MapperHelpers.str(row['unit'], fallback: 'ea'),
      minQty: MapperHelpers.intOrNull(row['min_qty']) ?? 0,
    );
  }

  static Map<String, dynamic> itemToRow(InventoryItem item) => {
        if (MapperHelpers.isUuid(item.id)) 'id': item.id,
        'sku': item.sku,
        'name': item.name,
        'category': item.category,
        'unit': item.unit,
        'min_qty': item.minQty,
      };

  static InventoryLocation locationFromRow(Map<String, dynamic> row) {
    return InventoryLocation(
      id: MapperHelpers.uuid(row['id']),
      kind: EnumDb.stockLocationKindFromDb(MapperHelpers.str(row['kind'])),
      name: MapperHelpers.str(row['name']),
    );
  }

  static Map<String, dynamic> locationToRow(InventoryLocation location) => {
        if (MapperHelpers.isUuid(location.id)) 'id': location.id,
        'kind': EnumDb.stockLocationKind(location.kind),
        'name': location.name,
      };

  static LocationStock stockFromRow(Map<String, dynamic> row) {
    return LocationStock(
      locationId: MapperHelpers.uuid(row['location_id']),
      itemId: MapperHelpers.uuid(row['item_id']),
      quantity: MapperHelpers.intOrNull(row['quantity']) ?? 0,
    );
  }

  static Map<String, dynamic> stockToRow(LocationStock stock) => {
        'location_id': stock.locationId,
        'item_id': stock.itemId,
        'quantity': stock.quantity,
      };

  static StockMovement movementFromRow(Map<String, dynamic> row) {
    return StockMovement(
      id: MapperHelpers.uuid(row['id']),
      at: MapperHelpers.isoTimestamp(row['at']),
      itemId: MapperHelpers.uuid(row['item_id']),
      kind: EnumDb.stockMovementKindFromDb(MapperHelpers.str(row['kind'])),
      quantity: MapperHelpers.intOrNull(row['quantity']) ?? 0,
      fromLocationId: MapperHelpers.uuid(row['from_location_id']),
      toLocationId: MapperHelpers.uuid(row['to_location_id']),
      reason: MapperHelpers.str(row['reason']),
      jobId: MapperHelpers.strOrNull(row['job_id']),
    );
  }

  static Map<String, dynamic> movementToRow(StockMovement movement) => {
        if (MapperHelpers.isUuid(movement.id)) 'id': movement.id,
        'at': movement.at,
        'item_id': movement.itemId,
        'kind': EnumDb.stockMovementKind(movement.kind),
        'quantity': movement.quantity,
        'from_location_id': movement.fromLocationId,
        'to_location_id': movement.toLocationId,
        'reason': movement.reason,
        if (movement.jobId != null) 'job_id': movement.jobId,
      };

  static Map<String, dynamic> movementToRpc(StockMovement movement) => {
        'p_item_id': movement.itemId,
        'p_kind': EnumDb.stockMovementKind(movement.kind),
        'p_quantity': movement.quantity,
        'p_from_location_id': movement.fromLocationId,
        'p_to_location_id': movement.toLocationId,
        'p_reason': movement.reason,
        if (movement.jobId != null && MapperHelpers.isUuid(movement.jobId!))
          'p_job_id': movement.jobId,
      };
}
