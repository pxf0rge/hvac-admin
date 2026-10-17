import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/dashboard_snapshot.dart';
import 'package:hvac_admin/core/reports/operational_metrics_calculator.dart';
import 'package:hvac_admin/core/utils/formatters.dart';import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/billing_repository.dart';
import 'package:hvac_admin/data/repositories/job_repository.dart';
import 'package:hvac_admin/data/repositories/reports_repository.dart';
import 'package:hvac_admin/data/repositories/technician_repository.dart';

class MockReportsRepository implements ReportsRepository {
  MockReportsRepository({
    required JobRepository jobs,
    required TechnicianRepository technicians,
    required BillingRepository billing,
    MockSeedData? seed,
  })  : _jobs = jobs,
        _technicians = technicians,
        _billing = billing,
        _seed = seed ?? MockSeedData();

  final JobRepository _jobs;
  final TechnicianRepository _technicians;
  final BillingRepository _billing;
  final MockSeedData _seed;

  @override
  Future<DashboardSnapshot> loadDashboardMetrics({bool includeFinancial = true}) async {
    final allJobs = await _jobs.getJobs();
    final techs = await _technicians.getTechnicians();
    final today = isoDate(DateTime.now());

    final todaysJobs = allJobs.where((job) => job.date == today).length;
    final unassignedJobs = allJobs.where((job) {
      return job.status == JobStatus.unassigned ||
          job.technicianId == null ||
          job.technicianId!.isEmpty;
    }).length;

    final activeTechnicians = techs.where((tech) => tech.status != TechnicianStatus.offDuty).length;

    var jobsCompleted = 0;
    var jobsOpen = 0;
    for (final job in allJobs) {
      if (job.status == JobStatus.completed) {
        jobsCompleted += 1;
      } else if (job.status != JobStatus.cancelled) {
        jobsOpen += 1;
      }
    }

    var openEstimates = 0;
    var overdueInvoiceCount = 0;
    var overdueInvoiceTotal = 0.0;
    var hasFinancialData = false;

    if (includeFinancial) {
      final estimates = await _billing.getEstimates();
      openEstimates = estimates
          .where((estimate) =>
              estimate.status == EstimateStatus.draft || estimate.status == EstimateStatus.sent)
          .length;

      final invoices = await _billing.getInvoices();
      hasFinancialData = estimates.isNotEmpty || invoices.isNotEmpty;
      for (final invoice in invoices) {
        if (invoice.status == InvoiceStatus.overdue) {
          overdueInvoiceCount += 1;
          overdueInvoiceTotal += invoice.amount;
        }
      }
    }

    return DashboardSnapshot(
      todaysJobs: todaysJobs,
      unassignedJobs: unassignedJobs,
      activeTechnicians: activeTechnicians,
      openEstimates: openEstimates,
      overdueInvoiceCount: overdueInvoiceCount,
      overdueInvoiceTotal: overdueInvoiceTotal,
      jobsCompleted: jobsCompleted,
      jobsOpen: jobsOpen,
      jobsTotal: allJobs.length,
      recentActivity: _activityFromSeed(),
      hasOperationalData: allJobs.isNotEmpty || techs.isNotEmpty,
      hasFinancialData: hasFinancialData,
    );
  }

  List<DashboardActivityItem> _activityFromSeed() {
    final items = <DashboardActivityItem>[
      for (final message in _seed.messages)
        DashboardActivityItem(
          at: message.at,
          title: '${message.channel.name.toUpperCase()} · ${message.entityLabel}',
          detail: message.body,
          entityType: message.entityType.name,
          entityId: message.entityId,
        ),
      for (final job in _seed.jobs)
        DashboardActivityItem(
          at: job.date,
          title: 'Job ${job.jobNumber}',
          detail: job.description.isEmpty ? job.type.name : job.description,
          entityType: 'job',
          entityId: job.id,
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));
    return items.take(8).toList();
  }

  @override
  Future<OperationalReportMetrics> loadOperationalMetrics() async {
    final allJobs = await _jobs.getJobs();
    final technicians = await _technicians.getTechnicians();
    final inputs = <JobReportInput>[];
    for (final job in allJobs) {
      final detail = await _jobs.getJobDetail(job.id);
      inputs.add(
        JobReportInput(
          id: job.id,
          type: job.type,
          status: job.status,
          technicianId: job.technicianId,
          technicianName: job.technicianName,
          scheduledDate: job.date,
          startTime: job.startTime,
          history: detail.statusHistory,
        ),
      );
    }
    return OperationalMetricsCalculator.compute(jobs: inputs, technicians: technicians);
  }
}
