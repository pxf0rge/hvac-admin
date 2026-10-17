import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/dispatch/dispatch_schedule.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/models/office_job.dart';
import 'package:hvac_admin/core/realtime/realtime_bridge.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';
import 'package:hvac_admin/data/repositories/job_repository.dart';
import 'package:hvac_admin/data/repositories/technician_repository.dart';

class JobController extends ChangeNotifier {
  JobController({
    required JobRepository jobs,
    required TechnicianRepository technicians,
  })  : _jobs = jobs,
        _technicians = technicians;

  final JobRepository _jobs;
  final TechnicianRepository _technicians;
  RealtimeBridge? _realtime;

  void bindRealtime(RealtimeBridge bridge) => _realtime = bridge;

  final Map<String, HistoryJob> _cache = {};
  final Map<String, JobDetail> _details = {};
  List<OfficeTechnician> _techniciansList = const [];
  List<HistoryJob> _dispatchJobs = const [];
  bool _loading = false;
  bool _loadingTechnicians = false;
  String? _loadError;
  String? _technicianLoadError;
  int _refreshToken = 0;

  String? _assigningJobId;

  bool get isLoading => _loading;
  String? get assigningJobId => _assigningJobId;
  bool get isAssigning => _assigningJobId != null;
  String? get loadError => _loadError;
  String? get technicianLoadError => _technicianLoadError;
  int get refreshToken => _refreshToken;
  List<OfficeTechnician> get technicians => _techniciansList;
  List<HistoryJob> get jobs => _dispatchJobs;

  HistoryJob? jobById(String id) => _cache[id];

  JobDetail? detailFor(String id) => _details[id];

  List<HistoryJob> jobsForTechnician(String? technicianId) {
    return [
      for (final job in _dispatchJobs)
        if (job.isOpen && job.technicianId == technicianId) job,
    ];
  }

  TechnicianStatus boardStatusFor(OfficeTechnician technician) {
    final assigned = jobsForTechnician(technician.id);
    if (assigned.any((job) => job.status == JobStatus.onTheWay)) return TechnicianStatus.onTheWay;
    if (assigned.any((job) => job.status == JobStatus.arrived || job.status == JobStatus.inProgress)) {
      return TechnicianStatus.onJob;
    }
    if (assigned.any((job) => job.status == JobStatus.assigned || job.status == JobStatus.scheduled)) {
      return TechnicianStatus.assigned;
    }
    return TechnicianStatus.available;
  }

  Future<void> reloadTechnicians() async {
    try {
      _technicianLoadError = null;
      _techniciansList = await _technicians.getTechnicians();
      notifyListeners();
    } catch (error, stack) {
      _technicianLoadError = error.toString();
      debugPrint('JobController.reloadTechnicians failed: $error\n$stack');
      notifyListeners();
    }
  }

  Future<void> loadTechnicians({bool force = false}) async {
    if (_loadingTechnicians) return;
    if (!force && _techniciansList.isNotEmpty) return;
    _loadingTechnicians = true;
    _technicianLoadError = null;
    try {
      _techniciansList = await _technicians.getTechnicians();
    } catch (error, stack) {
      _technicianLoadError = error.toString();
      debugPrint('JobController.loadTechnicians failed: $error\n$stack');
    } finally {
      _loadingTechnicians = false;
      notifyListeners();
    }
  }

