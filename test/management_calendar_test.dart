import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/calendar/management_calendar.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';

void main() {
  final jobs = [
    const HistoryJob(
      id: 'job_a',
      propertyId: 'prop_1',
      jobNumber: 'JOB-A',
      type: JobType.diagnostic,
      status: JobStatus.assigned,
      priority: JobPriority.normal,
      date: '2026-08-25',
      startTime: '09:00',
      endTime: '11:00',
      technicianName: 'Carlos',
      technicianId: 'tech_carlos',
    ),
    const HistoryJob(
      id: 'job_b',
      propertyId: 'prop_2',
      jobNumber: 'JOB-B',
      type: JobType.preventiveMaintenance,
      status: JobStatus.unassigned,
      priority: JobPriority.normal,
      date: '2026-08-26',
      startTime: '13:00',
      endTime: '15:00',
      technicianName: '',
    ),
    const HistoryJob(
      id: 'job_c',
      propertyId: 'prop_3',
      jobNumber: 'JOB-C',
      type: JobType.acNotCooling,
      status: JobStatus.cancelled,
      priority: JobPriority.normal,
      date: '2026-08-26',
      startTime: '10:00',
      endTime: '12:00',
      technicianName: 'Carlos',
      technicianId: 'tech_carlos',
    ),
  ];

  test('weekDays starts on Monday', () {
    final days = ManagementCalendar.weekDays(DateTime(2026, 8, 26)); // Wednesday
    expect(days.first.weekday, DateTime.monday);
    expect(ManagementCalendar.isoDate(days.first), '2026-08-24');
    expect(days.length, 7);
  });

  test('jobsOnDay filters by date and technician', () {
    final wednesday = DateTime(2026, 8, 26);
    final all = ManagementCalendar.jobsOnDay(jobs: jobs, day: wednesday, technicianFilter: 'all');
    expect(all.map((j) => j.id), ['job_b']);

    final unassigned = ManagementCalendar.jobsOnDay(
      jobs: jobs,
      day: wednesday,
      technicianFilter: ManagementCalendar.unassignedFilter,
    );
    expect(unassigned.single.id, 'job_b');

    final carlos = ManagementCalendar.jobsOnDay(
      jobs: jobs,
      day: DateTime(2026, 8, 25),
      technicianFilter: 'tech_carlos',
    );
    expect(carlos.single.id, 'job_a');
  });

  test('jobsBetween spans week and excludes cancelled', () {
    final start = DateTime(2026, 8, 24);
    final end = DateTime(2026, 8, 30);
    final week = ManagementCalendar.jobsBetween(jobs: jobs, start: start, end: end, technicianFilter: 'all');
    expect(week.map((j) => j.id), ['job_a', 'job_b']);
  });
}
