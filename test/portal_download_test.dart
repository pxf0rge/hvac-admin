import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/portal/portal_link_service.dart';
import 'package:hvac_admin/data/repositories/mock_portal_repository.dart';

/// Phase 20 — portal document download contract (mock resolve payloads).
void main() {
  test('mock document resolve exposes downloadable + storage_path metadata', () async {
    final repository = MockPortalRepository();
    final token = await repository.createAccessToken(
      resourceType: PortalResourceType.document,
      resourceId: 'doc_1',
    );
    final result = await repository.resolveToken(token);
    expect(result['ok'], isTrue);
    final payload = Map<String, dynamic>.from(result['payload'] as Map);
    expect(payload['resource_type'], 'document');
    expect(payload['storage_path'], isA<String>());
  });

  test('invalid token resolves to safe error', () async {
    final repository = MockPortalRepository();
    final result = await repository.resolveToken('nope');
    expect(result['ok'], isFalse);
    expect(result['error'], 'invalid_token');
  });
}
