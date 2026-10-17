import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_reports_repository.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('MockReportsRepository aggregates dashboard metrics from seed data', () async {
    final seed = MockSeedData();
    final jobs = MockJobRepository(seed: seed);
    final technicians = MockTechnicianRepository(seed: seed);
    final billing = MockBillingRepository(seed: seed);
    final repo = MockReportsRepository(
      jobs: jobs,
      technicians: technicians,
      billing: billing,
      seed: seed,
    );

    final snap = await repo.loadDashboardMetrics(includeFinancial: true);
    final today = isoDate(DateTime.now());

    expect(snap.todaysJobs, greaterThanOrEqualTo(1));
    expect(snap.unassignedJobs, greaterThanOrEqualTo(1));
    expect(snap.activeTechnicians, 2);
    expect(snap.openEstimates, 1);
    expect(snap.overdueInvoiceCount, 1);
    expect(snap.overdueInvoiceTotal, 420);
    expect(snap.jobsTotal, seed.jobs.length);
    expect(snap.recentActivity, isNotEmpty);
    expect(snap.hasOperationalData, isTrue);
    expect(snap.hasFinancialData, isTrue);

    final financialOff = await repo.loadDashboardMetrics(includeFinancial: false);
    expect(financialOff.openEstimates, 0);
    expect(financialOff.overdueInvoiceCount, 0);
    expect(financialOff.hasFinancialData, isFalse);

    expect(seed.jobs.any((job) => job.date == today), isTrue);
  });
}
