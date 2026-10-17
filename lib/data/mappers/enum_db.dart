import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_job.dart';

/// Flutter enum ↔ Postgres enum (`snake_case`) conversions.
abstract final class EnumDb {
  static String jobStatus(JobStatus value) => switch (value) {
        JobStatus.unassigned => 'unassigned',
        JobStatus.scheduled => 'scheduled',
        JobStatus.assigned => 'assigned',
        JobStatus.onTheWay => 'on_the_way',
        JobStatus.arrived => 'arrived',
        JobStatus.inProgress => 'in_progress',
        JobStatus.completed => 'completed',
        JobStatus.cancelled => 'cancelled',
      };

  static JobStatus jobStatusFromDb(String value) => switch (value) {
        'unassigned' => JobStatus.unassigned,
        'scheduled' => JobStatus.scheduled,
        'assigned' => JobStatus.assigned,
        'on_the_way' => JobStatus.onTheWay,
        'arrived' => JobStatus.arrived,
        'in_progress' => JobStatus.inProgress,
        'completed' => JobStatus.completed,
        'cancelled' => JobStatus.cancelled,
        _ => JobStatus.unassigned,
      };

  static String technicianStatus(TechnicianStatus value) => switch (value) {
        TechnicianStatus.available => 'available',
        TechnicianStatus.assigned => 'assigned',
        TechnicianStatus.onTheWay => 'on_the_way',
        TechnicianStatus.onJob => 'on_job',
        TechnicianStatus.driving => 'driving',
        TechnicianStatus.offDuty => 'off_duty',
      };

  static TechnicianStatus technicianStatusFromDb(String value) => switch (value) {
        'available' => TechnicianStatus.available,
        'assigned' => TechnicianStatus.assigned,
        'on_the_way' => TechnicianStatus.onTheWay,
        'on_job' => TechnicianStatus.onJob,
        'driving' => TechnicianStatus.driving,
        'off_duty' => TechnicianStatus.offDuty,
        _ => TechnicianStatus.available,
      };

  static String propertyType(PropertyType value) => switch (value) {
        PropertyType.residential => 'residential',
        PropertyType.commercial => 'commercial',
        PropertyType.multiFamily => 'multi_family',
      };

  static PropertyType propertyTypeFromDb(String value) => switch (value) {
        'residential' => PropertyType.residential,
        'commercial' => PropertyType.commercial,
        'multi_family' => PropertyType.multiFamily,
        _ => PropertyType.residential,
      };

  static String equipmentType(EquipmentType value) => switch (value) {
        EquipmentType.centralAc => 'central_ac',
        EquipmentType.heatPump => 'heat_pump',
        EquipmentType.furnace => 'furnace',
        EquipmentType.miniSplit => 'mini_split',
        EquipmentType.airHandler => 'air_handler',
        EquipmentType.condenser => 'condenser',
        EquipmentType.packageUnit => 'package_unit',
      };

  static EquipmentType equipmentTypeFromDb(String value) => switch (value) {
        'central_ac' => EquipmentType.centralAc,
        'heat_pump' => EquipmentType.heatPump,
        'furnace' => EquipmentType.furnace,
        'mini_split' => EquipmentType.miniSplit,
        'air_handler' => EquipmentType.airHandler,
        'condenser' => EquipmentType.condenser,
        'package_unit' => EquipmentType.packageUnit,
        _ => EquipmentType.centralAc,
      };

  static String jobType(JobType value) => switch (value) {
        JobType.acNotCooling => 'ac_not_cooling',
        JobType.preventiveMaintenance => 'preventive_maintenance',
        JobType.furnaceRepair => 'furnace_repair',
        JobType.diagnostic => 'diagnostic',
        JobType.emergencyService => 'emergency_service',
        JobType.newInstallation => 'new_installation',
        JobType.refrigerantLeak => 'refrigerant_leak',
        JobType.thermostatReplacement => 'thermostat_replacement',
      };

