import 'package:hvac_admin/core/portal/portal_link_service.dart';

abstract class PortalRepository {
  Future<String> createAccessToken({
    required PortalResourceType resourceType,
    required String resourceId,
    int ttlHours = 720,
  });

  Future<Map<String, dynamic>> resolveToken(String token);
}
