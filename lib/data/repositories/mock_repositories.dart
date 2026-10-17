import 'package:hvac_admin/core/catalog/equipment_type_catalog_data.dart';
import 'package:hvac_admin/core/audit/audit_actions.dart';
import 'package:hvac_admin/core/models/catalog_option.dart';
import 'package:hvac_admin/core/audit/audit_metadata.dart';
import 'package:hvac_admin/core/audit/audit_recording.dart';
import 'package:hvac_admin/core/audit/in_memory_audit_log.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/billing/invoice_policy.dart';
import 'package:hvac_admin/core/models/maintenance_agreement.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/models/office_inventory.dart';
import 'package:hvac_admin/core/models/office_job.dart';
import 'package:hvac_admin/core/models/message_history_filter.dart';
import 'package:hvac_admin/core/models/message_webhook_failure.dart';
import 'package:hvac_admin/core/models/office_message.dart';
import 'package:hvac_admin/core/models/office_payment.dart';
import 'package:hvac_admin/data/datasources/mock_fleet_data.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';
import 'package:hvac_admin/data/pagination/list_paging.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';
import 'package:hvac_admin/data/repositories/billing_repository.dart';
import 'package:hvac_admin/data/repositories/communication_repository.dart';
import 'package:hvac_admin/data/repositories/message_query.dart';
import 'package:hvac_admin/data/repositories/customer_repository.dart';
import 'package:hvac_admin/data/repositories/document_template_repository.dart';
import 'package:hvac_admin/core/models/fleet_asset.dart';
import 'package:hvac_admin/data/repositories/fleet_repository.dart';
import 'package:hvac_admin/data/repositories/inventory_repository.dart';
import 'package:hvac_admin/data/repositories/job_repository.dart';
import 'package:hvac_admin/data/repositories/maintenance_agreement_repository.dart';
import 'package:hvac_admin/data/repositories/technician_repository.dart';

final _sharedSeed = MockSeedData();

class MockCustomerRepository implements CustomerRepository {
  MockCustomerRepository({MockSeedData? seed}) : _seed = seed ?? _sharedSeed;

  final MockSeedData _seed;

  @override
  Future<List<OfficeCustomer>> getCustomers() async => List.unmodifiable(_seed.customers);

