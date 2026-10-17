import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/fleet_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/fleet_asset.dart';
import 'package:hvac_admin/data/datasources/mock_fleet_data.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('MockFleetRepository reassigns truck and records history', () async {
    final data = MockFleetData();
    final repo = MockFleetRepository(data: data);
    final jamesId = '88888888-8888-4888-8888-888888888881';

    final assigned = await repo.assignAsset(
      fleetAssetId: MockSeedIds.fleetTruckId,
      technicianId: jamesId,
      notes: 'Test reassignment',
    );
    expect(assigned.currentTechnicianId, jamesId);

    final history = await repo.getAssignmentHistory(MockSeedIds.fleetTruckId);
    expect(history.any((row) => row.technicianId == jamesId && row.isOpen), isTrue);
    expect(history.any((row) => row.technicianId == MockSeedIds.technicianId && !row.isOpen), isTrue);
  });

  test('FleetController lists assets for technician', () async {
    final data = MockFleetData();
    final controller = FleetController(MockFleetRepository(data: data));
    await controller.load(force: true);

    final carlosAssets = controller.assetsForTechnician(MockSeedIds.technicianId);
    expect(carlosAssets.any((asset) => asset.id == MockSeedIds.fleetTruckId), isTrue);
  });

  test('MockFleetRepository saves new asset', () async {
    final data = MockFleetData();
    final repo = MockFleetRepository(data: data);
    final saved = await repo.saveAsset(
      const FleetAsset(id: '', kind: FleetAssetKind.device, label: 'Test gauge', identifier: 'TG-1'),
    );
    expect(saved.id, isNotEmpty);
    expect(data.assets.any((asset) => asset.label == 'Test gauge'), isTrue);
  });
}
