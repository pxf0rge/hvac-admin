import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/inventory_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_inventory.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/data/mappers/inventory_mapper.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('InventoryMapper round-trips stock enums and rows', () {
    expect(
      EnumDb.stockMovementKindFromDb(EnumDb.stockMovementKind(StockMovementKind.returnStock)),
      StockMovementKind.returnStock,
    );

    const row = {
      'id': MockSeedIds.inventoryItemId,
      'sku': 'CAP-45-5',
      'name': '45/5 Capacitor',
      'category': 'Electrical',
      'unit': 'ea',
      'min_qty': 5,
    };
    final item = InventoryMapper.itemFromRow(row);
    expect(item.minQty, 5);

    final movement = InventoryMapper.movementFromRow({
      'id': 'mv_test',
      'at': '2026-08-29T10:00:00Z',
      'item_id': item.id,
      'kind': 'assign',
      'quantity': 2,
      'from_location_id': MockSeedIds.warehouseLocationId,
      'to_location_id': MockSeedIds.fleetTruckLocationId,
      'reason': 'Truck load',
      'job_id': MockSeedIds.jobId,
    });
    expect(movement.kind, StockMovementKind.assign);
    expect(InventoryMapper.movementToRpc(movement)['p_kind'], 'assign');
  });

  test('InventoryController receive and assign update mock stock', () async {
    final repo = MockInventoryRepository(seed: MockSeedData());
    final inventory = InventoryController(repo);
    await inventory.load(force: true);

    final item = inventory.items.first;
    final warehouseBefore = inventory.warehouseQty(item.id);
    final truck = inventory.assignableLocations.first;

    await inventory.receive(itemId: item.id, quantity: 5, reason: 'Vendor delivery');
    expect(inventory.warehouseQty(item.id), warehouseBefore + 5);

    final available = inventory.warehouseQty(item.id);
    await inventory.assignToLocation(
      itemId: item.id,
      toLocationId: truck.id,
      quantity: 2,
      reason: 'Route staging',
      jobId: MockSeedIds.jobId,
    );
    expect(inventory.warehouseQty(item.id), available - 2);
    expect(inventory.quantityAt(itemId: item.id, locationId: truck.id), greaterThanOrEqualTo(2));
  });

  test('InventoryController consumeForJob decrements truck stock', () async {
    final repo = MockInventoryRepository(seed: MockSeedData());
    final inventory = InventoryController(repo);
    await inventory.load(force: true);

    final item = inventory.items.first;
    final truck = inventory.assignableLocations.first;
    final before = inventory.quantityAt(itemId: item.id, locationId: truck.id);

    await inventory.consumeForJob(
      itemId: item.id,
      fromLocationId: truck.id,
      quantity: 1,
      jobId: MockSeedIds.jobId,
      reason: 'Installed on job',
    );

    expect(inventory.quantityAt(itemId: item.id, locationId: truck.id), before - 1);
    expect(inventory.movementsForItem(item.id).first.kind, StockMovementKind.issue);
  });

  test('low stock is derived from warehouse quantity vs minimum', () async {
    final repo = MockInventoryRepository(seed: MockSeedData());
    final inventory = InventoryController(repo);
    await inventory.load(force: true);

    final item = inventory.items.first;
    expect(inventory.isLow(item), isTrue);
    expect(inventory.lowStockItems, contains(item));
  });

  test('saveItem creates catalog row', () async {
    final repo = MockInventoryRepository(seed: MockSeedData());
    final inventory = InventoryController(repo);
    await inventory.load(force: true);

    final saved = await inventory.saveItem(
      const InventoryItem(
        id: 'part_new_filter',
        sku: 'FLT-NEW',
        name: 'Test filter',
        category: 'Filters',
        unit: 'ea',
        minQty: 10,
      ),
    );
    expect(saved.sku, 'FLT-NEW');
    expect(inventory.itemById('part_new_filter'), isNotNull);
  });
}