  @override
  Future<PagedResult<OfficeCustomer>> getCustomersPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
  }) async {
    final filtered = _seed.customers.where((customer) => _customerMatchesSearch(customer, search)).toList();
    return pageSlice(filtered, offset: offset, limit: limit);
  }

  bool _customerMatchesSearch(OfficeCustomer customer, String? search) {
    final needle = search?.trim();
    if (needle == null || needle.isEmpty) return true;
    final blob =
        '${customer.displayName} ${customer.email} ${customer.phone} ${customer.city} ${customer.state}';
    if (matchesSearch(blob, search)) return true;
    for (final property in _seed.properties) {
      if (property.customerId == customer.id && matchesSearch(property.fullAddress, search)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<OfficeCustomer> saveCustomer(OfficeCustomer customer) async {
    final isNew = customer.id.isEmpty || !MapperHelpers.isUuid(customer.id);
    final saved = isNew
        ? customer.copyWith(id: MapperHelpers.newUuid())
        : customer;
    if (isNew) {
      _seed.customers.add(saved);
    } else {
      final index = _seed.customers.indexWhere((item) => item.id == saved.id);
      if (index >= 0) {
        _seed.customers[index] = saved;
      } else {
        _seed.customers.add(saved);
      }
    }
    return saved;
  }

  @override
  Future<List<OfficeProperty>> getProperties() async => List.unmodifiable(_seed.properties);

  @override
  Future<PagedResult<OfficeProperty>> getPropertiesPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
  }) async {
    final filtered = _seed.properties.where((property) {
      final customer = _seed.customers.where((c) => c.id == property.customerId).firstOrNull;
      final blob = '${property.fullAddress} ${property.label ?? ''} ${customer?.displayName ?? ''}';
      return matchesSearch(blob, search);
    }).toList();
    return pageSlice(filtered, offset: offset, limit: limit);
  }

  @override
  Future<OfficeProperty> saveProperty(OfficeProperty property) async {
    final isNew = property.id.isEmpty || !MapperHelpers.isUuid(property.id);
    final saved = isNew ? property.copyWith(id: MapperHelpers.newUuid()) : property;
    if (isNew) {
      _seed.properties.add(saved);
    } else {
      final index = _seed.properties.indexWhere((item) => item.id == saved.id);
      if (index >= 0) {
        _seed.properties[index] = saved;
      } else {
        _seed.properties.add(saved);
      }
    }
    return saved;
  }

  @override
  Future<OfficeCustomer?> getCustomer(String id) async {
    for (final customer in _seed.customers) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  @override
  Future<List<OfficeProperty>> getPropertiesForCustomer(String customerId) async {
    return [
      for (final property in _seed.properties)
        if (property.customerId == customerId) property,
    ];
  }

  @override
  Future<OfficeProperty?> getProperty(String id) async {
    for (final property in _seed.properties) {
      if (property.id == id) return property;
    }
    return null;
  }

  @override
  Future<List<PropertyEquipment>> getEquipmentForProperty(String propertyId) async {
    return [
      for (final unit in _allEquipment)
        if (unit.propertyId == propertyId) unit,
    ];
  }

  List<PropertyEquipment> get _allEquipment => _seed.equipment;

  final List<CatalogOption> _customEquipmentTypes = [];

  @override
  Future<List<CatalogOption>> getEquipmentTypeCatalog() async {
    return [
      ...EquipmentTypeCatalogData.builtInOptions(),
      ..._customEquipmentTypes,
    ];
  }

  @override
  Future<CatalogOption> addEquipmentTypeOption(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(label, 'label', 'must not be empty');
    final option = CatalogOption(
      key: 'custom_${MapperHelpers.newUuid().replaceAll('-', '')}',
      label: trimmed,
    );
    _customEquipmentTypes.add(option);
    return option;
  }

  bool _matchesWarrantyFilter(PropertyEquipment unit, WarrantyFilter filter) {
    return switch (filter) {
      WarrantyFilter.any => true,
      WarrantyFilter.none => unit.warranties.isEmpty,
      WarrantyFilter.active => unit.warrantyState == WarrantyState.active,
      WarrantyFilter.expiringSoon => unit.warrantyState == WarrantyState.expiringSoon,
      WarrantyFilter.expired => unit.warrantyState == WarrantyState.expired,
    };
  }

  bool _matchesEquipmentSearch(PropertyEquipment unit, String? search) {
    final needle = search?.trim();
    if (needle == null || needle.isEmpty) return true;
    final equipmentBlob =
        '${unit.name} ${unit.serial} ${unit.manufacturer} ${unit.model} ${unit.typeLabel}';
    if (matchesSearch(equipmentBlob, search)) return true;
    final property = _seed.properties.where((item) => item.id == unit.propertyId).firstOrNull;
    if (property == null) return false;
    final customer = _seed.customers.where((item) => item.id == property.customerId).firstOrNull;
    final addressBlob = '${property.fullAddress} ${customer?.displayName ?? ''}';
    return matchesSearch(addressBlob, search);
  }

  @override
  Future<PagedResult<PropertyEquipment>> getEquipmentPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    String? propertyId,
    String? typeKey,
    WarrantyFilter warrantyFilter = WarrantyFilter.any,
  }) async {
    final filtered = [
      for (final unit in _allEquipment)
        if ((propertyId == null || unit.propertyId == propertyId) &&
            (typeKey == null || unit.typeKey == typeKey) &&
            _matchesWarrantyFilter(unit, warrantyFilter) &&
            _matchesEquipmentSearch(unit, search))
          unit,
    ]..sort((a, b) => a.name.compareTo(b.name));
    return pageSlice(filtered, offset: offset, limit: limit);
  }

  @override
  Future<PropertyEquipment?> getEquipmentById(String id) async {
    for (final unit in _allEquipment) {
      if (unit.id == id) return unit;
    }
    return null;
  }

  @override
  Future<PropertyEquipment> saveEquipment(PropertyEquipment equipment) async {
    final isNew = equipment.id.isEmpty || !MapperHelpers.isUuid(equipment.id);
    final saved = isNew ? equipment.copyWith(id: MapperHelpers.newUuid()) : equipment;
    final index = _seed.equipment.indexWhere((item) => item.id == saved.id);
    if (index >= 0) {
      _seed.equipment[index] = saved;
    } else {
      _seed.equipment.add(saved);
    }
    return saved;
  }

  @override
  Future<PropertyWarranty> saveWarranty({
    required String equipmentId,
    required PropertyWarranty warranty,
  }) async {
    final index = _seed.equipment.indexWhere((item) => item.id == equipmentId);
    if (index < 0) throw StateError('Equipment not found');
    final unit = _seed.equipment[index];
    final updated = unit.copyWith(warranties: [...unit.warranties, warranty]);
    _seed.equipment[index] = updated;
    return warranty;
  }

  @override
  Future<PagedResult<WarrantyArchiveEntry>> searchWarranties({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
  }) async {
    final entries = <WarrantyArchiveEntry>[];
    for (final unit in _allEquipment) {
      if (unit.warranties.isEmpty) continue;
      final property = _seed.properties.where((item) => item.id == unit.propertyId).firstOrNull;
      if (property == null) continue;
      final customer = _seed.customers.where((item) => item.id == property.customerId).firstOrNull;
      final customerName = customer?.displayName ?? '';
      final blob = '${unit.serial} ${unit.manufacturer} ${unit.model} ${property.fullAddress} $customerName';
      if (!matchesSearch(blob, search)) continue;
      for (final warranty in unit.warranties) {
        entries.add(
          WarrantyArchiveEntry(
            equipmentId: unit.id,
            equipmentName: unit.name,
            manufacturer: unit.manufacturer,
            model: unit.model,
            serial: unit.serial,
            warranty: warranty,
            propertyId: property.id,
            propertyAddress: property.fullAddress,
            customerName: customerName,
          ),
        );
      }
    }
    entries.sort((a, b) => a.warranty.expiresOn.compareTo(b.warranty.expiresOn));
    return pageSlice(entries, offset: offset, limit: limit);
  }

  @override
  Future<PropertyHistory> getPropertyHistory(String propertyId) async {
    final jobs = [
      for (final job in _seed.jobs)
        if (job.propertyId == propertyId) job,
    ]..sort((a, b) => b.date.compareTo(a.date));

    final equipment = [
      for (final unit in _seed.equipment)
        if (unit.propertyId == propertyId) unit,
    ];

    final warranties = [for (final unit in equipment) ...unit.warranties];

    final estimates = [
      for (final estimate in _seed.estimates)
        if (estimate.propertyId == propertyId)
          MoneyRecord(
            id: estimate.id,
            number: estimate.number,
            status: estimate.status.label,
            amount: estimate.amount,
            date: estimate.date,
          ),
    ];

    final invoices = [
      for (final invoice in _seed.invoices)
        if (invoice.propertyId == propertyId)
          MoneyRecord(
            id: invoice.id,
            number: invoice.number,
            status: invoice.status.label,
            amount: invoice.amount,
            date: invoice.date,
          ),
    ];

    final technicians = <String>{
      for (final job in jobs)
        if (job.technicianName.isNotEmpty && job.technicianName != 'Unassigned') job.technicianName,
    }.toList();

    final timeline = <TimelineEvent>[
      for (final job in jobs)
        TimelineEvent(
          at: job.date,
          title: '${job.jobNumber} · ${job.status.label}',
          detail: job.description.isEmpty ? job.type.label : job.description,
        ),
      for (final job in jobs.where((job) => job.status == JobStatus.completed))
        TimelineEvent(
          at: job.date,
          title: 'Completed ${job.jobNumber}',
          detail: 'Technician: ${job.technicianName}',
        ),
      for (final message in _seed.messages)
        if (message.entityType == CommunicationEntityType.customer &&
            _seed.customers.any((c) => c.id == message.entityId && c.propertyIds.contains(propertyId)))
          TimelineEvent(at: message.at, title: 'Message', detail: message.body),
      for (final agreement in _seed.maintenanceAgreements)
        if (agreement.propertyId == propertyId)
          TimelineEvent(
            at: agreement.startOn,
            title: 'Maintenance · ${agreement.title}',
            detail: '${agreement.frequency.label} plan · ${agreement.status.label}',
          ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return PropertyHistory(
      jobs: jobs,
      equipment: equipment,
      warranties: warranties,
      photos: [for (final unit in equipment) ...unit.photos],
      documents: [for (final unit in equipment) ...unit.manuals],
      estimates: estimates,
      invoices: invoices,
      technicians: technicians,
      timeline: timeline,
    );
  }
}

class MockJobRepository implements JobRepository {
  MockJobRepository({MockSeedData? seed, InMemoryAuditLog? auditLog})
      : _seed = seed ?? _sharedSeed,
        _auditLog = auditLog;

  final MockSeedData _seed;
  final InMemoryAuditLog? _auditLog;
  final Map<String, List<JobStatusEvent>> _statusHistory = {};

  List<HistoryJob> get _allJobs => _seed.jobs;

  int _nextJobNumber() {
    var max = 10000;
    for (final job in _allJobs) {
      final parsed = int.tryParse(job.jobNumber.replaceAll(RegExp(r'\D'), '')) ?? 0;
      if (parsed > max) max = parsed;
    }
    return max + 1;
  }

  void _recordStatus(String jobId, JobActivityKind kind, {String? label}) {
    _statusHistory.putIfAbsent(jobId, () => []).insert(
          0,
          JobStatusEvent(at: DateTime.now().toUtc().toIso8601String(), kind: kind, label: label),
        );
  }

  bool _matchesJobFilters(
    HistoryJob job, {
    JobStatus? status,
    String? technicianId,
    String? customerId,
    String? dateFrom,
    String? dateTo,
  }) {
    if (status != null && job.status != status) return false;
    if (technicianId != null && job.technicianId != technicianId) return false;
    if (customerId != null) {
      final property = _seed.properties.where((item) => item.id == job.propertyId).firstOrNull;
      if (property == null || property.customerId != customerId) return false;
    }
    if (dateFrom != null && dateFrom.isNotEmpty && job.date.compareTo(dateFrom) < 0) return false;
    if (dateTo != null && dateTo.isNotEmpty && job.date.compareTo(dateTo) > 0) return false;
    return true;
  }

  bool _matchesJobSearch(HistoryJob job, String? search) {
    final needle = search?.trim();
    if (needle == null || needle.isEmpty) return true;
    final jobBlob = '${job.jobNumber} ${job.description} ${job.technicianName} ${job.type.label}';
    if (matchesSearch(jobBlob, search)) return true;
    final property = _seed.properties.where((item) => item.id == job.propertyId).firstOrNull;
    if (property == null) return false;
    final customer = _seed.customers.where((item) => item.id == property.customerId).firstOrNull;
    return matchesSearch('${property.fullAddress} ${customer?.displayName ?? ''}', search);
  }

  @override
  Future<List<HistoryJob>> getJobs() async => List.unmodifiable(_allJobs);

  @override
  Future<PagedResult<HistoryJob>> getJobsPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    JobStatus? status,
    String? technicianId,
    String? customerId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final filtered = [
      for (final job in _allJobs)
        if (_matchesJobFilters(
              job,
              status: status,
              technicianId: technicianId,
              customerId: customerId,
              dateFrom: dateFrom,
              dateTo: dateTo,
            ) &&
            _matchesJobSearch(job, search))
          job,
    ]..sort((a, b) => b.date.compareTo(a.date));
    return pageSlice(filtered, offset: offset, limit: limit);
  }

  @override
  Future<HistoryJob?> getJob(String id) async {
    for (final job in _allJobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  @override
  Future<JobDetail> getJobDetail(String id) async {
    final job = await getJob(id);
    if (job == null) throw StateError('Job not found: $id');
    final equipment = [
      for (final unit in _seed.equipment)
        if (unit.serviceJobIds.contains(id)) unit,
    ];
    return JobDetail(
      job: job,
      statusHistory: List.unmodifiable(_statusHistory[id] ?? const []),
      equipment: equipment,
      photos: const [],
      documents: const [],
    );
  }

  @override
  Future<HistoryJob> createJob({
    required String propertyId,
    required JobType type,
    required String date,
    required String startTime,
    required String endTime,
    String description = '',
    String? truckAssetId,
  }) async {
    final number = _nextJobNumber();
    final job = HistoryJob(
      id: MapperHelpers.newUuid(),
      propertyId: propertyId,
      jobNumber: 'JOB-$number',
      type: type,
      status: JobStatus.unassigned,
      priority: JobPriority.normal,
      date: date,
      startTime: startTime,
      endTime: endTime,
      technicianName: 'Unassigned',
      truckAssetId: truckAssetId,
      description: description,
    );
    _seed.jobs.add(job);
    _recordStatus(job.id, JobActivityKind.scheduled);
    return job;
  }

  @override
  Future<HistoryJob> rescheduleJob({
    required String jobId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final current = await getJob(jobId);
    if (current == null) throw StateError('Job not found: $jobId');
    final updated = current.copyWith(date: date, startTime: startTime, endTime: endTime);
    final index = _seed.jobs.indexWhere((item) => item.id == jobId);
    if (index >= 0) _seed.jobs[index] = updated;
    _recordStatus(jobId, JobActivityKind.scheduled, label: 'Rescheduled');
    return updated;
  }

  @override
  Future<HistoryJob> cancelJob(String jobId) async {
    final current = await getJob(jobId);
    if (current == null) throw StateError('Job not found: $jobId');
    final updated = current.copyWith(status: JobStatus.cancelled);
    final index = _seed.jobs.indexWhere((item) => item.id == jobId);
    if (index >= 0) _seed.jobs[index] = updated;
    _recordStatus(jobId, JobActivityKind.jobCompleted, label: 'Cancelled by office');
    return updated;
  }

  @override
  Future<HistoryJob> assignJob({required String jobId, String? technicianId}) async {
    final current = await getJob(jobId);
    if (current == null) throw StateError('Job not found: $jobId');
    final previousTechId = current.technicianId;
    final updated = _assign(current, technicianId);
    final index = _seed.jobs.indexWhere((item) => item.id == jobId);
    if (index >= 0) {
      _seed.jobs[index] = updated;
    }
    if (technicianId == null) {
      _recordStatus(jobId, JobActivityKind.assigned, label: 'Unassigned');
    } else {
      _recordStatus(jobId, JobActivityKind.assigned);
    }
    if (previousTechId != technicianId) {
      final reassigned = previousTechId != null && technicianId != null;
      recordMockAudit(
        _auditLog,
        action: technicianId == null
            ? AuditActions.jobUnassign
            : (reassigned ? AuditActions.jobReassign : AuditActions.jobAssign),
        entityType: 'job',
        entityId: jobId,
        metadata: AuditMetadata.jobAssignment(
          beforeTechnicianId: previousTechId,
          afterTechnicianId: technicianId,
          reassigned: reassigned,
        ),
      );
    }
    return updated;
  }

  @override
  Future<HistoryJob> setJobTruck({required String jobId, String? truckAssetId}) async {
    final current = await getJob(jobId);
    if (current == null) throw StateError('Job not found: $jobId');
    final updated = truckAssetId == null || truckAssetId.isEmpty
        ? current.copyWith(clearTruckAssetId: true)
        : current.copyWith(truckAssetId: truckAssetId);
    final index = _seed.jobs.indexWhere((item) => item.id == jobId);
    if (index >= 0) _seed.jobs[index] = updated;
    return updated;
  }

  HistoryJob _assign(HistoryJob current, String? technicianId) {
    var status = current.status;
    if (technicianId == null) {
      if (current.isOpen) status = JobStatus.unassigned;
    } else if (status == JobStatus.unassigned || status == JobStatus.scheduled) {
      status = JobStatus.assigned;
    }
    OfficeTechnician? technician;
    if (technicianId != null) {
      for (final item in _seed.technicians) {
        if (item.id == technicianId) {
          technician = item;
          break;
        }
      }
    }
    return current.copyWith(
      status: status,
      technicianName: technician?.displayName ?? 'Unassigned',
      technicianId: technicianId,
      clearTechnicianId: technicianId == null,
    );
  }
}

class MockTechnicianRepository implements TechnicianRepository {
  MockTechnicianRepository({MockSeedData? seed}) : _seed = seed ?? _sharedSeed;

  final MockSeedData _seed;

  @override
  Future<List<OfficeTechnician>> getTechnicians() async => List.unmodifiable(_seed.technicians);

  @override
  Future<OfficeTechnician?> getTechnician(String id) async {
    for (final tech in _seed.technicians) {
      if (tech.id == id) return tech;
    }
    return null;
  }

  @override
  Future<List<TechnicianActivity>> getTechnicianActivity(String technicianId) async {
    return List.unmodifiable(_seed.technicianActivity[technicianId] ?? const []);
  }

  @override
  Future<TechnicianDetail> getTechnicianDetail(String id) async {
    final technician = await getTechnician(id);
    if (technician == null) throw StateError('Technician not found: $id');
    final activity = await getTechnicianActivity(id);
    final recentJobs = [
      for (final job in _seed.jobs)
        if (job.technicianId == id) job,
    ]..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        return b.startTime.compareTo(a.startTime);
      });
    return TechnicianDetail(
      technician: technician,
      activity: activity,
      recentJobs: recentJobs,
    );
  }

  @override
  Future<OfficeTechnician> saveTechnician({
    String? id,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    String? profileId,
    TechnicianStatus status = TechnicianStatus.available,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    if (id != null) {
      for (var i = 0; i < _seed.technicians.length; i++) {
        final current = _seed.technicians[i];
        if (current.id != id) continue;
        final saved = current.copyWith(
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          email: email,
          profileId: profileId,
          status: status,
          lastUpdated: now,
        );
        _seed.technicians[i] = saved;
        return saved;
      }
      throw StateError('Technician not found: $id');
    }

    final saved = OfficeTechnician(
      id: 'tech-${DateTime.now().microsecondsSinceEpoch}',
      firstName: firstName,
      lastName: lastName,
      status: status,
      latitude: 39.7817,
      longitude: -89.6501,
      lastAddress: 'Arctic HVAC Solutions shop, Springfield',
      lastUpdated: now,
      profileId: profileId,
      phone: phone,
      email: email,
    );
    _seed.technicians.add(saved);
    return saved;
  }

  @override
  Future<OfficeTechnician> setAccountEnabled({required String id, required bool enabled}) async {
    for (var i = 0; i < _seed.technicians.length; i++) {
      final current = _seed.technicians[i];
      if (current.id != id) continue;
      final saved = current.copyWith(accountEnabled: enabled);
      _seed.technicians[i] = saved;
      return saved;
    }
    throw StateError('Technician not found: $id');
  }
}

class MockBillingRepository implements BillingRepository {
  MockBillingRepository({MockSeedData? seed, InMemoryAuditLog? auditLog})
      : _seed = seed ?? _sharedSeed,
        _auditLog = auditLog;

  final MockSeedData _seed;
  final InMemoryAuditLog? _auditLog;

  @override
  Future<List<OfficeEstimate>> getEstimates({EstimateStatus? status}) async {
    return _filterEstimates(status: status);
  }

  @override
  Future<PagedResult<OfficeEstimate>> getEstimatesPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    EstimateStatus? status,
  }) async {
    final filtered = _filterEstimates(status: status, search: search);
    return pageSlice(filtered, offset: offset, limit: limit);
  }

  @override
  Future<OfficeEstimate?> getEstimate(String id) async {
    for (final estimate in _seed.estimates) {
      if (estimate.id == id) return estimate;
    }
    return null;
  }

  @override
  Future<OfficeEstimate> saveEstimate(OfficeEstimate estimate) async {
    final index = _seed.estimates.indexWhere((item) => item.id == estimate.id);
    if (index >= 0) {
      _seed.estimates[index] = estimate;
    } else {
      _seed.estimates.insert(0, estimate);
    }
    return estimate;
  }

  @override
  Future<OfficeEstimate> updateEstimateStatus(String id, EstimateStatus status) async {
    final estimate = await getEstimate(id);
    if (estimate == null) throw StateError('Estimate not found: $id');
    return saveEstimate(estimate.copyWith(status: status));
  }

  @override
  Future<OfficeInvoice?> getInvoiceForEstimate(String estimateId) async {
    for (final invoice in _seed.invoices) {
      if (invoice.estimateId == estimateId) return invoice;
    }
    return null;
  }

  @override
  Future<OfficeInvoice> convertEstimateToInvoice(String estimateId) async {
    final existing = await getInvoiceForEstimate(estimateId);
    if (existing != null) return existing;
    final estimate = await getEstimate(estimateId);
    if (estimate == null) throw StateError('Estimate not found: $estimateId');
    final due = DateTime.parse('${estimate.date}T00:00:00').add(const Duration(days: 14));
    final invoice = OfficeInvoice(
      id: 'inv_${DateTime.now().microsecondsSinceEpoch}',
      number: 'INV-${estimate.number.replaceFirst('EST-', '')}',
      status: InvoiceStatus.draft,
      date: estimate.date,
      dueDate: due.toIso8601String().split('T').first,
      propertyId: estimate.propertyId,
      jobId: estimate.jobId,
      estimateId: estimate.id,
      notes: estimate.notes,
      items: estimate.items,
    );
    _seed.invoices.insert(0, invoice);
    return invoice;
  }

  List<OfficeEstimate> _filterEstimates({EstimateStatus? status, String? search}) {
    return _seed.estimates.where((estimate) {
      if (status != null && estimate.status != status) return false;
      return matchesSearch('${estimate.number} ${estimate.notes}', search);
    }).toList();
  }

  @override
  Future<List<OfficeInvoice>> getInvoices({InvoiceStatus? status}) async {
    await _syncOverdueStatuses();
    return _filterInvoices(status: status);
  }

  @override
  Future<PagedResult<OfficeInvoice>> getInvoicesPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    InvoiceStatus? status,
    bool overdueOnly = false,
    double? minAmount,
  }) async {
    await _syncOverdueStatuses();
    final filtered = _filterInvoices(
      status: status,
      search: search,
      overdueOnly: overdueOnly,
      minAmount: minAmount,
    );
    return pageSlice(filtered, offset: offset, limit: limit);
  }

  @override
  Future<OfficeInvoice?> getInvoice(String id) async {
    await _syncOverdueStatuses();
    for (final invoice in _seed.invoices) {
      if (invoice.id == id) return InvoicePolicy.withEffectiveStatus(invoice);
    }
    return null;
  }

  @override
  Future<OfficeInvoice> saveInvoice(OfficeInvoice invoice) async {
    final index = _seed.invoices.indexWhere((item) => item.id == invoice.id);
    if (index >= 0) {
      _seed.invoices[index] = invoice;
    } else {
      _seed.invoices.insert(0, invoice);
    }
    return invoice;
  }

  @override
  Future<OfficeInvoice> updateInvoiceStatus(String id, InvoiceStatus status) async {
    final invoice = await getInvoice(id);
    if (invoice == null) throw StateError('Invoice not found: $id');
    final before = invoice.status;
    final saved = await saveInvoice(invoice.copyWith(status: status));
    if (before != status) {
      recordMockAudit(
        _auditLog,
        action: status == InvoiceStatus.cancelled ? AuditActions.invoiceVoid : AuditActions.invoiceStatus,
        entityType: 'invoice',
        entityId: id,
        metadata: AuditMetadata.invoiceStatusChange(
          invoiceId: id,
          number: saved.number,
          beforeStatus: before.name,
          afterStatus: status.name,
          amount: saved.amount,
        ),
      );
    }
    return saved;
  }

  Future<void> _syncOverdueStatuses() async {
    for (var i = 0; i < _seed.invoices.length; i++) {
      final invoice = _seed.invoices[i];
      if (invoice.status == InvoiceStatus.sent && InvoicePolicy.isPastDue(invoice)) {
        _seed.invoices[i] = invoice.copyWith(status: InvoiceStatus.overdue);
      }
    }
  }

  List<OfficeInvoice> _filterInvoices({
    InvoiceStatus? status,
    String? search,
    bool overdueOnly = false,
    double? minAmount,
  }) {
    return _seed.invoices.where((invoice) {
      final effective = InvoicePolicy.withEffectiveStatus(invoice);
      if (overdueOnly && effective.status != InvoiceStatus.overdue) return false;
      if (status != null && effective.status != status) return false;
      if (minAmount != null && effective.amount < minAmount) return false;
      return matchesSearch('${effective.number} ${effective.notes}', search);
    }).toList();
  }

  @override
  Future<List<OfficePayment>> getPayments({String? invoiceId}) async {
    return [
      for (final payment in _seed.payments)
        if (invoiceId == null || payment.invoiceId == invoiceId) payment,
    ];
  }

  @override
  Future<OfficePayment?> paymentByProviderId(String provider, String providerPaymentId) async {
    for (final payment in _seed.payments) {
      if (payment.provider == provider && payment.providerPaymentId == providerPaymentId) {
        return payment;
      }
    }
    return null;
  }

  @override
  Future<OfficePayment> savePayment(OfficePayment payment) async {
    final index = _seed.payments.indexWhere((item) => item.id == payment.id);
    if (index < 0) {
      _seed.payments.insert(0, payment);
    } else {
      _seed.payments[index] = payment;
    }
    return payment;
  }
}

