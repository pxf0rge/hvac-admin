import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/dashboard_controller.dart';
import 'package:hvac_admin/core/models/dashboard_snapshot.dart';
import 'package:hvac_admin/core/reports/operational_metrics_calculator.dart';
import 'package:hvac_admin/data/repositories/reports_repository.dart';

class _FakeReportsRepository implements ReportsRepository {
  _FakeReportsRepository(this.snapshot, {this.throws = false});

  final DashboardSnapshot snapshot;
  final bool throws;
  var callCount = 0;
  var lastIncludeFinancial = true;

  @override
  Future<DashboardSnapshot> loadDashboardMetrics({bool includeFinancial = true}) async {
    callCount += 1;
    lastIncludeFinancial = includeFinancial;
    if (throws) throw StateError('network');
    return snapshot;
  }

  @override
  Future<OperationalReportMetrics> loadOperationalMetrics() async => OperationalReportMetrics.empty;
}

void main() {
  test('DashboardController loads metrics and caches until forced', () async {
    final repo = _FakeReportsRepository(
      const DashboardSnapshot(
        todaysJobs: 2,
        unassignedJobs: 1,
        activeTechnicians: 3,
        openEstimates: 4,
        overdueInvoiceCount: 1,
        overdueInvoiceTotal: 420,
        jobsCompleted: 5,
        jobsOpen: 2,
        jobsTotal: 7,
        recentActivity: [],
        hasOperationalData: true,
        hasFinancialData: true,
      ),
    );
    final controller = DashboardController(repo);

    await controller.load(includeFinancial: true);
    expect(controller.snapshot.todaysJobs, 2);
    expect(repo.callCount, 1);

    await controller.load(includeFinancial: true);
    expect(repo.callCount, 1);

    await controller.load(includeFinancial: true, force: true);
    expect(repo.callCount, 2);
  });

  test('DashboardController surfaces errors', () async {
    final repo = _FakeReportsRepository(DashboardSnapshot.empty, throws: true);
    final controller = DashboardController(repo);

    await controller.load(includeFinancial: false);
    expect(controller.error, isNotNull);
    expect(controller.snapshot.todaysJobs, 0);
  });
}
