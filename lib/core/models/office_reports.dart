import 'package:hvac_admin/core/models/office_billing.dart';

class TechnicianReportRow {
  const TechnicianReportRow({
    required this.name,
    required this.completed,
    required this.total,
    this.technicianId,
    this.avgMinutesOnSite,
    this.onTimePercent,
  });

  final String name;
  final String? technicianId;
  final int completed;
  final int total;
  final int? avgMinutesOnSite;
  final int? onTimePercent;
}

class JobVolumeBar {
  const JobVolumeBar({required this.label, required this.count});

  final String label;
  final int count;
}

class OfficeReportSnapshot {
  const OfficeReportSnapshot({
    required this.paid,
    required this.outstanding,
    required this.overdue,
    required this.jobsCompleted,
    required this.jobsOpen,
    required this.jobsTotal,
    required this.technicians,
    required this.volume,
    required this.invoices,
    required this.hasFinancialData,
    required this.hasOperationalData,
    required this.hasWorkflowData,
  });

  final double paid;
  final double outstanding;
  final double overdue;
  final int jobsCompleted;
  final int jobsOpen;
  final int jobsTotal;
  final List<TechnicianReportRow> technicians;
  final List<JobVolumeBar> volume;
  final List<OfficeInvoice> invoices;
  final bool hasFinancialData;
  final bool hasOperationalData;
  final bool hasWorkflowData;
}
