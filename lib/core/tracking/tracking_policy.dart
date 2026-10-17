import 'package:flutter/material.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/company_settings.dart';

/// Company GPS policy — management map respects working hours (not 24/7).
class TrackingPolicy {
  const TrackingPolicy({
    this.workdayStart = const TimeOfDay(hour: 7, minute: 0),
    this.workdayEnd = const TimeOfDay(hour: 18, minute: 0),
    this.staleAfter = const Duration(minutes: 15),
    this.stopStatuses = const {TechnicianStatus.offDuty},
  });

  static const hvacPro = TrackingPolicy();

  /// Builds from persisted company settings; invalid windows fall back to [hvacPro].
  factory TrackingPolicy.fromCompanySettings(CompanySettings? settings) {
    if (settings == null) return hvacPro;
    final window = settings.normalizedGpsWindow;
    return TrackingPolicy(
      workdayStart: TimeOfDay(hour: window.$1 ~/ 60, minute: window.$1 % 60),
      workdayEnd: TimeOfDay(hour: window.$2 ~/ 60, minute: window.$2 % 60),
    );
  }

  final TimeOfDay workdayStart;
  final TimeOfDay workdayEnd;
  final Duration staleAfter;
  final Set<TechnicianStatus> stopStatuses;

  String get hoursLabel {
    String fmt(TimeOfDay t) {
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final m = t.minute.toString().padLeft(2, '0');
      final period = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$h:$m $period';
    }

    return '${fmt(workdayStart)} – ${fmt(workdayEnd)}';
  }

  bool isWithinWorkingHours(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    final start = workdayStart.hour * 60 + workdayStart.minute;
    final end = workdayEnd.hour * 60 + workdayEnd.minute;
    return minutes >= start && minutes < end;
  }

  bool shouldShowOnMap({
    required DateTime now,
    required TechnicianStatus status,
    bool includeOffDuty = false,
  }) {
    if (!isWithinWorkingHours(now) && !status.isActiveFieldStatus) return false;
    if (stopStatuses.contains(status) && !includeOffDuty) return false;
    return true;
  }

  bool isStale(DateTime? recordedAt, {DateTime? now}) {
    if (recordedAt == null) return true;
    final anchor = now ?? DateTime.now();
    return anchor.difference(recordedAt) > staleAfter;
  }
}

extension _TechnicianStatusMapX on TechnicianStatus {
  bool get isActiveFieldStatus => switch (this) {
        TechnicianStatus.onTheWay || TechnicianStatus.driving || TechnicianStatus.onJob => true,
        _ => false,
      };
}
