import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_inventory.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';
import 'package:hvac_admin/data/repositories/inventory_repository.dart';

class InventoryController extends ChangeNotifier {
  InventoryController(this._repository);

  final InventoryRepository _repository;
  bool _loading = false;
  List<InventoryItem> _items = const [];
  List<InventoryLocation> _locations = const [];
  List<LocationStock> _stocks = const [];
  List<StockMovement> _movements = const [];
  int _nextMovement = 100;
  int _refreshToken = 0;

  bool get isLoading => _loading;
  int get refreshToken => _refreshToken;
  List<InventoryItem> get items => List.unmodifiable(_items);
  List<InventoryLocation> get locations => List.unmodifiable(_locations);
  List<StockMovement> get movements => List.unmodifiable(_movements);

  InventoryItem? itemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  InventoryLocation? locationById(String id) {
    for (final location in _locations) {
      if (location.id == id) return location;
    }
    return null;
  }

  InventoryLocation get warehouse {
    for (final location in _locations) {
      if (location.kind == StockLocationKind.warehouse) return location;
    }
    throw StateError('No warehouse location configured');
  }

  List<InventoryLocation> get assignableLocations => [
        for (final location in _locations)
          if (location.kind == StockLocationKind.truck || location.kind == StockLocationKind.device)
            location,
      ];

  List<InventoryItem> get lowStockItems => [for (final item in _items) if (isLow(item)) item];

  int quantityAt({required String itemId, required String locationId}) {
    for (final stock in _stocks) {
      if (stock.itemId == itemId && stock.locationId == locationId) return stock.quantity;
    }
    return 0;
  }

  int warehouseQty(String itemId) => quantityAt(itemId: itemId, locationId: warehouse.id);

  int assignedQty(String itemId) {
    var total = 0;
    for (final location in assignableLocations) {
      total += quantityAt(itemId: itemId, locationId: location.id);
    }
    return total;
  }

  int totalQty(String itemId) => warehouseQty(itemId) + assignedQty(itemId);

  bool isLow(InventoryItem item) => warehouseQty(item.id) < item.minQty;

  List<StockMovement> movementsForItem(String itemId) {
    return [for (final movement in _movements) if (movement.itemId == itemId) movement];
  }

