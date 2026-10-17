import 'package:hvac_admin/core/models/audit_log_record.dart';

abstract class AuditRepository {
  Future<List<AuditLogRecord>> queryEntries({
    String? action,
    String? actorQuery,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  });

  /// Append a sensitive-action row (owner/admin exports, etc.).
  Future<void> recordAction({
    required String action,
    required String entityType,
    required String entityId,
    Map<String, Object?> metadata = const {},
  });
}
