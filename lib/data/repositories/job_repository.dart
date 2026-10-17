import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/models/office_job.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';

abstract class JobRepository {
  Future<List<HistoryJob>> getJobs();
  Future<PagedResult<HistoryJob>> getJobsPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    JobStatus? status,
    String? technicianId,
    String? customerId,
    String? dateFrom,
    String? dateTo,
  });
  Future<HistoryJob?> getJob(String id);
  Future<JobDetail> getJobDetail(String id);

  Future<HistoryJob> createJob({
    required String propertyId,
    required JobType type,
    required String date,
    required String startTime,
    required String endTime,
    String description = '',
    String? truckAssetId,
  });
  Future<HistoryJob> rescheduleJob({
    required String jobId,
    required String date,
    required String startTime,
    required String endTime,
  });
  Future<HistoryJob> cancelJob(String jobId);
  Future<HistoryJob> assignJob({required String jobId, String? technicianId});
  Future<HistoryJob> setJobTruck({required String jobId, String? truckAssetId});
}
