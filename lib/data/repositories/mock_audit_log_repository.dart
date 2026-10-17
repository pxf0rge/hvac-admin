import 'package:hvac_admin/core/audit/audit_recording.dart';
import 'package:hvac_admin/core/audit/audit_redaction.dart';
import 'package:hvac_admin/core/audit/in_memory_audit_log.dart';
import 'package:hvac_admin/core/models/audit_log_record.dart';
import 'package:hvac_admin/data/repositories/audit_repository.dart';

class MockAuditLogRepository implements AuditRepository {
  MockAuditLogRepository(this._auditLog);

  final InMemoryAuditLog _auditLog;

  @override
  Future<void> recordAction({
    required String action,
    required String entityType,
    required String entityId,
    Map<String, Object?> metadata = const {},
  }) async {
    recordMockAudit(
      _auditLog,
      action: action,
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
    );
  }

  @override
  Future<List<AuditLogRecord>> queryEntries({
    String? action,
    String? actorQuery,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) async {
    final needle = actorQuery?.trim().toLowerCase();
    final filtered = [
      for (final entry in _auditLog.entries)
        if (_matches(entry, action: action, actorQuery: needle, from: from, to: to))
          AuditLogRecord(
            id: entry.id,
            at: entry.at,
            action: entry.action,
            entityType: entry.entityType,
            entityId: entry.entityId,
            metadata: AuditRedaction.sanitizeMetadata(entry.metadata),
            actorUserId: entry.actorUserId,
            actorName: entry.actorName,
            actorRole: entry.actorRole,
          ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    if (filtered.length <= limit) return filtered;
    return filtered.sublist(0, limit);
  }

  bool _matches(
    AuditLogEntry entry, {
    String? action,
    String? actorQuery,
    DateTime? from,
    DateTime? to,
  }) {
    if (action != null && action.isNotEmpty && entry.action != action) return false;
    if (from != null && entry.at.isBefore(from)) return false;
    if (to != null && entry.at.isAfter(to)) return false;
    if (actorQuery != null && actorQuery.isNotEmpty) {
      final blob = '${entry.actorName ?? ''} ${entry.actorUserId ?? ''} ${entry.actorRole ?? ''}'
          .toLowerCase();
      if (!blob.contains(actorQuery)) return false;
    }
    return true;
  }
}
