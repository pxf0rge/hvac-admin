import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('MockCustomerRepository builds property history from seed', () async {
    final seed = MockSeedData();
    final repo = MockCustomerRepository(seed: seed);
    final history = await repo.getPropertyHistory(MockSeedIds.propertyId);

    expect(history.jobs, isNotEmpty);
    expect(history.equipment, hasLength(1));
    expect(history.warranties, hasLength(1));
    expect(history.activeWarrantyCount, 1);
    expect(history.technicians, contains('Carlos Rodriguez'));
    expect(history.timeline, isNotEmpty);
    expect(history.estimates, isNotEmpty);
    expect(history.invoices, isNotEmpty);

    final jobEvents = history.timeline.where((event) => event.title.contains('JOB-'));
    expect(jobEvents, isNotEmpty);
  });

  test('property search finds Oak Lane address', () async {
    final seed = MockSeedData();
    final repo = MockCustomerRepository(seed: seed);
    final page = await repo.getPropertiesPage(search: 'Oak Lane');
    expect(page.items, hasLength(1));
    expect(page.items.first.address, '77 Oak Lane');
  });
}
