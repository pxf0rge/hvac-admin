import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/tracking/technician_location_fix.dart';
import 'package:hvac_admin/data/repositories/technician_location_repository.dart';

class GpsMapController extends ChangeNotifier {
  GpsMapController(this._locations);

  final TechnicianLocationRepository _locations;
  final Map<String, List<TechnicianLocationFix>> _historyByTechnician = {};

  Future<void> loadHistory(String technicianId) async {
    try {
      _historyByTechnician[technicianId] = await _locations.historyFor(technicianId);
      notifyListeners();
    } catch (error, stack) {
      debugPrint('GpsMapController.loadHistory failed: $error\n$stack');
    }
  }

  List<TechnicianLocationFix> historyFor(String technicianId) =>
      List.unmodifiable(_historyByTechnician[technicianId] ?? const []);

  Future<void> refreshLocationHistoryIfLoaded(String technicianId) async {
    if (!_historyByTechnician.containsKey(technicianId)) return;
    await loadHistory(technicianId);
  }
}
