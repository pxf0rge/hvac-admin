import 'package:hvac_admin/core/portal/portal_link_service.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';
import 'package:hvac_admin/data/repositories/portal_repository.dart';

class MockPortalRepository implements PortalRepository {
  final Map<String, ({PortalResourceType type, String resourceId, DateTime expires})> _tokens = {};

  @override
  Future<String> createAccessToken({
    required PortalResourceType resourceType,
    required String resourceId,
    int ttlHours = 720,
  }) async {
    final token = 'mock_${MapperHelpers.newUuid().replaceAll('-', '')}';
    _tokens[token] = (
      type: resourceType,
      resourceId: resourceId,
      expires: DateTime.now().toUtc().add(Duration(hours: ttlHours)),
    );
    return token;
  }

  @override
  Future<Map<String, dynamic>> resolveToken(String token) async {
    final entry = _tokens[token];
    if (entry == null) return {'ok': false, 'error': 'invalid_token'};
    if (entry.expires.isBefore(DateTime.now().toUtc())) {
      return {'ok': false, 'error': 'expired_token'};
    }
    final company = {
      'company_name': 'Arctic HVAC Solutions',
      'phone': '(217) 555-0100',
      'address': '1200 Commerce Blvd, Springfield, IL',
    };
    return switch (entry.type) {
      PortalResourceType.estimate => {
          'ok': true,
          'payload': {
            'resource_type': 'estimate',
            'number': 'EST-1001',
            'status': 'sent',
            'issued_on': '2026-09-01',
            'notes': 'Mock estimate for portal preview.',
            'customer_name': 'Pat Nguyen',
            'property_address': '77 Oak Lane',
            'line_items': [
              {'description': 'Diagnostic', 'quantity': 1, 'unit_price': 129},
            ],
            'company': company,
          },
        },
      PortalResourceType.invoice => {
          'ok': true,
          'payload': {
            'resource_type': 'invoice',
            'number': 'INV-1001',
            'status': 'sent',
            'issued_on': '2026-09-01',
            'due_on': '2026-09-15',
            'notes': '',
            'customer_name': 'Pat Nguyen',
            'property_address': '77 Oak Lane',
            'line_items': [
              {'description': 'Repair labor', 'quantity': 2, 'unit_price': 95},
            ],
            'company': company,
            'pay_online': false,
            'pay_hint': 'Contact the office to pay this invoice.',
            'tax_rate_pct': 8.25,
            'grand_total': 205.68,
          },
        },
      PortalResourceType.document => {
          'ok': true,
          'payload': {
            'resource_type': 'document',
            'title': 'Service Authorization',
            'signer_name': 'Pat Nguyen',
            'signed_at': '2026-09-01T15:00:00Z',
            'storage_path': '',
            'company': company,
          },
        },
    };
  }
}