  Future<void> load({bool force = false}) async {
    if (!force && _items.isNotEmpty) return;
    _loading = true;
    notifyListeners();
    try {
      _items = [...await _repository.getItems()];
      _locations = [...await _repository.getLocations()];
      await _ensureDefaultLocations();
      _stocks = [...await _repository.getStocks()];
      _movements = [...await _repository.getMovements()];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<InventoryItem> saveItem(InventoryItem item) async {
    final saved = await _repository.saveItem(item);
    final index = _items.indexWhere((entry) => entry.id == saved.id);
    if (index < 0) {
      _items = [saved, ..._items];
    } else {
      final copy = [..._items];
      copy[index] = saved;
      _items = copy;
    }
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  Future<InventoryLocation> saveLocation(InventoryLocation location) async {
    final saved = await _repository.saveLocation(location);
    final index = _locations.indexWhere((entry) => entry.id == saved.id);
    if (index < 0) {
      _locations = [..._locations, saved];
    } else {
      final copy = [..._locations];
      copy[index] = saved;
      _locations = copy;
    }
    notifyListeners();
    return saved;
  }

  Future<void> receive({required String itemId, required int quantity, required String reason}) async {
    if (quantity <= 0) return;
    final wh = warehouse.id;
    await _setQty(itemId: itemId, locationId: wh, quantity: warehouseQty(itemId) + quantity);
    await _addMovement(
      StockMovement(
        id: 'mv_${_nextMovement++}',
        at: DateTime.now().toIso8601String(),
        itemId: itemId,
        kind: StockMovementKind.receive,
        quantity: quantity,
        fromLocationId: wh,
        toLocationId: wh,
        reason: reason,
      ),
    );
  }

  Future<void> assignToLocation({
    required String itemId,
    required String toLocationId,
    required int quantity,
    required String reason,
    String? jobId,
  }) async {
    if (quantity <= 0) return;
    final wh = warehouse.id;
    final available = warehouseQty(itemId);
    if (quantity > available) return;
    final target = locationById(toLocationId);
    if (target == null || target.kind == StockLocationKind.warehouse) return;

    await _setQty(itemId: itemId, locationId: wh, quantity: available - quantity);
    await _setQty(
      itemId: itemId,
      locationId: toLocationId,
      quantity: quantityAt(itemId: itemId, locationId: toLocationId) + quantity,
    );
    await _addMovement(
      StockMovement(
        id: 'mv_${_nextMovement++}',
        at: DateTime.now().toIso8601String(),
        itemId: itemId,
        kind: StockMovementKind.assign,
        quantity: quantity,
        fromLocationId: wh,
        toLocationId: toLocationId,
        reason: reason,
        jobId: jobId,
      ),
    );
  }

  Future<void> transferBetweenLocations({
    required String itemId,
    required String fromLocationId,
    required String toLocationId,
    required int quantity,
    required String reason,
  }) async {
    if (quantity <= 0 || fromLocationId == toLocationId) return;
    final available = quantityAt(itemId: itemId, locationId: fromLocationId);
    if (quantity > available) return;

    await _setQty(itemId: itemId, locationId: fromLocationId, quantity: available - quantity);
    await _setQty(
      itemId: itemId,
      locationId: toLocationId,
      quantity: quantityAt(itemId: itemId, locationId: toLocationId) + quantity,
    );
    await _addMovement(
      StockMovement(
        id: 'mv_${_nextMovement++}',
        at: DateTime.now().toIso8601String(),
        itemId: itemId,
        kind: StockMovementKind.returnStock,
        quantity: quantity,
        fromLocationId: fromLocationId,
        toLocationId: toLocationId,
        reason: reason,
      ),
    );
  }

  Future<void> consumeForJob({
    required String itemId,
    required String fromLocationId,
    required int quantity,
    required String jobId,
    required String reason,
  }) async {
    if (quantity <= 0) return;
    final available = quantityAt(itemId: itemId, locationId: fromLocationId);
    if (quantity > available) return;

    await _setQty(itemId: itemId, locationId: fromLocationId, quantity: available - quantity);
    await _addMovement(
      StockMovement(
        id: 'mv_${_nextMovement++}',
        at: DateTime.now().toIso8601String(),
        itemId: itemId,
        kind: StockMovementKind.issue,
        quantity: quantity,
        fromLocationId: fromLocationId,
        toLocationId: fromLocationId,
        reason: reason,
        jobId: jobId,
      ),
    );
  }

  Future<PagedResult<InventoryItem>> fetchItemsPage({required int offset, String? search}) {
    return _repository.getItemsPage(offset: offset, search: _cleanSearch(search));
  }

  Future<void> _ensureDefaultLocations() async {
    var locations = [..._locations];

    if (!locations.any((location) => location.kind == StockLocationKind.warehouse)) {
      final created = await _repository.saveLocation(
        const InventoryLocation(id: '', kind: StockLocationKind.warehouse, name: 'Main warehouse'),
      );
      locations = [created, ...locations];
    }

    if (!locations.any((location) => location.kind == StockLocationKind.truck)) {
      final created = await _repository.saveLocation(
        const InventoryLocation(id: '', kind: StockLocationKind.truck, name: 'Service truck'),
      );
      locations = [...locations, created];
    }

    _locations = locations;
  }

  Future<void> _setQty({required String itemId, required String locationId, required int quantity}) async {
    final next = LocationStock(locationId: locationId, itemId: itemId, quantity: quantity);
    await _repository.saveStock(next);
    final index = _stocks.indexWhere((stock) => stock.locationId == locationId && stock.itemId == itemId);
    if (index < 0) {
      _stocks = [..._stocks, next];
    } else {
      final copy = [..._stocks];
      copy[index] = next;
      _stocks = copy;
    }
    _refreshToken += 1;
    notifyListeners();
  }

  Future<void> _addMovement(StockMovement movement) async {
    await _repository.saveMovement(movement);
    _movements = [movement, ..._movements];
    notifyListeners();
  }

  String? _cleanSearch(String? search) {
    final trimmed = search?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
