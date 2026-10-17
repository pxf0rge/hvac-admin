import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_job.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('MockJobRepository creates job and records status history', () async {
    final seed = MockSeedData();
    final repo = MockJobRepository(seed: seed);
    final created = await repo.createJob(
      propertyId: MockSeedIds.propertyId,
      type: JobType.diagnostic,
      date: '2026-09-01',
      startTime: '10:00',
      endTime: '12:00',
      description: 'No cooling',
    );

    expect(created.status, JobStatus.unassigned);
    expect(seed.jobs.any((job) => job.id == created.id), isTrue);

    final detail = await repo.getJobDetail(created.id);
    expect(detail.statusHistory, isNotEmpty);
    expect(detail.statusHistory.first.kind, JobActivityKind.scheduled);

    final page = await repo.getJobsPage(search: created.jobNumber);
    expect(page.items.any((job) => job.id == created.id), isTrue);
  });

  test('MockJobRepository cancels open job', () async {
    final seed = MockSeedData();
    final repo = MockJobRepository(seed: seed);
    final created = await repo.createJob(
      propertyId: MockSeedIds.propertyId,
      type: JobType.acNotCooling,
      date: '2026-09-02',
      startTime: '08:00',
      endTime: '10:00',
    );

    final cancelled = await repo.cancelJob(created.id);
    expect(cancelled.status, JobStatus.cancelled);
    expect(cancelled.isOpen, isFalse);
  });

  test('JobController caches created jobs', () async {
    final seed = MockSeedData();
    final controller = JobController(
      jobs: MockJobRepository(seed: seed),
      technicians: MockTechnicianRepository(seed: seed),
    );

    final created = await controller.createJob(
      propertyId: MockSeedIds.propertyId,
      type: JobType.preventiveMaintenance,
      date: '2026-09-03',
      startTime: '13:00',
      endTime: '15:00',
    );

    expect(controller.jobById(created.id)?.jobNumber, created.jobNumber);
    final detail = await controller.loadJobDetail(created.id);
    expect(detail.job.id, created.id);
  });
}
