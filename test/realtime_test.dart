import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/gps_map_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/controllers/technician_controller.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/realtime/hvac_realtime_event.dart';
import 'package:hvac_admin/core/realtime/realtime_bridge.dart';
import 'package:hvac_admin/core/realtime/realtime_event_deduper.dart';
import 'package:hvac_admin/core/tracking/technician_location_fix.dart';
import 'package:hvac_admin/data/datasources/hvac_realtime_service.dart';
import 'package:hvac_admin/data/datasources/mock_management_auth_service.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';
import 'package:hvac_admin/data/repositories/mock_technician_location_repository.dart';

class _CountingJobRepository extends MockJobRepository {
  _CountingJobRepository({super.seed});

  int getJobsCalls = 0;

  @override
  Future<List<HistoryJob>> getJobs() async {
    getJobsCalls += 1;
    return super.getJobs();
  }
}

class _CountingTechnicianRepository extends MockTechnicianRepository {
  _CountingTechnicianRepository({super.seed});

  int getTechniciansCalls = 0;

  @override
  Future<List<OfficeTechnician>> getTechnicians() async {
    getTechniciansCalls += 1;
    return super.getTechnicians();
  }
}

class _CountingLocationRepository extends MockTechnicianLocationRepository {
  int historyCalls = 0;

  @override
  Future<List<TechnicianLocationFix>> historyFor(String technicianId, {int limit = 40}) async {
    historyCalls += 1;
    return super.historyFor(technicianId, limit: limit);
  }
}

