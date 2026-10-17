import 'package:hvac_admin/core/models/dashboard_snapshot.dart';
import 'package:hvac_admin/core/reports/operational_metrics_calculator.dart';

abstract class ReportsRepository {
  Future<DashboardSnapshot> loadDashboardMetrics({bool includeFinancial = true});
  Future<OperationalReportMetrics> loadOperationalMetrics();
}
