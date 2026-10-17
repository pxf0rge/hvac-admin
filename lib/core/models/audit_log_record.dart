import 'package:hvac_admin/core/audit/audit_redaction.dart';

class AuditLogRecord {
  const AuditLogRecord({
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

  Map<String, Object?> get displayMetadata => AuditRedaction.sanitizeMetadata(metadata);
}
