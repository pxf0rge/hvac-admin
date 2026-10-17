class DashboardActivityItem {
  const DashboardActivityItem({
    required this.at,
    required this.title,
    required this.detail,
    this.entityType,
    this.entityId,
  });

  final String at;
  final String title;
  final String detail;
  final String? entityType;
  final String? entityId;
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.todaysJobs,
    required this.unassignedJobs,
    required this.activeTechnicians,
    required this.openEstimates,
    required this.overdueInvoiceCount,
    required this.overdueInvoiceTotal,
    required this.jobsCompleted,
    required this.jobsOpen,
    required this.jobsTotal,
    required this.recentActivity,
    required this.hasOperationalData,
    required this.hasFinancialData,
  });

  static const empty = DashboardSnapshot(
    todaysJobs: 0,
    unassignedJobs: 0,
    activeTechnicians: 0,
    openEstimates: 0,
    overdueInvoiceCount: 0,
    overdueInvoiceTotal: 0,
    jobsCompleted: 0,
    jobsOpen: 0,
    jobsTotal: 0,
    recentActivity: [],
    hasOperationalData: false,
    hasFinancialData: false,
  );

  final int todaysJobs;
  final int unassignedJobs;
  final int activeTechnicians;
  final int openEstimates;
  final int overdueInvoiceCount;
  final double overdueInvoiceTotal;
  final int jobsCompleted;
  final int jobsOpen;
  final int jobsTotal;
  final List<DashboardActivityItem> recentActivity;

  final bool hasOperationalData;
  final bool hasFinancialData;
}
