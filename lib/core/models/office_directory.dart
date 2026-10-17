import 'package:hvac_admin/core/enums/domain_enums.dart';

class OfficeCustomer {
  const OfficeCustomer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.city,
    required this.state,
    this.notes = '',
    this.preferredLanguage = PreferredLanguage.english,
    this.propertyIds = const [],
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String city;
  final String state;
  final String notes;
  final PreferredLanguage preferredLanguage;
  final List<String> propertyIds;

  String get displayName => '$firstName $lastName'.trim();

  OfficeCustomer copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? city,
    String? state,
    String? notes,
    PreferredLanguage? preferredLanguage,
    List<String>? propertyIds,
  }) {
    return OfficeCustomer(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      state: state ?? this.state,
      notes: notes ?? this.notes,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      propertyIds: propertyIds ?? this.propertyIds,
    );
  }
}

class OfficeProperty {
  const OfficeProperty({
    required this.id,
    required this.customerId,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.type,
    this.label,
    this.latitude,
    this.longitude,
    this.equipmentIds = const [],
    this.jobIds = const [],
  });

  final String id;
  final String customerId;
  final String address;
  final String city;
  final String state;
  final String zip;
  final PropertyType type;
  final String? label;
  final double? latitude;
  final double? longitude;
  final List<String> equipmentIds;
  final List<String> jobIds;

  String get fullAddress => '$address, $city, $state $zip';

  OfficeProperty copyWith({
    String? id,
    String? customerId,
    String? address,
    String? city,
    String? state,
    String? zip,
    PropertyType? type,
    String? label,
    double? latitude,
    double? longitude,
    List<String>? equipmentIds,
    List<String>? jobIds,
  }) {
    return OfficeProperty(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      type: type ?? this.type,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      equipmentIds: equipmentIds ?? this.equipmentIds,
      jobIds: jobIds ?? this.jobIds,
    );
  }
}

class OfficeTechnician {
  const OfficeTechnician({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.lastAddress,
    required this.lastUpdated,
    this.profileId,
    this.phone = '',
    this.email = '',
    this.accountEnabled = true,
  });

  final String id;
  final String firstName;
  final String lastName;
  final TechnicianStatus status;
  final double latitude;
  final double longitude;
  final String lastAddress;
  final String lastUpdated;
  final String? profileId;
  final String phone;
  final String email;
  final bool accountEnabled;

  String get displayName => '$firstName $lastName'.trim();

  OfficeTechnician copyWith({
    String? id,
    String? firstName,
    String? lastName,
    TechnicianStatus? status,
    double? latitude,
    double? longitude,
    String? lastAddress,
    String? lastUpdated,
    String? profileId,
    String? phone,
    String? email,
    bool? accountEnabled,
  }) {
    return OfficeTechnician(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastAddress: lastAddress ?? this.lastAddress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      profileId: profileId ?? this.profileId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      accountEnabled: accountEnabled ?? this.accountEnabled,
    );
  }
}

class TechnicianActivity {
  const TechnicianActivity({required this.at, required this.title, required this.detail});

  final String at;
  final String title;
  final String detail;
}

class TechnicianDetail {
  const TechnicianDetail({
    required this.technician,
    required this.activity,
    required this.recentJobs,
    this.assignedAssetLabel,
  });

  final OfficeTechnician technician;
  final List<TechnicianActivity> activity;
  final List<HistoryJob> recentJobs;
  final String? assignedAssetLabel;
}

class HistoryJob {
  const HistoryJob({
    required this.id,
    required this.propertyId,
    required this.jobNumber,
    required this.type,
    required this.status,
    required this.priority,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.technicianName,
    this.technicianId,
    this.truckAssetId,
    this.description = '',
    this.notes = '',
    this.partsUsed = '',
  });

  final String id;
  final String propertyId;
  final String jobNumber;
  final JobType type;
  final JobStatus status;
  final JobPriority priority;
  final String date;
  final String startTime;
  final String endTime;
  final String technicianName;
  final String? technicianId;
  final String? truckAssetId;
  final String description;
  final String notes;
  final String partsUsed;

  bool get isOpen => status != JobStatus.completed && status != JobStatus.cancelled;

  HistoryJob copyWith({
    String? id,
    String? propertyId,
    String? jobNumber,
    JobType? type,
    JobStatus? status,
    JobPriority? priority,
    String? date,
    String? startTime,
    String? endTime,
    String? technicianName,
    String? technicianId,
    String? truckAssetId,
    String? description,
    String? notes,
    String? partsUsed,
    bool clearTechnicianId = false,
    bool clearTruckAssetId = false,
  }) {
    return HistoryJob(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      jobNumber: jobNumber ?? this.jobNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      technicianName: technicianName ?? this.technicianName,
      technicianId: clearTechnicianId ? null : (technicianId ?? this.technicianId),
      truckAssetId: clearTruckAssetId ? null : (truckAssetId ?? this.truckAssetId),
      description: description ?? this.description,
      notes: notes ?? this.notes,
      partsUsed: partsUsed ?? this.partsUsed,
    );
  }
}

