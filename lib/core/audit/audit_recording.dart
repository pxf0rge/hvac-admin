import 'package:hvac_admin/core/audit/audit_redaction.dart';
import 'package:hvac_admin/core/audit/audit_session_holder.dart';
import 'package:hvac_admin/core/audit/in_memory_audit_log.dart';
import 'package:hvac_admin/core/enums/user_role.dart';

void recordMockAudit(
  InMemoryAuditLog? log, {
  required String action,
  required String entityType,
  required String entityId,
  Map<String, Object?> metadata = const {},
  String? actorUserId,
  String? actorName,
  String? actorRole,
}) {
  if (log == null) return;
  final session = AuditSessionHolder.session;
  log.record(
    action: action,
    entityType: entityType,
    entityId: entityId,
    metadata: AuditRedaction.sanitizeMetadata(metadata),
    actorUserId: actorUserId ?? session?.userId,
    actorName: actorName ?? session?.displayName,
    actorRole: actorRole ?? session?.role.dbValue,
  );
}
