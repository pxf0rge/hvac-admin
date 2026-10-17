import 'package:hvac_admin/core/audit/audit_redaction.dart';
import 'package:hvac_admin/core/logging/hvac_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Writes rows to `public.audit_log` via `record_audit_log` RPC.
class SupabaseAuditLog {
  SupabaseAuditLog(this._client);

  final SupabaseClient _client;

  Future<void> record({
    required String action,
    required String entityType,
    required String entityId,
    Map<String, Object?> metadata = const {},
  }) async {
    try {
      await _client.rpc('record_audit_log', params: {
        'p_action': action,
        'p_entity_type': entityType,
        'p_entity_id': entityId,
        'p_metadata': AuditRedaction.sanitizeMetadata(metadata),
      });
      HvacLog.info('audit.recorded', fields: {
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
      });
    } catch (error) {
      HvacLog.warn(
        'audit.write_failed',
        fields: {
          'action': action,
          'entity_type': entityType,
          'entity_id': entityId,
        },
        error: error,
      );
    }
  }
}