class PropertyWarranty {
  const PropertyWarranty({
    required this.title,
    required this.serial,
    required this.expiresOn,
  });

  final String title;
  final String serial;
  final String expiresOn;

  WarrantyState get state {
    if (expiresOn.isEmpty) return WarrantyState.active;
    final parsed = DateTime.tryParse(expiresOn);
    if (parsed == null) return WarrantyState.active;
    final now = DateTime.now();
    if (parsed.isBefore(now)) return WarrantyState.expired;
    if (parsed.difference(now).inDays <= 90) return WarrantyState.expiringSoon;
    return WarrantyState.active;
  }
}

class NamedRecord {
  const NamedRecord({
    required this.title,
    required this.date,
    this.meta,
  });

  final String title;
  final String date;
  final String? meta;
}

class PropertyEquipment {
  const PropertyEquipment({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.manufacturer,
    required this.model,
    required this.serial,
    required this.typeKey,
    required this.typeLabel,
    required this.capacity,
    required this.installedOn,
    required this.installer,
    this.warranties = const [],
    this.photos = const [],
    this.manuals = const [],
    this.serviceJobIds = const [],
  });

  final String id;
  final String propertyId;
  final String name;
  final String manufacturer;
  final String model;
  final String serial;
  final String typeKey;
  final String typeLabel;
  final String capacity;
  final String installedOn;
  final String installer;
  final List<PropertyWarranty> warranties;
  final List<NamedRecord> photos;
  final List<NamedRecord> manuals;
  final List<String> serviceJobIds;

  String get catalogLine {
    final line = '${manufacturer.trim()} ${model.trim()}'.trim();
    return line.isEmpty ? name : line;
  }

  WarrantyState? get warrantyState {
    if (warranties.isEmpty) return null;
    WarrantyState worst = WarrantyState.active;
    for (final warranty in warranties) {
      final state = warranty.state;
      if (state == WarrantyState.expired) return WarrantyState.expired;
      if (state == WarrantyState.expiringSoon) worst = WarrantyState.expiringSoon;
    }
    return worst;
  }

  PropertyEquipment copyWith({
    String? id,
    String? propertyId,
    String? name,
    String? manufacturer,
    String? model,
    String? serial,
    String? typeKey,
    String? typeLabel,
    String? capacity,
    String? installedOn,
    String? installer,
    List<PropertyWarranty>? warranties,
    List<NamedRecord>? photos,
    List<NamedRecord>? manuals,
    List<String>? serviceJobIds,
  }) {
    return PropertyEquipment(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serial: serial ?? this.serial,
      typeKey: typeKey ?? this.typeKey,
      typeLabel: typeLabel ?? this.typeLabel,
      capacity: capacity ?? this.capacity,
      installedOn: installedOn ?? this.installedOn,
      installer: installer ?? this.installer,
      warranties: warranties ?? this.warranties,
      photos: photos ?? this.photos,
      manuals: manuals ?? this.manuals,
      serviceJobIds: serviceJobIds ?? this.serviceJobIds,
    );
  }
}

class WarrantyArchiveEntry {
  const WarrantyArchiveEntry({
    required this.equipmentId,
    required this.equipmentName,
    required this.manufacturer,
    required this.model,
    required this.serial,
    required this.warranty,
    required this.propertyId,
    required this.propertyAddress,
    required this.customerName,
  });

  final String equipmentId;
  final String equipmentName;
  final String manufacturer;
  final String model;
  final String serial;
  final PropertyWarranty warranty;
  final String propertyId;
  final String propertyAddress;
  final String customerName;
}

class MoneyRecord {
  const MoneyRecord({
    this.id,
    required this.number,
    required this.status,
    required this.amount,
    required this.date,
  });

  final String? id;
  final String number;
  final String status;
  final double amount;
  final String date;
}

class TimelineEvent {
  const TimelineEvent({required this.at, required this.title, required this.detail});

  final String at;
  final String title;
  final String detail;
}

class PropertyHistory {
  const PropertyHistory({
    required this.jobs,
    required this.equipment,
    required this.warranties,
    required this.photos,
    required this.documents,
    required this.estimates,
    required this.invoices,
    required this.technicians,
    required this.timeline,
  });

  static const empty = PropertyHistory(
    jobs: [],
    equipment: [],
    warranties: [],
    photos: [],
    documents: [],
    estimates: [],
    invoices: [],
    technicians: [],
    timeline: [],
  );

  final List<HistoryJob> jobs;
  final List<PropertyEquipment> equipment;
  final List<PropertyWarranty> warranties;
  final List<NamedRecord> photos;
  final List<NamedRecord> documents;
  final List<MoneyRecord> estimates;
  final List<MoneyRecord> invoices;
  final List<String> technicians;
  final List<TimelineEvent> timeline;

  int get activeWarrantyCount =>
      warranties.where((warranty) => warranty.state != WarrantyState.expired).length;
}