  static JobType jobTypeFromDb(String value) => switch (value) {
        'ac_not_cooling' => JobType.acNotCooling,
        'preventive_maintenance' => JobType.preventiveMaintenance,
        'furnace_repair' => JobType.furnaceRepair,
        'diagnostic' => JobType.diagnostic,
        'emergency_service' => JobType.emergencyService,
        'new_installation' => JobType.newInstallation,
        'refrigerant_leak' => JobType.refrigerantLeak,
        'thermostat_replacement' => JobType.thermostatReplacement,
        _ => JobType.diagnostic,
      };

  static String jobPriority(JobPriority value) => switch (value) {
        JobPriority.low => 'low',
        JobPriority.normal => 'normal',
        JobPriority.high => 'high',
        JobPriority.urgent => 'urgent',
      };

  static JobPriority jobPriorityFromDb(String value) => switch (value) {
        'low' => JobPriority.low,
        'normal' => JobPriority.normal,
        'high' => JobPriority.high,
        'urgent' => JobPriority.urgent,
        _ => JobPriority.normal,
      };

  static String invoiceStatus(InvoiceStatus value) => switch (value) {
        InvoiceStatus.draft => 'draft',
        InvoiceStatus.sent => 'sent',
        InvoiceStatus.paid => 'paid',
        InvoiceStatus.overdue => 'overdue',
        InvoiceStatus.cancelled => 'cancelled',
      };

  static InvoiceStatus invoiceStatusFromDb(String value) => switch (value) {
        'draft' => InvoiceStatus.draft,
        'sent' => InvoiceStatus.sent,
        'paid' => InvoiceStatus.paid,
        'overdue' => InvoiceStatus.overdue,
        'cancelled' => InvoiceStatus.cancelled,
        _ => InvoiceStatus.draft,
      };

  static String estimateStatus(EstimateStatus value) => switch (value) {
        EstimateStatus.draft => 'draft',
        EstimateStatus.sent => 'sent',
        EstimateStatus.approved => 'approved',
        EstimateStatus.declined => 'declined',
        EstimateStatus.expired => 'expired',
      };

  static EstimateStatus estimateStatusFromDb(String value) => switch (value) {
        'draft' => EstimateStatus.draft,
        'sent' => EstimateStatus.sent,
        'approved' => EstimateStatus.approved,
        'declined' => EstimateStatus.declined,
        'expired' => EstimateStatus.expired,
        _ => EstimateStatus.draft,
      };

  static String communicationChannel(CommunicationChannel value) => switch (value) {
        CommunicationChannel.sms => 'sms',
        CommunicationChannel.email => 'email',
        CommunicationChannel.system => 'system',
      };

  static CommunicationChannel communicationChannelFromDb(String value) => switch (value) {
        'email' => CommunicationChannel.email,
        'system' => CommunicationChannel.system,
        _ => CommunicationChannel.sms,
      };

  static String messageDirection(MessageDirection value) => switch (value) {
        MessageDirection.inbound => 'inbound',
        MessageDirection.outbound => 'outbound',
      };

  static MessageDirection messageDirectionFromDb(String value) => switch (value) {
        'inbound' => MessageDirection.inbound,
        _ => MessageDirection.outbound,
      };

  static String communicationEntityType(CommunicationEntityType value) => switch (value) {
        CommunicationEntityType.customer => 'customer',
        CommunicationEntityType.property => 'property',
        CommunicationEntityType.job => 'job',
      };

  static CommunicationEntityType communicationEntityTypeFromDb(String value) => switch (value) {
        'property' => CommunicationEntityType.property,
        'job' => CommunicationEntityType.job,
        _ => CommunicationEntityType.customer,
      };

  static String stockLocationKind(StockLocationKind value) => switch (value) {
        StockLocationKind.warehouse => 'warehouse',
        StockLocationKind.truck => 'truck',
        StockLocationKind.device => 'device',
      };

  static StockLocationKind stockLocationKindFromDb(String value) => switch (value) {
        'truck' => StockLocationKind.truck,
        'device' => StockLocationKind.device,
        _ => StockLocationKind.warehouse,
      };

