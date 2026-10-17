import 'package:hvac_admin/core/audit/audit_redaction.dart';
import 'package:hvac_admin/core/models/audit_log_record.dart';
import 'package:hvac_admin/data/datasources/supabase_audit_log.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';
import 'package:hvac_admin/data/repositories/audit_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuditLogRepository implements AuditRepository {
  SupabaseAuditLogRepository(this._client, {SupabaseAuditLog? writer})
      : _writer = writer ?? SupabaseAuditLog(_client);

  final SupabaseClient _client;
  final SupabaseAuditLog _writer;

  static const _select =
      'id, at, actor_profile_id, actor_role, action, entity_type, entity_id, metadata, profiles(first_name, last_name)';

  @override
  Future<void> recordAction({
    required String action,
    required String entityType,
    required String entityId,
    Map<String, Object?> metadata = const {},
  }) {
    return _writer.record(
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
    var query = _client.from('audit_log').select(_select);
    if (action != null && action.isNotEmpty) {
      query = query.eq('action', action);
    }
    if (from != null) {
      query = query.gte('at', from.toUtc().toIso8601String());
    }
    if (to != null) {
      query = query.lte('at', to.toUtc().toIso8601String());
    }
    final rows = await query.order('at', ascending: false).limit(limit);
    final needle = actorQuery?.trim().toLowerCase();
    return [
      for (final row in rows)
        if (_matchesActor(row, needle)) _fromRow(MapperHelpers.row(row)),
    ];
  }

  bool _matchesActor(Map<String, dynamic> row, String? needle) {
    if (needle == null || needle.isEmpty) return true;
    final profile = row['profiles'];
    var name = '';
    if (profile is Map) {
      name = '${MapperHelpers.str(profile['first_name'])} ${MapperHelpers.str(profile['last_name'])}'.trim();
    }
    final blob = '$name ${MapperHelpers.strOrNull(row['actor_profile_id']) ?? ''} '
            '${MapperHelpers.strOrNull(row['actor_role']) ?? ''}'
        .toLowerCase();
    return blob.contains(needle);
  }

  AuditLogRecord _fromRow(Map<String, dynamic> row) {
    final profile = row['profiles'];
    String? actorName;
    if (profile is Map) {
      final name = '${MapperHelpers.str(profile['first_name'])} ${MapperHelpers.str(profile['last_name'])}'.trim();
      if (name.isNotEmpty) actorName = name;
    }
    final metadata = row['metadata'];
    return AuditLogRecord(
      id: MapperHelpers.uuid(row['id']),
      at: DateTime.parse(MapperHelpers.isoTimestamp(row['at'])).toUtc(),
      action: MapperHelpers.str(row['action']),
      entityType: MapperHelpers.str(row['entity_type']),
      entityId: MapperHelpers.str(row['entity_id']),
      metadata: metadata is Map
          ? AuditRedaction.sanitizeMetadata(Map<String, Object?>.from(metadata))
          : const {},
      actorUserId: MapperHelpers.strOrNull(row['actor_profile_id']),
      actorName: actorName,
      actorRole: MapperHelpers.strOrNull(row['actor_role']),
    );
  }
}