void main() {
  test('Realtime deduper skips duplicates and local echoes', () {
    final deduper = RealtimeEventDeduper(localEchoWindow: const Duration(seconds: 2));
    final event = HvacRealtimeEvent(
      table: HvacRealtimeTable.jobs,
      changeType: HvacRealtimeChangeType.update,
      recordId: 'job-1',
      commitTimestamp: DateTime.utc(2026, 8, 26, 12),
    );
    expect(deduper.shouldApply(event), isTrue);
    expect(deduper.shouldApply(event), isFalse);

    deduper.rememberLocalMutation(HvacRealtimeTable.jobAssignments, 'job-1');
    final echo = HvacRealtimeEvent(
      table: HvacRealtimeTable.jobAssignments,
      changeType: HvacRealtimeChangeType.update,
      recordId: 'job-1',
      commitTimestamp: DateTime.utc(2026, 8, 26, 12, 1),
    );
    expect(deduper.shouldApply(echo), isFalse);
  });

  test('Realtime bridge refreshes dispatch on remote job event', () async {
    final service = NoopRealtimeService();
    final jobsRepo = _CountingJobRepository();
    final techRepo = MockTechnicianRepository();
    final jobs = JobController(jobs: jobsRepo, technicians: techRepo);
    final technicians = TechnicianController(techRepo);
    final customers = CustomerController(MockCustomerRepository());
    final gps = GpsMapController(MockTechnicianLocationRepository());
    final management = AppManagementAuthController(MockManagementAuthService());

    final bridge = RealtimeBridge(
      service: service,
      management: management,
      jobs: jobs,
      technicians: technicians,
      customers: customers,
      gps: gps,
      refreshDebounce: const Duration(milliseconds: 5),
    );
    jobs.bindRealtime(bridge);
    bridge.attach();

    await management.signIn(email: 'diana@hvacpro.com', password: 'OfficeLead!');
    await jobs.loadDispatch();
    final callsAfterLoad = jobsRepo.getJobsCalls;

    service.emit(
      HvacRealtimeEvent(
        table: HvacRealtimeTable.jobs,
        changeType: HvacRealtimeChangeType.update,
        recordId: 'remote-job-1',
        commitTimestamp: DateTime.utc(2026, 8, 30, 12),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(jobsRepo.getJobsCalls, greaterThan(callsAfterLoad));

    await bridge.dispose();
  });

  test('Realtime bridge polls when connection drops', () async {
    final service = NoopRealtimeService();
    final jobsRepo = _CountingJobRepository();
    final techRepo = MockTechnicianRepository();
    final jobs = JobController(jobs: jobsRepo, technicians: techRepo);
    final technicians = TechnicianController(techRepo);
    final customers = CustomerController(MockCustomerRepository());
    final gps = GpsMapController(MockTechnicianLocationRepository());
    final management = AppManagementAuthController(MockManagementAuthService());

    final bridge = RealtimeBridge(
      service: service,
      management: management,
      jobs: jobs,
      technicians: technicians,
      customers: customers,
      gps: gps,
      pollInterval: const Duration(milliseconds: 40),
      refreshDebounce: const Duration(milliseconds: 5),
    );
    bridge.attach();

    await management.signIn(email: 'diana@hvacpro.com', password: 'OfficeLead!');
    await jobs.loadDispatch();
    final callsAfterLoad = jobsRepo.getJobsCalls;

    service.emitConnection(RealtimeConnectionStatus.disconnected);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    expect(jobsRepo.getJobsCalls, greaterThan(callsAfterLoad));

    await bridge.dispose();
  });

  test('Realtime bridge refreshes technicians on remote technician event', () async {
    final service = NoopRealtimeService();
    final techRepo = _CountingTechnicianRepository();
    final jobs = JobController(jobs: MockJobRepository(), technicians: techRepo);
    final technicians = TechnicianController(techRepo);
    final management = AppManagementAuthController(MockManagementAuthService());

    final bridge = RealtimeBridge(
      service: service,
      management: management,
      jobs: jobs,
      technicians: technicians,
      customers: CustomerController(MockCustomerRepository()),
      gps: GpsMapController(MockTechnicianLocationRepository()),
      refreshDebounce: const Duration(milliseconds: 5),
    );
    bridge.attach();

    await management.signIn(email: 'diana@hvacpro.com', password: 'OfficeLead!');
    await technicians.load();
    final callsAfterLoad = techRepo.getTechniciansCalls;

    service.emit(
      HvacRealtimeEvent(
        table: HvacRealtimeTable.technicians,
        changeType: HvacRealtimeChangeType.update,
        recordId: MockSeedIds.technicianId,
        commitTimestamp: DateTime.utc(2026, 8, 30, 12),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(techRepo.getTechniciansCalls, greaterThan(callsAfterLoad));

    await bridge.dispose();
  });

  test('Realtime bridge refreshes loaded GPS history on location insert', () async {
    final service = NoopRealtimeService();
    final locations = _CountingLocationRepository();
    final gps = GpsMapController(locations);
    final techRepo = _CountingTechnicianRepository();
    final management = AppManagementAuthController(MockManagementAuthService());

    final bridge = RealtimeBridge(
      service: service,
      management: management,
      jobs: JobController(jobs: MockJobRepository(), technicians: techRepo),
      technicians: TechnicianController(techRepo),
      customers: CustomerController(MockCustomerRepository()),
      gps: gps,
      refreshDebounce: const Duration(milliseconds: 5),
    );
    bridge.attach();

    await management.signIn(email: 'diana@hvacpro.com', password: 'OfficeLead!');
    await gps.loadHistory(MockSeedIds.technicianId);
    final callsAfterLoad = locations.historyCalls;

    service.emit(
      HvacRealtimeEvent(
        table: HvacRealtimeTable.technicianLocations,
        changeType: HvacRealtimeChangeType.insert,
        recordId: 'loc-1',
        commitTimestamp: DateTime.utc(2026, 8, 30, 12, 1),
        newRecord: {'technician_id': MockSeedIds.technicianId},
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(locations.historyCalls, greaterThan(callsAfterLoad));

    await bridge.dispose();
  });

  test('Realtime bridge stops handling events after dispose', () async {
    final service = NoopRealtimeService();
    final jobsRepo = _CountingJobRepository();
    final management = AppManagementAuthController(MockManagementAuthService());
    final bridge = RealtimeBridge(
      service: service,
      management: management,
      jobs: JobController(jobs: jobsRepo, technicians: MockTechnicianRepository()),
      technicians: TechnicianController(MockTechnicianRepository()),
      customers: CustomerController(MockCustomerRepository()),
      gps: GpsMapController(MockTechnicianLocationRepository()),
      refreshDebounce: const Duration(milliseconds: 5),
    );
    bridge.attach();

    await management.signIn(email: 'diana@hvacpro.com', password: 'OfficeLead!');
    await bridge.dispose();

    service.emit(
      HvacRealtimeEvent(
        table: HvacRealtimeTable.jobs,
        changeType: HvacRealtimeChangeType.update,
        recordId: 'remote-job-2',
        commitTimestamp: DateTime.utc(2026, 8, 30, 12, 2),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(jobsRepo.getJobsCalls, 0);
    expect(service.stopCalls, greaterThanOrEqualTo(1));
  });

  test('assignJob records local mutation for deduper', () async {
    final service = NoopRealtimeService();
    final seed = MockSeedData();
    final jobsRepo = MockJobRepository(seed: seed);
    final techRepo = MockTechnicianRepository(seed: seed);
    final jobs = JobController(jobs: jobsRepo, technicians: techRepo);
    final bridge = RealtimeBridge(
      service: service,
      management: AppManagementAuthController(MockManagementAuthService()),
      jobs: jobs,
      technicians: TechnicianController(techRepo),
      customers: CustomerController(MockCustomerRepository(seed: seed)),
      gps: GpsMapController(MockTechnicianLocationRepository()),
    );
    jobs.bindRealtime(bridge);
    bridge.attach();

    await jobs.loadDispatch();
    await jobs.assignJob(jobId: MockSeedIds.unassignedJobId, technicianId: MockSeedIds.technicianId);

    final echo = HvacRealtimeEvent(
      table: HvacRealtimeTable.jobs,
      changeType: HvacRealtimeChangeType.update,
      recordId: MockSeedIds.unassignedJobId,
      commitTimestamp: DateTime.utc(2026, 8, 30, 12),
    );
    expect(bridge.deduper.shouldApply(echo), isFalse);

    await bridge.dispose();
  });
}
