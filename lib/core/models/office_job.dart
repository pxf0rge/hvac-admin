import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';

enum JobActivityKind {
  scheduled,
  assigned,
  onTheWay,
  arrived,
  jobStarted,
  jobCompleted,
  available,
  offDuty,
}

extension JobActivityKindX on JobActivityKind {
  String get label => switch (this) {
        JobActivityKind.scheduled => 'Scheduled',
        JobActivityKind.assigned => 'Assigned',
        JobActivityKind.onTheWay => 'On the way',
        JobActivityKind.arrived => 'Arrived',
        JobActivityKind.jobStarted => 'Job started',
        JobActivityKind.jobCompleted => 'Completed',
        JobActivityKind.available => 'Available',
        JobActivityKind.offDuty => 'Off duty',
      };
}

class JobStatusEvent {
  const JobStatusEvent({required this.at, required this.kind, this.label});

  final String at;
  final JobActivityKind kind;
  final String? label;

  String get displayLabel => label ?? kind.label;
}

class JobPhotoSummary {
  const JobPhotoSummary({
    required this.id,
    required this.caption,
    required this.createdAt,
  });

  final String id;
  final String caption;
  final String createdAt;
}

class JobDocumentSummary {
  const JobDocumentSummary({
    required this.id,
    required this.title,
    required this.signed,
    this.signerName,
  });

  final String id;
  final String title;
  final bool signed;
  final String? signerName;
}

class JobDetail {
  const JobDetail({
    required this.job,
    required this.statusHistory,
    required this.equipment,
    required this.photos,
    required this.documents,
  });

  static JobDetail fromJob(HistoryJob job) => JobDetail(
        job: job,
        statusHistory: const [],
        equipment: const [],
        photos: const [],
        documents: const [],
      );

  final HistoryJob job;
  final List<JobStatusEvent> statusHistory;
  final List<PropertyEquipment> equipment;
  final List<JobPhotoSummary> photos;
  final List<JobDocumentSummary> documents;
}
