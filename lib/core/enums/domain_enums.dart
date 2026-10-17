/// Domain enums aligned with Postgres enums in `hvac_client/supabase/`.
enum JobStatus {
  unassigned,
  scheduled,
  assigned,
  onTheWay,
  arrived,
  inProgress,
  completed,
  cancelled,
}

enum TechnicianStatus {
  available,
  assigned,
  onTheWay,
  onJob,
  driving,
  offDuty,
}

enum PropertyType { residential, commercial, multiFamily }

/// Customer outbound SMS/email language (independent of office/field UI locale).
enum PreferredLanguage { english, spanish }

enum EquipmentType {
  centralAc,
  heatPump,
  furnace,
  miniSplit,
  airHandler,
  condenser,
  packageUnit,
}

enum JobType {
  acNotCooling,
  preventiveMaintenance,
  furnaceRepair,
  diagnostic,
  emergencyService,
  newInstallation,
  refrigerantLeak,
  thermostatReplacement,
}

enum JobPriority { low, normal, high, urgent }

enum InvoiceStatus { draft, sent, paid, overdue, cancelled }

enum EstimateStatus { draft, sent, approved, declined, expired }

enum CommunicationChannel { sms, email, system }

enum MessageDirection { inbound, outbound }

enum CommunicationEntityType { customer, property, job }

extension CommunicationEntityTypeX on CommunicationEntityType {
  String get label => switch (this) {
        CommunicationEntityType.customer => 'Customer',
        CommunicationEntityType.property => 'Property',
        CommunicationEntityType.job => 'Job',
      };
}

extension CommunicationChannelX on CommunicationChannel {
  String get label => switch (this) {
        CommunicationChannel.sms => 'SMS',
        CommunicationChannel.email => 'Email',
        CommunicationChannel.system => 'System',
      };
}

extension MessageDirectionX on MessageDirection {
  String get label => switch (this) {
        MessageDirection.inbound => 'Inbound',
        MessageDirection.outbound => 'Outbound',
      };
}

enum StockLocationKind { warehouse, truck, device }

enum StockMovementKind { receive, issue, assign, returnStock }

enum WarrantyState { active, expiringSoon, expired }

enum WarrantyFilter { any, active, expiringSoon, expired, none }

enum FleetAssetKind { truck, device }

enum DocumentTemplateStatus { active, draft, archived }

enum MaintenanceAgreementStatus { active, paused, expired, cancelled }

enum MaintenanceAgreementFrequency { monthly, quarterly, semiAnnual, annual }

extension FleetAssetKindX on FleetAssetKind {
  String get label => switch (this) {
        FleetAssetKind.truck => 'Truck',
        FleetAssetKind.device => 'Device',
      };
}

extension DocumentTemplateStatusX on DocumentTemplateStatus {
  String get label => switch (this) {
        DocumentTemplateStatus.active => 'Active',
        DocumentTemplateStatus.draft => 'Inactive',
        DocumentTemplateStatus.archived => 'Archived',
      };
}

extension TechnicianStatusX on TechnicianStatus {
  String get label => switch (this) {
        TechnicianStatus.available => 'Available',
        TechnicianStatus.assigned => 'Assigned',
        TechnicianStatus.onTheWay => 'On the way',
        TechnicianStatus.onJob => 'On Job',
        TechnicianStatus.driving => 'Driving',
        TechnicianStatus.offDuty => 'Off Duty',
      };
}

extension PreferredLanguageX on PreferredLanguage {
  String get code => switch (this) {
        PreferredLanguage.english => 'en',
        PreferredLanguage.spanish => 'es',
      };

  String get label => switch (this) {
        PreferredLanguage.english => 'English',
        PreferredLanguage.spanish => 'Español',
      };

  static PreferredLanguage fromCode(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value == 'es' || value == 'spanish') return PreferredLanguage.spanish;
    return PreferredLanguage.english;
  }
}

extension PropertyTypeX on PropertyType {
  String get label => switch (this) {
        PropertyType.residential => 'Residential',
        PropertyType.commercial => 'Commercial',
        PropertyType.multiFamily => 'Multi-family',
      };
}

