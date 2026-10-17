import 'package:hvac_admin/core/enums/domain_enums.dart';

class FleetAsset {
  const FleetAsset({
    required this.id,
    required this.kind,
    required this.label,
    this.identifier = '',
    this.inventoryLocationId,
    this.currentTechnicianId,
    this.isActive = true,
  });

  final String id;
  final FleetAssetKind kind;
  final String label;
  final String identifier;
  final String? inventoryLocationId;
  final String? currentTechnicianId;
  final bool isActive;

  FleetAsset copyWith({
    FleetAssetKind? kind,
    String? label,
    String? identifier,
    String? inventoryLocationId,
    String? currentTechnicianId,
    bool? isActive,
    bool clearTechnician = false,
    bool clearInventoryLocation = false,
  }) {
    return FleetAsset(
      id: id,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      identifier: identifier ?? this.identifier,
      inventoryLocationId: clearInventoryLocation ? null : (inventoryLocationId ?? this.inventoryLocationId),
      currentTechnicianId: clearTechnician ? null : (currentTechnicianId ?? this.currentTechnicianId),
      isActive: isActive ?? this.isActive,
    );
  }
}

class FleetAssignment {
  const FleetAssignment({
    required this.id,
    required this.fleetAssetId,
    required this.technicianId,
    required this.assignedAt,
    this.unassignedAt,
    this.notes = '',
  });

  final String id;
  final String fleetAssetId;
  final String technicianId;
  final String assignedAt;
  final String? unassignedAt;
  final String notes;

  bool get isOpen => unassignedAt == null;
}
