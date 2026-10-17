import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/models/dashboard_snapshot.dart';
import 'package:hvac_admin/data/repositories/reports_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this._reports);

  final ReportsRepository _reports;

  DashboardSnapshot _snapshot = DashboardSnapshot.empty;
  bool _loading = false;
  String? _error;

  DashboardSnapshot get snapshot => _snapshot;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasData => _snapshot.hasOperationalData || _snapshot.hasFinancialData;

  Future<void> load({bool includeFinancial = true, bool force = false}) async {
    if (_loading) return;
    if (!force && hasData && _error == null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _snapshot = await _reports.loadDashboardMetrics(includeFinancial: includeFinancial);
    } catch (error, stack) {
      debugPrint('DashboardController.load failed: $error\n$stack');
      _error = 'Could not load dashboard metrics.';
      _snapshot = DashboardSnapshot.empty;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
