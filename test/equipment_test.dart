import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('MockCustomerRepository saves equipment and warranty', () async {
    final seed = MockSeedData();
    final repo = MockCustomerRepository(seed: seed);
    final equipment = await repo.saveEquipment(
      PropertyEquipment(
        id: '',
        propertyId: MockSeedIds.propertyId,
        name: 'Upstairs unit',
        manufacturer: 'Trane',
        model: 'XR16',
        serial: 'SN-9001',
        typeKey: 'central_ac',
        typeLabel: 'Central AC',
        capacity: '3 ton',
        installedOn: '2026-01-15',
        installer: 'Arctic HVAC Solutions',
      ),
    );
    expect(equipment.id, isNotEmpty);

    final warranty = await repo.saveWarranty(
      equipmentId: equipment.id,
      warranty: const PropertyWarranty(
        title: 'Parts warranty',
        serial: 'W-9001',
        expiresOn: '2025-01-01',
      ),
    );
    expect(warranty.state, WarrantyState.expired);

    final history = await repo.getPropertyHistory(MockSeedIds.propertyId);
    expect(history.equipment.any((unit) => unit.serial == 'SN-9001'), isTrue);
    expect(history.warranties.any((item) => item.title == 'Parts warranty'), isTrue);

    final archive = await repo.searchWarranties(search: 'Pat Nguyen');
    expect(archive.items, isNotEmpty);

    final serialSearch = await repo.getEquipmentPage(search: 'SN-9001');
    expect(serialSearch.items, hasLength(1));
  });

  test('CustomerController caches saved equipment', () async {
    final controller = CustomerController(MockCustomerRepository(seed: MockSeedData()));
    await controller.load();

    final saved = await controller.saveEquipment(
      PropertyEquipment(
        id: '',
        propertyId: MockSeedIds.propertyId,
        name: 'Garage mini split',
        manufacturer: 'Mitsubishi',
        model: 'MSZ',
        serial: 'MSZ-42',
        typeKey: 'mini_split',
        typeLabel: 'Mini Split',
        capacity: '18k BTU',
        installedOn: '2026-02-01',
        installer: 'Arctic HVAC Solutions',
      ),
    );

    expect(controller.equipmentById(saved.id)?.serial, 'MSZ-42');
    final history = await controller.loadPropertyHistory(MockSeedIds.propertyId);
    expect(history.equipment.any((unit) => unit.id == saved.id), isTrue);
  });
}
