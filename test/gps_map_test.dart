import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/gps_map_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/tracking/job_map_builder.dart';
import 'package:hvac_admin/core/tracking/technician_map_builder.dart';
import 'package:hvac_admin/core/tracking/tracking_policy.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';
import 'package:hvac_admin/data/repositories/mock_technician_location_repository.dart';

void main() {
  group('TrackingPolicy', () {
    const policy = TrackingPolicy.hvacPro;

    test('working hours window', () {
      final noon = DateTime(2026, 8, 30, 12, 0);
      final night = DateTime(2026, 8, 30, 22, 0);
      expect(policy.isWithinWorkingHours(noon), isTrue);
      expect(policy.isWithinWorkingHours(night), isFalse);
    });

    test('off duty hidden unless opted in', () {
      final noon = DateTime(2026, 8, 30, 12, 0);
      expect(
        policy.shouldShowOnMap(now: noon, status: TechnicianStatus.offDuty),
        isFalse,
      );
      expect(
        policy.shouldShowOnMap(now: noon, status: TechnicianStatus.offDuty, includeOffDuty: true),
        isTrue,
      );
    });

    test('active field status visible outside working hours', () {
      final night = DateTime(2026, 8, 30, 22, 0);
      expect(
        policy.shouldShowOnMap(now: night, status: TechnicianStatus.onJob),
        isTrue,
      );
      expect(
        policy.shouldShowOnMap(now: night, status: TechnicianStatus.available),
        isFalse,
      );
    });

    test('stale when last fix is older than threshold', () {
      final now = DateTime(2026, 8, 30, 12, 0);
      final fresh = now.subtract(const Duration(minutes: 5));
      final old = now.subtract(const Duration(minutes: 20));
      expect(policy.isStale(fresh, now: now), isFalse);
      expect(policy.isStale(old, now: now), isTrue);
      expect(policy.isStale(null, now: now), isTrue);
    });
  });

  group('TechnicianMapBuilder', () {
    test('builds snapshots with job address and visibility', () async {
      final seed = MockSeedData();
      final jobs = JobController(
        jobs: MockJobRepository(seed: seed),
        technicians: MockTechnicianRepository(seed: seed),
      );
      await jobs.loadDispatch();

      final carlos = jobs.technicians.firstWhere((tech) => tech.id == MockSeedIds.technicianId);
      final noon = DateTime(2026, 8, 30, 12, 0);

      final snapshots = TechnicianMapBuilder.build(
        technicians: jobs.technicians,
        statusFor: jobs.boardStatusFor,
        jobsFor: jobs.jobsForTechnician,
        propertyFor: (id) => seed.properties.firstWhere((property) => property.id == id),
        customerFor: (id) => seed.customers.firstWhere((customer) => customer.id == id),
        now: noon,
      );

      final carlosSnapshot = snapshots.firstWhere((item) => item.technician.id == MockSeedIds.technicianId);
      expect(carlosSnapshot.status, TechnicianStatus.onJob);
      expect(carlosSnapshot.isVisible, isTrue);
      expect(carlosSnapshot.jobAddress, contains('Oak Lane'));
      expect(carlosSnapshot.currentJob?.jobNumber, 'JOB-RLS-21');
      expect(carlosSnapshot.isStale, isTrue);
      expect(carlosSnapshot.headline, contains(carlos.displayName));
    });
  });

  group('JobMapBuilder', () {
    test('builds today open job pins with property coordinates', () async {
      final seed = MockSeedData();
      final jobs = JobController(
        jobs: MockJobRepository(seed: seed),
        technicians: MockTechnicianRepository(seed: seed),
      );
      await jobs.loadDispatch();

      final today = DateTime.now();
      final pins = JobMapBuilder.buildForDay(
        jobs: jobs.jobs,
        propertyFor: (id) => seed.properties.firstWhere((property) => property.id == id),
        customerFor: (id) => seed.customers.firstWhere((customer) => customer.id == id),
        technicianFor: (id) => seed.technicians.firstWhere((tech) => tech.id == id),
        day: today,
      );

      expect(pins, isNotEmpty);
      expect(pins.every((pin) => pin.job.isOpen), isTrue);
      final withPoint = pins.where((pin) => pin.point != null).toList();
      expect(withPoint, isNotEmpty);
      expect(withPoint.first.markerId, startsWith('job:'));
      expect(withPoint.first.addressLabel, contains('Oak Lane'));
    });

    test('marks needsGeocode when property coords missing', () {
      final seed = MockSeedData();
      final today = DateTime.now();
      final bareProperty = OfficeProperty(
        id: 'prop-no-coords',
        customerId: MockSeedIds.customerId,
        address: '12 Missing Coords Ave',
        city: 'Springfield',
        state: 'IL',
        zip: '62701',
        type: PropertyType.residential,
      );
      final job = HistoryJob(
        id: 'job-geocode',
        propertyId: bareProperty.id,
        jobNumber: 'JOB-GEO-01',
        type: JobType.diagnostic,
        status: JobStatus.scheduled,
        priority: JobPriority.normal,
        date: isoDate(today),
        startTime: '10:00',
        endTime: '11:00',
        technicianName: 'Unassigned',
      );

      final pins = JobMapBuilder.buildForDay(
        jobs: [job],
        propertyFor: (id) => id == bareProperty.id ? bareProperty : null,
        customerFor: (_) => seed.customers.first,
        technicianFor: (_) => null,
        day: today,
      );

      expect(pins, hasLength(1));
      expect(pins.first.point, isNull);
      expect(pins.first.needsGeocode, isTrue);
      expect(pins.first.geocodeQuery, contains('Missing Coords'));
    });
  });

  test('GpsMapController loads location history', () async {
    final controller = GpsMapController(MockTechnicianLocationRepository());
    await controller.loadHistory(MockSeedIds.technicianId);
    final history = controller.historyFor(MockSeedIds.technicianId);
    expect(history, isNotEmpty);
    expect(history.first.technicianId, MockSeedIds.technicianId);
    expect(history.first.lastAddress, isNotNull);
  });
}
