import 'package:flutter/material.dart';
import 'package:hvac_admin/core/models/fleet_asset.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/design_system/design_system.dart';

Future<String?> showAssignFleetDialog({
  required BuildContext context,
  required FleetAsset asset,
  required List<OfficeTechnician> technicians,
  String? currentTechnicianId,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _AssignFleetDialog(
      asset: asset,
      technicians: technicians,
      currentTechnicianId: currentTechnicianId,
    ),
  );
}

class _AssignFleetDialog extends StatefulWidget {
  const _AssignFleetDialog({
    required this.asset,
    required this.technicians,
    this.currentTechnicianId,
  });

  final FleetAsset asset;
  final List<OfficeTechnician> technicians;
  final String? currentTechnicianId;

  @override
  State<_AssignFleetDialog> createState() => _AssignFleetDialogState();
}

class _AssignFleetDialogState extends State<_AssignFleetDialog> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentTechnicianId ?? widget.technicians.firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Assign ${widget.asset.label}', style: AppTypography.titleMedium),
      content: SizedBox(
        width: 360,
        child: DropdownButtonFormField<String>(
          key: const Key('fleet-assign-technician'),
          isExpanded: true,
          value: _selectedId,
          decoration: const InputDecoration(labelText: 'Technician'),
          items: [
            for (final tech in widget.technicians)
              DropdownMenuItem(value: tech.id, child: Text(tech.displayName)),
          ],
          onChanged: (value) => setState(() => _selectedId = value),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        AppPrimaryButton(
          key: const Key('fleet-assign-confirm'),
          label: 'Assign',
          onPressed: _selectedId == null ? null : () => Navigator.of(context).pop(_selectedId),
        ),
      ],
    );
  }
}
