import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/fleet_asset.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';

class MockFleetData {
  MockFleetData() {
    assets = List.of(_seedAssets());
    assignments = List.of(_seedAssignments());
  }

  late List<FleetAsset> assets;
  late List<FleetAssignment> assignments;

  static List<FleetAsset> _seedAssets() => [
        FleetAsset(
          id: MockSeedIds.fleetTruckId,
          kind: FleetAssetKind.truck,
          label: 'Truck 12',
          identifier: 'IL-FLT-12',
          inventoryLocationId: MockSeedIds.fleetTruckLocationId,
          currentTechnicianId: MockSeedIds.technicianId,
        ),
        FleetAsset(
          id: MockSeedIds.fleetTruck2Id,
          kind: FleetAssetKind.truck,
          label: 'Truck 18',
          identifier: 'IL-FLT-18',
          inventoryLocationId: MockSeedIds.fleetTruck2LocationId,
          currentTechnicianId: '88888888-8888-4888-8888-888888888881',
        ),
        FleetAsset(
          id: MockSeedIds.fleetDeviceId,
          kind: FleetAssetKind.device,
          label: 'Recovery unit RU-04',
          identifier: 'RU-04',
          inventoryLocationId: MockSeedIds.fleetDeviceLocationId,
        ),
        FleetAsset(
          id: MockSeedIds.fleetDevice2Id,
          kind: FleetAssetKind.device,
          label: 'Manifold kit MK-2',
          identifier: 'MK-2',
          inventoryLocationId: MockSeedIds.fleetDevice2LocationId,
          currentTechnicianId: '88888888-8888-4888-8888-888888888881',
        ),
      ];

  static List<FleetAssignment> _seedAssignments() => [
        FleetAssignment(
          id: 'fa_hist_1',
          fleetAssetId: MockSeedIds.fleetTruckId,
          technicianId: '88888888-8888-4888-8888-888888888881',
          assignedAt: '2026-06-01T08:00:00Z',
          unassignedAt: '2026-07-15T17:00:00Z',
          notes: 'Summer route',
        ),
        FleetAssignment(
          id: 'fa_hist_2',
          fleetAssetId: MockSeedIds.fleetTruckId,
          technicianId: MockSeedIds.technicianId,
          assignedAt: '2026-07-15T17:00:00Z',
          notes: 'Reassigned from James',
        ),
        FleetAssignment(
          id: 'fa_hist_3',
          fleetAssetId: MockSeedIds.fleetTruck2Id,
          technicianId: '88888888-8888-4888-8888-888888888881',
          assignedAt: '2026-05-01T08:00:00Z',
        ),
        FleetAssignment(
          id: 'fa_hist_4',
          fleetAssetId: MockSeedIds.fleetDevice2Id,
          technicianId: '88888888-8888-4888-8888-888888888881',
          assignedAt: '2026-08-01T09:00:00Z',
        ),
      ];
}