class MockCommunicationRepository implements CommunicationRepository {
  MockCommunicationRepository({MockSeedData? seed}) : _seed = seed ?? _sharedSeed;

  final MockSeedData _seed;
  final List<MessageWebhookFailure> _webhookFailures = [];

  /// Simulates server-side webhook ingestion (inbound SMS/email).
  Future<OfficeMessage> ingestInbound({
    required CommunicationChannel channel,
    required CommunicationEntityType entityType,
    required String entityId,
    required String entityLabel,
    required String body,
    String toAddress = '',
    String? providerMessageId,
  }) async {
    final message = OfficeMessage(
      id: 'msg_inbound_${DateTime.now().microsecondsSinceEpoch}',
      at: DateTime.now().toUtc().toIso8601String(),
      channel: channel,
      direction: MessageDirection.inbound,
      entityType: entityType,
      entityId: entityId,
      entityLabel: entityLabel,
      body: body,
      deliveryStatus: 'received',
      toAddress: toAddress,
      provider: 'mock-webhook',
      providerMessageId: providerMessageId,
    );
    return save(message);
  }

  @override
  Future<List<OfficeMessage>> getMessages({
    CommunicationEntityType? entityType,
    String? entityId,
    List<MessageEntityRef>? entities,
    MessageHistoryFilter? filter,
    int limit = 200,
  }) async {
    return _sorted(
      MessageQuery.apply(
        messages: _seed.messages,
        entityType: entityType,
        entityId: entityId,
        entities: entities,
        filter: filter,
      ),
    ).take(limit).toList();
  }

