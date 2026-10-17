import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/models/global_search_hit.dart';
import 'package:hvac_admin/core/search/global_search_service.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('globalSearch returns mixed entity hits with admin routes', () async {
    final service = GlobalSearchService(
      customers: MockCustomerRepository(),
      jobs: MockJobRepository(),
      billing: MockBillingRepository(),
    );
    final hits = await service.search('Pat');
    expect(hits, isNotEmpty);
    expect(hits.any((hit) => hit.kind == GlobalSearchKind.customer), isTrue);
    expect(hits.first.route, startsWith('/'));
    expect(hits.any((hit) => hit.route.startsWith('/customers/')), isTrue);
  });

  test('globalSearch finds property and related jobs by address', () async {
    final service = GlobalSearchService(
      customers: MockCustomerRepository(),
      jobs: MockJobRepository(),
      billing: MockBillingRepository(),
    );
    final hits = await service.search('Oak Lane');
    expect(hits.any((hit) => hit.kind == GlobalSearchKind.property), isTrue);
    expect(hits.any((hit) => hit.kind == GlobalSearchKind.job), isTrue);
  });

  test('globalSearch omits invoices when includeFinancials is false', () async {
    final service = GlobalSearchService(
      customers: MockCustomerRepository(),
      jobs: MockJobRepository(),
      billing: MockBillingRepository(),
    );
    final withFinancials = await service.search('INV', includeFinancials: true);
    final withoutFinancials = await service.search('INV', includeFinancials: false);
    expect(withFinancials.any((hit) => hit.kind == GlobalSearchKind.invoice), isTrue);
    expect(withoutFinancials.any((hit) => hit.kind == GlobalSearchKind.invoice), isFalse);
  });
}
