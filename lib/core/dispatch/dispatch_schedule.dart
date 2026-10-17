import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/utils/formatters.dart';

/// Overlap detection for dispatch board scheduling.
abstract final class DispatchSchedule {
  static bool overlaps(HistoryJob a, HistoryJob b) {
    if (!a.isOpen || !b.isOpen) return false;
    if (a.date != b.date) return false;
    if (a.technicianId == null || b.technicianId == null) return false;
    if (a.technicianId != b.technicianId) return false;

    final aStart = timeToMinutes(a.startTime);
    final aEnd = timeToMinutes(a.endTime);
    final bStart = timeToMinutes(b.startTime);
    final bEnd = timeToMinutes(b.endTime);
    if (aEnd <= aStart || bEnd <= bStart) return false;
    return aStart < bEnd && bStart < aEnd;
  }

  static List<HistoryJob> conflictsFor({
    required List<HistoryJob> scheduled,
    required HistoryJob candidate,
    String? excludeJobId,
  }) {
    return [
      for (final job in scheduled)
        if (job.id != excludeJobId && job.id != candidate.id && overlaps(job, candidate)) job,
    ];
  }
}
