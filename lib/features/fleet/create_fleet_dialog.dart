import 'package:flutter/material.dart';
import 'package:hvac_admin/core/controllers/fleet_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/fleet_asset.dart';
import 'package:hvac_admin/core/validation/field_validators.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:provider/provider.dart';

Future<FleetAsset?> showCreateFleetAssetDialog(
  BuildContext context, {
  FleetAsset? asset,
}) {
  return showDialog<FleetAsset>(
    context: context,
    builder: (_) => _FleetAssetDialog(asset: asset),
  );
}

class _FleetAssetDialog extends StatefulWidget {
  const _FleetAssetDialog({this.asset});

  final FleetAsset? asset;

  @override
  State<_FleetAssetDialog> createState() => _FleetAssetDialogState();
}

class _FleetAssetDialogState extends State<_FleetAssetDialog> {
  late final TextEditingController _label;
  late final TextEditingController _identifier;
  late FleetAssetKind _kind;
  late bool _isActive;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.asset != null;

  @override
  void initState() {
    super.initState();
    final asset = widget.asset;
    _label = TextEditingController(text: asset?.label ?? '');
    _identifier = TextEditingController(text: asset?.identifier ?? '');
    _kind = asset?.kind ?? FleetAssetKind.truck;
    _isActive = asset?.isActive ?? true;
  }

  @override
  void dispose() {
    _label.dispose();
    _identifier.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = FieldValidators.requiredText(_label.text, label: 'Label');
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final saved = await context.read<FleetController>().saveAsset(
            FleetAsset(
              id: widget.asset?.id ?? '',
              kind: _kind,
              label: _label.text.trim(),
              identifier: _identifier.text.trim(),
              inventoryLocationId: widget.asset?.inventoryLocationId,
              currentTechnicianId: widget.asset?.currentTechnicianId,
              isActive: _isActive,
            ),
          );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save fleet asset.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(_editing ? 'Edit fleet asset' : 'Add fleet asset'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Type'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<FleetAssetKind>(
                  isExpanded: true,
                  value: _kind,
                  items: [
                    for (final kind in FleetAssetKind.values)
                      DropdownMenuItem(value: kind, child: Text(kind.label)),
                  ],
                  onChanged: _editing
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _kind = value);
                        },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(controller: _label, label: 'Label'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _identifier,
              label: _kind == FleetAssetKind.truck ? 'Plate / unit number' : 'Serial / asset tag',
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        AppPrimaryButton(label: _editing ? 'Save' : 'Create', onPressed: _saving ? null : _submit),
      ],
    );
  }
}
