import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/reports_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_job.dart';
import 'package:hvac_admin/core/reports/operational_metrics_calculator.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_reports_repository.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('OperationalMetricsCalculator derives duration and on-time from history', () {
    final scheduled = DateTime(2026, 8, 29, 9, 0);
    final arrived = scheduled.add(const Duration(minutes: 10));
    final completed = arrived.add(const Duration(minutes: 45));

    final metrics = OperationalMetricsCalculator.compute(
      jobs: [
        JobReportInput(
          id: 'job_1',
          type: JobType.diagnostic,
          status: JobStatus.completed,
          technicianId: MockSeedIds.technicianId,
          technicianName: 'Carlos Rodriguez',
          scheduledDate: '2026-08-29',
          startTime: '09:00',
          history: [
            JobStatusEvent(at: completed.toIso8601String(), kind: JobActivityKind.jobCompleted),
            JobStatusEvent(at: arrived.toIso8601String(), kind: JobActivityKind.arrived),
          ],
        ),
      ],
      technicians: const [],
    );

    expect(metrics.jobsCompleted, 1);
    expect(metrics.jobsWithHistory, 1);
    expect(metrics.technicians.single.completed, 1);
    expect(metrics.technicians.single.avgMinutesOnSite, 45);
    expect(metrics.technicians.single.onTimePercent, 100);
  });

  test('ReportsController uses billing invoices and operational repository', () async {
    final seed = MockSeedData();
    final jobs = MockJobRepository(seed: seed);
    final technicians = MockTechnicianRepository(seed: seed);
    final billing = MockBillingRepository(seed: seed);
    final reportsRepo = MockReportsRepository(jobs: jobs, technicians: technicians, billing: billing, seed: seed);
    final controller = ReportsController(billing, reportsRepo);

    await controller.load(force: true);
    final snap = controller.snapshot;

    expect(snap.hasFinancialData, isTrue);
    expect(snap.hasOperationalData, isTrue);
    expect(snap.outstanding, greaterThan(0));
    expect(snap.jobsTotal, greaterThan(0));
    expect(snap.technicians.any((row) => row.name.contains('Carlos')), isTrue);
    expect(snap.invoices, isNotEmpty);
  });
}
