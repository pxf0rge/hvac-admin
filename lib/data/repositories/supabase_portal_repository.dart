import 'package:hvac_admin/core/portal/portal_link_service.dart';
import 'package:hvac_admin/data/repositories/portal_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePortalRepository implements PortalRepository {
  SupabasePortalRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<String> createAccessToken({
    required PortalResourceType resourceType,
    required String resourceId,
    int ttlHours = 720,
  }) async {
    final type = switch (resourceType) {
      PortalResourceType.estimate => 'estimate',
      PortalResourceType.invoice => 'invoice',
      PortalResourceType.document => 'document',
    };
    final raw = await _client.rpc(
      'create_customer_access_token',
      params: {
        'p_resource_type': type,
        'p_resource_id': resourceId,
        'p_ttl_hours': ttlHours,
      },
    );
    final token = raw?.toString().trim() ?? '';
    if (token.isEmpty) throw StateError('Token mint failed');
    return token;
  }

  @override
  Future<Map<String, dynamic>> resolveToken(String token) async {
    final raw = await _client.rpc(
      'resolve_customer_access_token',
      params: {'p_token': token},
    );
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {'ok': false, 'error': 'invalid_token'};
  }
}
