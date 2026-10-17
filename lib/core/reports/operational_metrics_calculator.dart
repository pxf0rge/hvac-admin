import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/models/office_job.dart';
import 'package:hvac_admin/core/models/office_reports.dart';

/// Input row for operational KPI computation (jobs + workflow history).
class JobReportInput {
  const JobReportInput({
    required this.id,
    required this.type,
    required this.status,
    required this.technicianId,
    required this.technicianName,
    required this.scheduledDate,
    required this.startTime,
    required this.history,
  });

  final String id;
  final JobType type;
  final JobStatus status;
  final String? technicianId;
  final String technicianName;
  final String scheduledDate;
  final String startTime;
  final List<JobStatusEvent> history;
}

abstract final class OperationalMetricsCalculator {
  static const _onTimeGrace = Duration(minutes: 15);

  static OperationalReportMetrics compute({
    required List<JobReportInput> jobs,
    required List<OfficeTechnician> technicians,
  }) {
    var jobsCompleted = 0;
    var jobsOpen = 0;
    final volumeMap = <String, int>{};
    final techStats = <String, _TechAccumulator>{};

    for (final tech in technicians) {
      techStats[tech.id] = _TechAccumulator(name: tech.displayName);
    }

    for (final job in jobs) {
      if (job.status == JobStatus.completed) {
        jobsCompleted += 1;
      } else if (job.status != JobStatus.cancelled) {
        jobsOpen += 1;
      }
      volumeMap[job.type.label] = (volumeMap[job.type.label] ?? 0) + 1;

      final techId = _technicianIdFor(job, technicians);
      if (techId == null) continue;
      final stats = techStats.putIfAbsent(techId, () => _TechAccumulator(name: job.technicianName));
      stats.total += 1;
      if (job.status == JobStatus.completed) {
        stats.completed += 1;
        final minutes = _jobDurationMinutes(job.history);
        if (minutes != null) {
          stats.durationMinutes.add(minutes);
        }
        final onTime = _jobOnTime(job);
        if (onTime != null) {
          stats.onTimeSamples += 1;
          if (onTime) stats.onTimeHits += 1;
        }
      }
    }

    final volume = [
      for (final entry in volumeMap.entries) JobVolumeBar(label: entry.key, count: entry.value),
    ]..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        if (byCount != 0) return byCount;
        return a.label.compareTo(b.label);
      });

    final technicianRows = [
      for (final tech in technicians) _rowFor(tech.id, techStats[tech.id]),
      for (final entry in techStats.entries)
        if (technicians.every((tech) => tech.id != entry.key)) _rowFor(entry.key, entry.value),
    ]..sort((a, b) {
        final byTotal = b.total.compareTo(a.total);
        if (byTotal != 0) return byTotal;
        return b.completed.compareTo(a.completed);
      });

    final jobsWithHistory = jobs.where((job) => job.history.isNotEmpty).length;

    return OperationalReportMetrics(
      jobsCompleted: jobsCompleted,
      jobsOpen: jobsOpen,
      jobsTotal: jobs.length,
      volume: volume,
      technicians: technicianRows,
      jobsWithHistory: jobsWithHistory,
    );
  }

  static TechnicianReportRow _rowFor(String technicianId, _TechAccumulator? stats) {
    final accumulator = stats ?? _TechAccumulator(name: technicianId);
    return TechnicianReportRow(
      technicianId: technicianId,
      name: accumulator.name,
      completed: accumulator.completed,
      total: accumulator.total,
      avgMinutesOnSite: accumulator.avgMinutes,
      onTimePercent: accumulator.onTimePercent,
    );
  }

  static int? _jobDurationMinutes(List<JobStatusEvent> history) {
    final start = _earliest(history, JobActivityKind.arrived) ??
        _earliest(history, JobActivityKind.jobStarted);
    final end = _earliest(history, JobActivityKind.jobCompleted);
    if (start == null || end == null || end.isBefore(start)) return null;
    return end.difference(start).inMinutes;
  }

  static DateTime? _earliest(List<JobStatusEvent> history, JobActivityKind kind) {
    DateTime? earliest;
    for (final event in history) {
      if (event.kind != kind) continue;
      final at = DateTime.tryParse(event.at);
      if (at == null) continue;
      if (earliest == null || at.isBefore(earliest)) {
        earliest = at;
      }
    }
    return earliest;
  }

  static bool? _jobOnTime(JobReportInput job) {
    final arrived = _earliest(job.history, JobActivityKind.arrived);
    if (arrived == null) return null;
    final scheduled = _scheduledStart(job.scheduledDate, job.startTime);
    if (scheduled == null) return null;
    return !arrived.isAfter(scheduled.add(_onTimeGrace));
  }

  static String? _technicianIdFor(JobReportInput job, List<OfficeTechnician> technicians) {
    final id = job.technicianId;
    if (id != null && id.isNotEmpty) return id;
    final name = job.technicianName.trim().toLowerCase();
    if (name.isEmpty || name == 'unassigned') return null;
    for (final tech in technicians) {
      if (tech.displayName.toLowerCase() == name) return tech.id;
    }
    return null;
  }

  static DateTime? _scheduledStart(String date, String startTime) {
    final day = DateTime.tryParse(date);
    if (day == null) return null;
    final parts = startTime.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }
}

class _TechAccumulator {
  _TechAccumulator({required this.name});

  final String name;
  int completed = 0;
  int total = 0;
  final List<int> durationMinutes = [];
  int onTimeSamples = 0;
  int onTimeHits = 0;

  int? get avgMinutes {
    if (durationMinutes.isEmpty) return null;
    final sum = durationMinutes.fold<int>(0, (total, value) => total + value);
    return (sum / durationMinutes.length).round();
  }

  int? get onTimePercent {
    if (onTimeSamples == 0) return null;
    return ((onTimeHits / onTimeSamples) * 100).round();
  }
}

class OperationalReportMetrics {
  const OperationalReportMetrics({
    required this.jobsCompleted,
    required this.jobsOpen,
    required this.jobsTotal,
    required this.volume,
    required this.technicians,
    required this.jobsWithHistory,
  });

  static const empty = OperationalReportMetrics(
    jobsCompleted: 0,
    jobsOpen: 0,
    jobsTotal: 0,
    volume: [],
    technicians: [],
    jobsWithHistory: 0,
  );

  final int jobsCompleted;
  final int jobsOpen;
  final int jobsTotal;
  final List<JobVolumeBar> volume;
  final List<TechnicianReportRow> technicians;
  final int jobsWithHistory;

  bool get hasOperationalData => jobsTotal > 0;
  bool get hasWorkflowData => jobsWithHistory > 0;
}