  Future<void> loadDispatch({bool force = false}) async {
    if (_loading) return;
    if (!force && _dispatchJobs.isNotEmpty && _loadError == null) return;
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      await loadTechnicians();
      final loaded = await _jobs.getJobs();
      _dispatchJobs = [for (final job in loaded) if (job.isOpen) job];
      for (final job in loaded) {
        _cache[job.id] = job;
      }
      if (force) _refreshToken += 1;
    } catch (error, stack) {
      _loadError = error.toString();
      debugPrint('JobController.loadDispatch failed: $error\n$stack');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFromRemote() => loadDispatch(force: true);

  Future<PagedResult<HistoryJob>> fetchJobsPage({
    required int offset,
    String? search,
    JobStatus? status,
    String? technicianId,
    String? customerId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final page = await _jobs.getJobsPage(
      offset: offset,
      search: search,
      status: status,
      technicianId: technicianId,
      customerId: customerId,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    for (final job in page.items) {
      _cache[job.id] = job;
    }
    return page;
  }

  Future<HistoryJob?> ensureJobLoaded(String id) async {
    var job = jobById(id);
    if (job != null) return job;
    job = await _jobs.getJob(id);
    if (job == null) return null;
    _cache[id] = job;
    notifyListeners();
    return job;
  }

  Future<JobDetail> loadJobDetail(String id) async {
    final detail = await _jobs.getJobDetail(id);
    _cache[id] = detail.job;
    _details[id] = detail;
    notifyListeners();
    return detail;
  }

  Future<HistoryJob> createJob({
    required String propertyId,
    required JobType type,
    required String date,
    required String startTime,
    required String endTime,
    String description = '',
    String? truckAssetId,
  }) async {
    final saved = await _jobs.createJob(
      propertyId: propertyId,
      type: type,
      date: date,
      startTime: startTime,
      endTime: endTime,
      description: description,
      truckAssetId: truckAssetId,
    );
    _cache[saved.id] = saved;
    _details.remove(saved.id);
    if (saved.isOpen) {
      _dispatchJobs = [..._dispatchJobs, saved];
    }
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  Future<HistoryJob> rescheduleJob({
    required String jobId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final saved = await _jobs.rescheduleJob(
      jobId: jobId,
      date: date,
      startTime: startTime,
      endTime: endTime,
    );
    _cache[jobId] = saved;
    _details.remove(jobId);
    _replaceDispatchJob(saved);
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  Future<HistoryJob> cancelJob(String jobId) async {
    final saved = await _jobs.cancelJob(jobId);
    _cache[jobId] = saved;
    _details.remove(jobId);
    _dispatchJobs = [for (final job in _dispatchJobs) if (job.id != jobId) job];
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  Future<void> assignJob({required String jobId, String? technicianId}) async {
    if (_assigningJobId != null) return;
    _assigningJobId = jobId;
    notifyListeners();
    try {
      _realtime?.noteLocalJobMutation(jobId);
      _realtime?.noteLocalAssignmentMutation(jobId);
      final saved = await _jobs.assignJob(jobId: jobId, technicianId: technicianId);
      _cache[jobId] = saved;
      _details.remove(jobId);
      _replaceDispatchJob(saved);
      _refreshToken += 1;
      notifyListeners();
    } finally {
      _assigningJobId = null;
      notifyListeners();
    }
  }

  Future<HistoryJob> setJobTruck({required String jobId, String? truckAssetId}) async {
    final saved = await _jobs.setJobTruck(jobId: jobId, truckAssetId: truckAssetId);
    _cache[jobId] = saved;
    _details.remove(jobId);
    _replaceDispatchJob(saved);
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  List<HistoryJob> assignmentConflicts({required String jobId, String? technicianId}) {
    final job = _cache[jobId];
    if (job == null || technicianId == null) return const [];
    final candidate = job.copyWith(technicianId: technicianId);
    return DispatchSchedule.conflictsFor(
      scheduled: _dispatchJobs,
      candidate: candidate,
      excludeJobId: jobId,
    );
  }

  void _replaceDispatchJob(HistoryJob saved) {
    final index = _dispatchJobs.indexWhere((job) => job.id == saved.id);
    if (!saved.isOpen) {
      if (index >= 0) {
        _dispatchJobs = [..._dispatchJobs]..removeAt(index);
      }
      return;
    }
    if (index >= 0) {
      _dispatchJobs = [..._dispatchJobs]..[index] = saved;
    } else {
      _dispatchJobs = [..._dispatchJobs, saved];
    }
  }
}