extension JobStatusX on JobStatus {
  String get label => switch (this) {
        JobStatus.unassigned => 'Unassigned',
        JobStatus.scheduled => 'Scheduled',
        JobStatus.assigned => 'Assigned',
        JobStatus.onTheWay => 'On the way',
        JobStatus.arrived => 'Arrived',
        JobStatus.inProgress => 'In Progress',
        JobStatus.completed => 'Completed',
        JobStatus.cancelled => 'Cancelled',
      };
}

extension JobTypeX on JobType {
  String get label => switch (this) {
        JobType.acNotCooling => 'AC Not Cooling',
        JobType.preventiveMaintenance => 'Preventive Maintenance',
        JobType.furnaceRepair => 'Furnace Repair',
        JobType.diagnostic => 'Diagnostic',
        JobType.emergencyService => 'Emergency Service',
        JobType.newInstallation => 'New Installation',
        JobType.refrigerantLeak => 'Refrigerant Leak',
        JobType.thermostatReplacement => 'Thermostat Replacement',
      };
}

extension EquipmentTypeX on EquipmentType {
  String get label => switch (this) {
        EquipmentType.centralAc => 'Central AC',
        EquipmentType.heatPump => 'Heat Pump',
        EquipmentType.furnace => 'Furnace',
        EquipmentType.miniSplit => 'Mini Split',
        EquipmentType.airHandler => 'Air Handler',
        EquipmentType.condenser => 'Condenser',
        EquipmentType.packageUnit => 'Package Unit',
      };
}

extension EstimateStatusX on EstimateStatus {
  String get label => switch (this) {
        EstimateStatus.draft => 'Draft',
        EstimateStatus.sent => 'Sent',
        EstimateStatus.approved => 'Approved',
        EstimateStatus.declined => 'Declined',
        EstimateStatus.expired => 'Expired',
      };
}

extension InvoiceStatusX on InvoiceStatus {
  String get label => switch (this) {
        InvoiceStatus.draft => 'Draft',
        InvoiceStatus.sent => 'Sent',
        InvoiceStatus.paid => 'Paid',
        InvoiceStatus.overdue => 'Overdue',
        InvoiceStatus.cancelled => 'Cancelled',
      };
}

extension WarrantyFilterX on WarrantyFilter {
  String get label => switch (this) {
        WarrantyFilter.any => 'Any warranty',
        WarrantyFilter.active => 'Active',
        WarrantyFilter.expiringSoon => 'Expiring soon',
        WarrantyFilter.expired => 'Expired',
        WarrantyFilter.none => 'No warranty',
      };
}

extension StockLocationKindX on StockLocationKind {
  String get label => switch (this) {
        StockLocationKind.warehouse => 'Warehouse',
        StockLocationKind.truck => 'Truck',
        StockLocationKind.device => 'Device',
      };
}

extension StockMovementKindX on StockMovementKind {
  String get label => switch (this) {
        StockMovementKind.receive => 'Receive',
        StockMovementKind.issue => 'Issue',
        StockMovementKind.assign => 'Assign',
        StockMovementKind.returnStock => 'Return',
      };
}

extension MaintenanceAgreementStatusX on MaintenanceAgreementStatus {
  String get label => switch (this) {
        MaintenanceAgreementStatus.active => 'Active',
        MaintenanceAgreementStatus.paused => 'Paused',
        MaintenanceAgreementStatus.expired => 'Expired',
        MaintenanceAgreementStatus.cancelled => 'Cancelled',
      };
}

extension MaintenanceAgreementFrequencyX on MaintenanceAgreementFrequency {
  String get label => switch (this) {
        MaintenanceAgreementFrequency.monthly => 'Monthly',
        MaintenanceAgreementFrequency.quarterly => 'Quarterly',
        MaintenanceAgreementFrequency.semiAnnual => 'Semi-annual',
        MaintenanceAgreementFrequency.annual => 'Annual',
      };
}