  @override
  Future<PagedResult<OfficeMessage>> getMessagesPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    CommunicationEntityType? entityType,
    String? entityId,
    List<MessageEntityRef>? entities,
    MessageHistoryFilter? filter,
  }) async {
    final filtered = _sorted(
      MessageQuery.apply(
        messages: _seed.messages,
        entityType: entityType,
        entityId: entityId,
        entities: entities,
        filter: filter,
        search: search,
      ),
    ).toList();
    return pageSlice(filtered, offset: offset, limit: limit);
  }

  @override
  Future<OfficeMessage> save(OfficeMessage message) async {
    _seed.messages.insert(0, message);
    return message;
  }

  @override
  Future<List<MessageWebhookFailure>> getWebhookFailures({int limit = 10}) async {
    if (_webhookFailures.length <= limit) return List.unmodifiable(_webhookFailures);
    return List.unmodifiable(_webhookFailures.take(limit));
  }

  Iterable<OfficeMessage> _sorted(Iterable<OfficeMessage> messages) {
    final list = [...messages]..sort((a, b) => b.at.compareTo(a.at));
    return list;
  }
}

class MockInventoryRepository implements InventoryRepository {
  MockInventoryRepository({MockSeedData? seed}) : _seed = seed ?? _sharedSeed;

  final MockSeedData _seed;

