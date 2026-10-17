enum HvacRealtimeTable {
  jobs,
  jobAssignments,
  jobStatusHistory,
  jobPhotos,
  jobDocuments,
  notifications,
  technicians,
  technicianLocations,
  internalMessages,
  internalThreads;

  static HvacRealtimeTable? tryParse(String table) {
    switch (table) {
      case 'jobs':
        return HvacRealtimeTable.jobs;
      case 'job_assignments':
        return HvacRealtimeTable.jobAssignments;
      case 'job_status_history':
        return HvacRealtimeTable.jobStatusHistory;
      case 'job_photos':
        return HvacRealtimeTable.jobPhotos;
      case 'job_documents':
        return HvacRealtimeTable.jobDocuments;
      case 'notifications':
        return HvacRealtimeTable.notifications;
      case 'technicians':
        return HvacRealtimeTable.technicians;
      case 'technician_locations':
        return HvacRealtimeTable.technicianLocations;
      case 'internal_messages':
        return HvacRealtimeTable.internalMessages;
      case 'internal_threads':
        return HvacRealtimeTable.internalThreads;
      default:
        return null;
    }
  }

  String get postgresName => switch (this) {
        HvacRealtimeTable.jobs => 'jobs',
        HvacRealtimeTable.jobAssignments => 'job_assignments',
        HvacRealtimeTable.jobStatusHistory => 'job_status_history',
        HvacRealtimeTable.jobPhotos => 'job_photos',
        HvacRealtimeTable.jobDocuments => 'job_documents',
        HvacRealtimeTable.notifications => 'notifications',
        HvacRealtimeTable.technicians => 'technicians',
        HvacRealtimeTable.technicianLocations => 'technician_locations',
        HvacRealtimeTable.internalMessages => 'internal_messages',
        HvacRealtimeTable.internalThreads => 'internal_threads',
      };
}

enum HvacRealtimeChangeType { insert, update, delete }

/// Domain event from a selective postgres_changes subscription.
class HvacRealtimeEvent {
  const HvacRealtimeEvent({
    required this.table,
    required this.changeType,
    required this.recordId,
    this.commitTimestamp,
    this.newRecord = const {},
    this.oldRecord = const {},
  });

  final HvacRealtimeTable table;
  final HvacRealtimeChangeType changeType;
  final String recordId;
  final DateTime? commitTimestamp;
  final Map<String, dynamic> newRecord;
  final Map<String, dynamic> oldRecord;

  String get dedupeKey {
    final ts = commitTimestamp?.millisecondsSinceEpoch ?? 0;
    return '${table.postgresName}:${changeType.name}:$recordId:$ts';
  }

  String get mutationKey => '${table.postgresName}:$recordId';
}
