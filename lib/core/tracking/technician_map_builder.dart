import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/tracking/tracking_policy.dart';

class TechnicianMapSnapshot {
  const TechnicianMapSnapshot({
    required this.technician,
    required this.status,
    required this.recordedAt,
    required this.isStale,
    required this.isVisible,
    this.currentJob,
    this.jobAddress,
    this.customerName,
  });

  final OfficeTechnician technician;
  final TechnicianStatus status;
  final DateTime? recordedAt;
  final bool isStale;
  final bool isVisible;
  final HistoryJob? currentJob;
  final String? jobAddress;
  final String? customerName;

  String get headline {
    final parts = <String>[technician.displayName, status.label];
    if (jobAddress != null && jobAddress!.isNotEmpty) parts.add(jobAddress!);
    return parts.join(' — ');
  }
}

abstract final class TechnicianMapBuilder {
  static List<TechnicianMapSnapshot> build({
    required List<OfficeTechnician> technicians,
    required TechnicianStatus Function(OfficeTechnician technician) statusFor,
    required List<HistoryJob> Function(String technicianId) jobsFor,
    required OfficeProperty? Function(String propertyId) propertyFor,
    required OfficeCustomer? Function(String customerId) customerFor,
    TrackingPolicy policy = TrackingPolicy.hvacPro,
    DateTime? now,
    bool includeOffDuty = false,
  }) {
    final anchor = now ?? DateTime.now();
    final snapshots = <TechnicianMapSnapshot>[];

    for (final technician in technicians) {
      final status = statusFor(technician);
      final visible = policy.shouldShowOnMap(
        now: anchor,
        status: status,
        includeOffDuty: includeOffDuty,
      );
      final recordedAt = DateTime.tryParse(technician.lastUpdated);
      final openJobs = jobsFor(technician.id);
      final currentJob = openJobs.isEmpty ? null : openJobs.first;
      OfficeProperty? property;
      OfficeCustomer? customer;
      if (currentJob != null) {
        property = propertyFor(currentJob.propertyId);
        if (property != null) customer = customerFor(property.customerId);
      }

      snapshots.add(
        TechnicianMapSnapshot(
          technician: technician,
          status: status,
          recordedAt: recordedAt,
          isStale: policy.isStale(recordedAt, now: anchor),
          isVisible: visible,
          currentJob: currentJob,
          jobAddress: property?.address ?? technician.lastAddress,
          customerName: customer?.displayName,
        ),
      );
    }

    snapshots.sort((a, b) => a.technician.displayName.compareTo(b.technician.displayName));
    return snapshots;
  }
}
