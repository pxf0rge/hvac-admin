import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('CustomerController saves customer and property', () async {
    final seed = MockSeedData();
    final repo = MockCustomerRepository(seed: seed);
    final controller = CustomerController(repo);

    await controller.load();
    expect(controller.customers, isNotEmpty);

    final savedCustomer = await controller.saveCustomer(
      const OfficeCustomer(
        id: '',
        firstName: 'Alex',
        lastName: 'Morgan',
        phone: '5551234567',
        email: 'alex@hvacpro.com',
        city: 'Springfield',
        state: 'IL',
      ),
    );
    expect(savedCustomer.id, isNotEmpty);
    expect(controller.customerById(savedCustomer.id)?.displayName, 'Alex Morgan');

    final savedProperty = await controller.saveProperty(
      OfficeProperty(
        id: '',
        customerId: savedCustomer.id,
        address: '12 Pine Street',
        city: 'Springfield',
        state: 'IL',
        zip: '62704',
        type: PropertyType.residential,
        latitude: 39.7817,
        longitude: -89.6501,
      ),
    );
    expect(savedProperty.id, isNotEmpty);
    expect(controller.propertiesForCustomer(savedCustomer.id), hasLength(1));
  });
}
