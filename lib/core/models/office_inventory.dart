import 'package:hvac_admin/core/enums/domain_enums.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.unit,
    required this.minQty,
  });

  final String id;
  final String sku;
  final String name;
  final String category;
  final String unit;
  final int minQty;

  InventoryItem copyWith({
    String? sku,
    String? name,
    String? category,
    String? unit,
    int? minQty,
  }) {
    return InventoryItem(
      id: id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      minQty: minQty ?? this.minQty,
    );
  }
}

class InventoryLocation {
  const InventoryLocation({
    required this.id,
    required this.kind,
    required this.name,
  });

  final String id;
  final StockLocationKind kind;
  final String name;

  InventoryLocation copyWith({StockLocationKind? kind, String? name}) {
    return InventoryLocation(
      id: id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
    );
  }
}

class LocationStock {
  const LocationStock({
    required this.locationId,
    required this.itemId,
    required this.quantity,
  });

  final String locationId;
  final String itemId;
  final int quantity;

  LocationStock copyWith({int? quantity}) {
    return LocationStock(
      locationId: locationId,
      itemId: itemId,
      quantity: quantity ?? this.quantity,
    );
  }
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.at,
    required this.itemId,
    required this.kind,
    required this.quantity,
    required this.fromLocationId,
    required this.toLocationId,
    required this.reason,
    this.jobId,
  });

  final String id;
  final String at;
  final String itemId;
  final StockMovementKind kind;
  final int quantity;
  final String fromLocationId;
  final String toLocationId;
  final String reason;
  final String? jobId;
}
