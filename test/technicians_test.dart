import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/controllers/technician_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('MockTechnicianRepository saves and disables technician', () async {
    final seed = MockSeedData();
    final repo = MockTechnicianRepository(seed: seed);

    final created = await repo.saveTechnician(
      firstName: 'Ava',
      lastName: 'Stone',
      phone: '2175550111',
      email: 'ava.stone@hvacpro.com',
    );
    expect(created.displayName, 'Ava Stone');
    expect(seed.technicians.any((tech) => tech.id == created.id), isTrue);

    final disabled = await repo.setAccountEnabled(id: created.id, enabled: false);
    expect(disabled.accountEnabled, isFalse);
  });

  test('TechnicianController loads detail with recent jobs', () async {
    final seed = MockSeedData();
    final controller = TechnicianController(MockTechnicianRepository(seed: seed));
    await controller.load();
    expect(controller.technicians.length, greaterThanOrEqualTo(2));

    final detail = await controller.loadDetail(MockSeedIds.technicianId);
    expect(detail.technician.id, MockSeedIds.technicianId);
    expect(detail.recentJobs, isNotEmpty);
    expect(detail.activity, isNotEmpty);
  });

  test('JobController board status reflects assigned jobs', () async {
    final seed = MockSeedData();
    final jobs = JobController(
      jobs: MockJobRepository(seed: seed),
      technicians: MockTechnicianRepository(seed: seed),
    );
    await jobs.loadDispatch();
    final carlos = jobs.technicians.firstWhere((tech) => tech.id == MockSeedIds.technicianId);
    expect(jobs.boardStatusFor(carlos), isNot(TechnicianStatus.available));
    expect(jobs.jobsForTechnician(MockSeedIds.technicianId), isNotEmpty);
  });
}
