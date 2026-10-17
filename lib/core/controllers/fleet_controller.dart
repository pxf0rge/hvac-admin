import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/fleet_asset.dart';
import 'package:hvac_admin/data/repositories/fleet_repository.dart';

class FleetController extends ChangeNotifier {
  FleetController(this._repository);

  final FleetRepository _repository;
  bool _loading = false;
  String? _loadError;
  List<FleetAsset> _assets = const [];
  final Map<String, List<FleetAssignment>> _historyByAsset = {};
  int _refreshToken = 0;

  bool get isLoading => _loading;
  String? get loadError => _loadError;
  List<FleetAsset> get assets => List.unmodifiable(_assets);
  int get refreshToken => _refreshToken;

  FleetAsset? assetById(String id) {
    for (final asset in _assets) {
      if (asset.id == id) return asset;
    }
    return null;
  }

  List<FleetAsset> assetsFor({String? query, FleetAssetKind? kind, bool activeOnly = true}) {
    final needle = query?.trim().toLowerCase() ?? '';
    return [
      for (final asset in _assets)
        if ((!activeOnly || asset.isActive) &&
            (kind == null || asset.kind == kind) &&
            (needle.isEmpty ||
                asset.label.toLowerCase().contains(needle) ||
                asset.identifier.toLowerCase().contains(needle)))
          asset,
    ];
  }

  List<FleetAsset> assetsForTechnician(String technicianId) {
    return [
      for (final asset in _assets)
        if (asset.currentTechnicianId == technicianId) asset,
    ];
  }

  /// Active trucks with the job technician's assigned trucks listed first.
  List<FleetAsset> truckOptionsForJob({String? technicianId}) {
    final trucks = assetsFor(kind: FleetAssetKind.truck, activeOnly: true);
    if (technicianId == null || technicianId.isEmpty) return trucks;
    return [
      for (final truck in trucks)
        if (truck.currentTechnicianId == technicianId) truck,
      for (final truck in trucks)
        if (truck.currentTechnicianId != technicianId) truck,
    ];
  }

  List<FleetAssignment> historyFor(String fleetAssetId) =>
      List.unmodifiable(_historyByAsset[fleetAssetId] ?? const []);

  FleetAsset? assetForInventoryLocation(String locationId) {
    for (final asset in _assets) {
      if (asset.inventoryLocationId == locationId) return asset;
    }
    return null;
  }

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (!force && _assets.isNotEmpty && _loadError == null) return;
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      _assets = [...await _repository.getAssets()];
    } catch (error, stack) {
      _loadError = error.toString();
      debugPrint('FleetController.load failed: $error\n$stack');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory(String fleetAssetId) async {
    _historyByAsset[fleetAssetId] = await _repository.getAssignmentHistory(fleetAssetId);
    notifyListeners();
  }

  Future<FleetAsset> saveAsset(FleetAsset asset) async {
    final saved = await _repository.saveAsset(asset);
    _replaceAsset(saved);
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  Future<FleetAsset> assignAsset({
    required String fleetAssetId,
    required String technicianId,
    String notes = '',
  }) async {
    final saved = await _repository.assignAsset(
      fleetAssetId: fleetAssetId,
      technicianId: technicianId,
      notes: notes,
    );
    _replaceAsset(saved);
    await loadHistory(fleetAssetId);
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  Future<FleetAsset> unassignAsset({required String fleetAssetId, String notes = ''}) async {
    final saved = await _repository.unassignAsset(fleetAssetId: fleetAssetId, notes: notes);
    _replaceAsset(saved);
    await loadHistory(fleetAssetId);
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  void _replaceAsset(FleetAsset saved) {
    final index = _assets.indexWhere((item) => item.id == saved.id);
    if (index < 0) {
      _assets = [..._assets, saved];
    } else {
      final copy = [..._assets];
      copy[index] = saved;
      _assets = copy;
    }
  }
}
