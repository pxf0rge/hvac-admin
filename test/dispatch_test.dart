import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/dispatch/dispatch_schedule.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('MockJobRepository assigns and unassigns technician', () async {
    final seed = MockSeedData();
    final repo = MockJobRepository(seed: seed);
    final created = await repo.createJob(
      propertyId: MockSeedIds.propertyId,
      type: JobType.diagnostic,
      date: '2026-09-10',
      startTime: '09:00',
      endTime: '11:00',
    );

    final assigned = await repo.assignJob(jobId: created.id, technicianId: MockSeedIds.technicianId);
    expect(assigned.technicianId, MockSeedIds.technicianId);
    expect(assigned.status, JobStatus.assigned);
    expect(assigned.technicianName, 'Carlos Rodriguez');

    final unassigned = await repo.assignJob(jobId: created.id, technicianId: null);
    expect(unassigned.technicianId, isNull);
    expect(unassigned.status, JobStatus.unassigned);
  });

  test('MockJobRepository binds optional truck without blocking workflow', () async {
    final seed = MockSeedData();
    final repo = MockJobRepository(seed: seed);
    final created = await repo.createJob(
      propertyId: MockSeedIds.propertyId,
      type: JobType.diagnostic,
      date: '2026-09-10',
      startTime: '09:00',
      endTime: '11:00',
      truckAssetId: 'truck-asset-1',
    );
    expect(created.truckAssetId, 'truck-asset-1');

    final cleared = await repo.setJobTruck(jobId: created.id, truckAssetId: null);
    expect(cleared.truckAssetId, isNull);

    final rebound = await repo.setJobTruck(jobId: created.id, truckAssetId: 'truck-asset-2');
    expect(rebound.truckAssetId, 'truck-asset-2');
  });

  test('DispatchSchedule detects overlapping jobs', () {
    const first = HistoryJob(
      id: 'job-1',
      propertyId: 'prop',
      jobNumber: 'JOB-1',
      type: JobType.diagnostic,
      status: JobStatus.assigned,
      priority: JobPriority.normal,
      date: '2026-09-10',
      startTime: '09:00',
      endTime: '11:00',
      technicianName: 'Carlos Rodriguez',
      technicianId: MockSeedIds.technicianId,
    );
    const second = HistoryJob(
      id: 'job-2',
      propertyId: 'prop',
      jobNumber: 'JOB-2',
      type: JobType.diagnostic,
      status: JobStatus.assigned,
      priority: JobPriority.normal,
      date: '2026-09-10',
      startTime: '10:00',
      endTime: '12:00',
      technicianName: 'Carlos Rodriguez',
      technicianId: MockSeedIds.technicianId,
    );

    final conflicts = DispatchSchedule.conflictsFor(
      scheduled: const [first],
      candidate: second,
    );
    expect(conflicts, hasLength(1));
    expect(conflicts.first.id, 'job-1');
  });

  test('JobController assigns job on dispatch board', () async {
    final seed = MockSeedData();
    final controller = JobController(
      jobs: MockJobRepository(seed: seed),
      technicians: MockTechnicianRepository(seed: seed),
    );
    await controller.loadDispatch();

    final unassigned = controller.jobsForTechnician(null);
    expect(unassigned, isNotEmpty);

    final job = unassigned.first;
    await controller.assignJob(jobId: job.id, technicianId: MockSeedIds.technicianId);

    expect(controller.jobsForTechnician(MockSeedIds.technicianId).any((item) => item.id == job.id), isTrue);
    expect(controller.jobsForTechnician(null).any((item) => item.id == job.id), isFalse);
  });
}
