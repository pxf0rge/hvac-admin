import 'package:hvac_admin/core/models/office_inventory.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getItems();
  Future<PagedResult<InventoryItem>> getItemsPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
  });
  Future<List<InventoryLocation>> getLocations();
  Future<List<LocationStock>> getStocks();
  Future<List<StockMovement>> getMovements({String? itemId});
  Future<InventoryItem> saveItem(InventoryItem item);
  Future<InventoryLocation> saveLocation(InventoryLocation location);
  Future<void> saveStock(LocationStock stock);
  Future<void> saveMovement(StockMovement movement);
}