  @override
  Future<List<InventoryItem>> getItems() async => List.unmodifiable(_seed.inventoryItems);

  @override
  Future<PagedResult<InventoryItem>> getItemsPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
  }) async {
    final filtered = _seed.inventoryItems
        .where((item) => matchesSearch('${item.sku} ${item.name} ${item.category}', search))
        .toList();
    return pageSlice(filtered, offset: offset, limit: limit);
  }

  @override
  Future<List<InventoryLocation>> getLocations() async => List.unmodifiable(_seed.inventoryLocations);

  @override
  Future<List<LocationStock>> getStocks() async => List.unmodifiable(_seed.inventoryStocks);

  @override
  Future<List<StockMovement>> getMovements({String? itemId}) async {
    return [
      for (final movement in _seed.inventoryMovements)
        if (itemId == null || movement.itemId == itemId) movement,
    ];
  }

  @override
  Future<InventoryItem> saveItem(InventoryItem item) async {
    final index = _seed.inventoryItems.indexWhere((entry) => entry.id == item.id);
    if (index < 0) {
      _seed.inventoryItems.insert(0, item);
    } else {
      _seed.inventoryItems[index] = item;
    }
    return item;
  }

  @override
  Future<InventoryLocation> saveLocation(InventoryLocation location) async {
    final index = _seed.inventoryLocations.indexWhere((entry) => entry.id == location.id);
    if (index < 0) {
      _seed.inventoryLocations.add(location);
    } else {
      _seed.inventoryLocations[index] = location;
    }
    return location;
  }

  @override
  Future<void> saveStock(LocationStock stock) async {
    final index = _seed.inventoryStocks.indexWhere(
      (entry) => entry.locationId == stock.locationId && entry.itemId == stock.itemId,
    );
    if (index < 0) {
      _seed.inventoryStocks.add(stock);
    } else {
      _seed.inventoryStocks[index] = stock;
    }
  }

  @override
  Future<void> saveMovement(StockMovement movement) async {
    _seed.inventoryMovements.insert(0, movement);
  }
}

