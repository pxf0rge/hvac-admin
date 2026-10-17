import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';

/// Calendar helpers shared by management calendar (same job source as dispatch).
abstract final class ManagementCalendar {
  static const unassignedFilter = '__unassigned__';

  static String isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime parseIso(String iso) {
    final parts = iso.split('-');
    if (parts.length < 3) return DateTime.now();
    return DateTime(
      int.tryParse(parts[0]) ?? 1970,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }

  static DateTime startOfWeek(DateTime anchor) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    final weekday = day.weekday; // Mon=1
    return day.subtract(Duration(days: weekday - 1));
  }

  static List<DateTime> weekDays(DateTime anchor) {
    final start = startOfWeek(anchor);
    return [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
  }

  static bool matchesTechnician(HistoryJob job, String? technicianFilter) {
    if (technicianFilter == null || technicianFilter == 'all') return true;
    if (technicianFilter == unassignedFilter) return job.technicianId == null;
    return job.technicianId == technicianFilter;
  }

  static List<HistoryJob> jobsBetween({
    required List<HistoryJob> jobs,
    required DateTime start,
    required DateTime end,
    String? technicianFilter,
    bool includeCompleted = true,
  }) {
    final startIso = isoDate(start);
    final endIso = isoDate(end);
    final filtered = [
      for (final job in jobs)
        if (_isOnOrBetween(job.date, startIso, endIso) &&
            matchesTechnician(job, technicianFilter) &&
            (includeCompleted || job.isOpen) &&
            job.status != JobStatus.cancelled)
          job,
    ]..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.startTime.compareTo(b.startTime);
      });
    return filtered;
  }

  static List<HistoryJob> jobsOnDay({
    required List<HistoryJob> jobs,
    required DateTime day,
    String? technicianFilter,
    bool includeCompleted = true,
  }) {
    return jobsBetween(
      jobs: jobs,
      start: day,
      end: day,
      technicianFilter: technicianFilter,
      includeCompleted: includeCompleted,
    );
  }

  static bool _isOnOrBetween(String jobDate, String startIso, String endIso) {
    return jobDate.compareTo(startIso) >= 0 && jobDate.compareTo(endIso) <= 0;
  }
}