  static String stockMovementKind(StockMovementKind value) => switch (value) {
        StockMovementKind.receive => 'receive',
        StockMovementKind.issue => 'issue',
        StockMovementKind.assign => 'assign',
        StockMovementKind.returnStock => 'return_stock',
      };

  static StockMovementKind stockMovementKindFromDb(String value) => switch (value) {
        'issue' => StockMovementKind.issue,
        'assign' => StockMovementKind.assign,
        'return_stock' => StockMovementKind.returnStock,
        _ => StockMovementKind.receive,
      };

  static JobActivityKind jobActivityKindFromDb(String value) => switch (value) {
        'scheduled' => JobActivityKind.scheduled,
        'assigned' => JobActivityKind.assigned,
        'on_the_way' => JobActivityKind.onTheWay,
        'arrived' => JobActivityKind.arrived,
        'job_started' => JobActivityKind.jobStarted,
        'job_completed' => JobActivityKind.jobCompleted,
        'available' => JobActivityKind.available,
        'off_duty' => JobActivityKind.offDuty,
        _ => JobActivityKind.assigned,
      };

  static String jobActivityKind(JobActivityKind value) => switch (value) {
        JobActivityKind.scheduled => 'scheduled',
        JobActivityKind.assigned => 'assigned',
        JobActivityKind.onTheWay => 'on_the_way',
        JobActivityKind.arrived => 'arrived',
        JobActivityKind.jobStarted => 'job_started',
        JobActivityKind.jobCompleted => 'job_completed',
        JobActivityKind.available => 'available',
        JobActivityKind.offDuty => 'off_duty',
      };

  static String fleetAssetKind(FleetAssetKind value) => switch (value) {
        FleetAssetKind.truck => 'truck',
        FleetAssetKind.device => 'device',
      };

  static FleetAssetKind fleetAssetKindFromDb(String value) => switch (value) {
        'device' => FleetAssetKind.device,
        _ => FleetAssetKind.truck,
      };

  static String documentTemplateStatus(DocumentTemplateStatus value) => switch (value) {
        DocumentTemplateStatus.active => 'active',
        DocumentTemplateStatus.draft => 'draft',
        DocumentTemplateStatus.archived => 'archived',
      };

  static DocumentTemplateStatus documentTemplateStatusFromDb(String value) => switch (value) {
        'active' => DocumentTemplateStatus.active,
        'draft' => DocumentTemplateStatus.draft,
        'archived' => DocumentTemplateStatus.archived,
        _ => DocumentTemplateStatus.draft,
      };

  static String maintenanceAgreementStatus(MaintenanceAgreementStatus value) => switch (value) {
        MaintenanceAgreementStatus.active => 'active',
        MaintenanceAgreementStatus.paused => 'paused',
        MaintenanceAgreementStatus.expired => 'expired',
        MaintenanceAgreementStatus.cancelled => 'cancelled',
      };

  static MaintenanceAgreementStatus maintenanceAgreementStatusFromDb(String value) => switch (value) {
        'paused' => MaintenanceAgreementStatus.paused,
        'expired' => MaintenanceAgreementStatus.expired,
        'cancelled' => MaintenanceAgreementStatus.cancelled,
        _ => MaintenanceAgreementStatus.active,
      };

  static String maintenanceAgreementFrequency(MaintenanceAgreementFrequency value) => switch (value) {
        MaintenanceAgreementFrequency.monthly => 'monthly',
        MaintenanceAgreementFrequency.quarterly => 'quarterly',
        MaintenanceAgreementFrequency.semiAnnual => 'semi_annual',
        MaintenanceAgreementFrequency.annual => 'annual',
      };

  static MaintenanceAgreementFrequency maintenanceAgreementFrequencyFromDb(String value) => switch (value) {
        'monthly' => MaintenanceAgreementFrequency.monthly,
        'quarterly' => MaintenanceAgreementFrequency.quarterly,
        'semi_annual' => MaintenanceAgreementFrequency.semiAnnual,
        _ => MaintenanceAgreementFrequency.annual,
      };
}