class MockFleetRepository implements FleetRepository {
  MockFleetRepository({MockFleetData? data}) : _data = data ?? _sharedFleetData;

  static final _sharedFleetData = MockFleetData();

  final MockFleetData _data;

  @override
  Future<List<FleetAsset>> getAssets() async => List.unmodifiable(_data.assets);

  @override
  Future<List<FleetAssignment>> getAssignmentHistory(String fleetAssetId) async {
    final rows = [
      for (final row in _data.assignments)
        if (row.fleetAssetId == fleetAssetId) row,
    ];
    rows.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
    return rows;
  }

  @override
  Future<FleetAsset> saveAsset(FleetAsset asset) async {
    final index = _data.assets.indexWhere((item) => item.id == asset.id);
    if (index < 0) {
      final saved = asset.id.isEmpty
          ? FleetAsset(
              id: 'fleet-${DateTime.now().microsecondsSinceEpoch}',
              kind: asset.kind,
              label: asset.label,
              identifier: asset.identifier,
              inventoryLocationId: asset.inventoryLocationId,
              currentTechnicianId: asset.currentTechnicianId,
              isActive: asset.isActive,
            )
          : asset;
      _data.assets = [..._data.assets, saved];
      return saved;
    }
    final copy = [..._data.assets];
    copy[index] = asset;
    _data.assets = copy;
    return asset;
  }

