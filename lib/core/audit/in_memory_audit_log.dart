/// In-memory audit sink for mock repositories and unit tests.
class InMemoryAuditLog {
  final List<AuditLogEntry> entries = [];
  var _nextId = 0;

  void record({
    required String action,
    required String entityType,
    required String entityId,
    Map<String, Object?> metadata = const {},
    String? actorUserId,
    String? actorName,
    String? actorRole,
    DateTime? at,
  }) {
    _nextId += 1;
    entries.add(
      AuditLogEntry(
        id: 'audit_$_nextId',
        at: at ?? DateTime.now().toUtc(),
        action: action,
        entityType: entityType,
        entityId: entityId,
        metadata: Map<String, Object?>.from(metadata),
        actorUserId: actorUserId,
        actorName: actorName,
        actorRole: actorRole,
      ),
    );
  }

  void clear() => entries.clear();
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.at,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.metadata,
    this.actorUserId,
    this.actorName,
    this.actorRole,
  });

  final String id;
  final DateTime at;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, Object?> metadata;
  final String? actorUserId;
  final String? actorName;
  final String? actorRole;
}