  @override
  Future<FleetAsset> assignAsset({
    required String fleetAssetId,
    required String technicianId,
    String notes = '',
  }) async {
    final index = _data.assets.indexWhere((item) => item.id == fleetAssetId);
    if (index < 0) throw StateError('Fleet asset not found: $fleetAssetId');

    final now = DateTime.now().toUtc().toIso8601String();
    final updatedAssignments = <FleetAssignment>[
      for (final row in _data.assignments)
        if (row.fleetAssetId == fleetAssetId && row.isOpen)
          FleetAssignment(
            id: row.id,
            fleetAssetId: row.fleetAssetId,
            technicianId: row.technicianId,
            assignedAt: row.assignedAt,
            unassignedAt: now,
            notes: row.notes,
          )
        else
          row,
      FleetAssignment(
        id: 'fa_${_data.assignments.length + 1}',
        fleetAssetId: fleetAssetId,
        technicianId: technicianId,
        assignedAt: now,
        notes: notes,
      ),
    ];
    _data.assignments = updatedAssignments;

    final asset = _data.assets[index].copyWith(currentTechnicianId: technicianId);
    _data.assets[index] = asset;
    return asset;
  }

  @override
  Future<FleetAsset> unassignAsset({required String fleetAssetId, String notes = ''}) async {
    final index = _data.assets.indexWhere((item) => item.id == fleetAssetId);
    if (index < 0) throw StateError('Fleet asset not found: $fleetAssetId');

    final now = DateTime.now().toUtc().toIso8601String();
    _data.assignments = [
      for (final row in _data.assignments)
        if (row.fleetAssetId == fleetAssetId && row.isOpen)
          FleetAssignment(
            id: row.id,
            fleetAssetId: row.fleetAssetId,
            technicianId: row.technicianId,
            assignedAt: row.assignedAt,
            unassignedAt: now,
            notes: notes.isEmpty ? row.notes : '${row.notes} $notes'.trim(),
          )
        else
          row,
    ];

    final asset = _data.assets[index].copyWith(clearTechnician: true);
    _data.assets[index] = asset;
    return asset;
  }
}

class MockMaintenanceAgreementRepository implements MaintenanceAgreementRepository {
  MockMaintenanceAgreementRepository({MockSeedData? seed}) : _seed = seed ?? _sharedSeed;

  final MockSeedData _seed;

  @override
  Future<List<MaintenanceAgreement>> getAgreements() async => List.unmodifiable(_seed.maintenanceAgreements);

  @override
  Future<MaintenanceAgreement?> getAgreement(String id) async {
    for (final agreement in _seed.maintenanceAgreements) {
      if (agreement.id == id) return agreement;
    }
    return null;
  }

  @override
  Future<MaintenanceAgreement> saveAgreement(
    MaintenanceAgreement agreement, {
    double? annualAmount,
  }) async {
    final saved = annualAmount == null
        ? agreement
        : agreement.copyWith(annualAmount: annualAmount);
    final index = _seed.maintenanceAgreements.indexWhere((item) => item.id == saved.id);
    if (index < 0) {
      _seed.maintenanceAgreements.add(saved);
    } else {
      _seed.maintenanceAgreements[index] = saved;
    }
    return saved;
  }
}

