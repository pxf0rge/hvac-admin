import 'package:flutter/material.dart';
import 'package:hvac_admin/core/catalog/equipment_type_catalog_data.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/validation/field_validators.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:provider/provider.dart';

Future<PropertyEquipment?> showCreateEquipmentDialog(
  BuildContext context, {
  required String propertyId,
}) {
  return showDialog<PropertyEquipment>(
    context: context,
    builder: (_) => _EquipmentDialog(propertyId: propertyId),
  );
}

Future<PropertyEquipment?> showEditEquipmentDialog(
  BuildContext context,
  PropertyEquipment equipment,
) {
  return showDialog<PropertyEquipment>(
    context: context,
    builder: (_) => _EquipmentDialog(propertyId: equipment.propertyId, equipment: equipment),
  );
}

Future<PropertyWarranty?> showCreateWarrantyDialog(
  BuildContext context, {
  required List<PropertyEquipment> equipment,
}) {
  return showDialog<PropertyWarranty>(
    context: context,
    builder: (_) => _CreateWarrantyDialog(equipment: equipment),
  );
}

class _EquipmentDialog extends StatefulWidget {
  const _EquipmentDialog({required this.propertyId, this.equipment});

  final String propertyId;
  final PropertyEquipment? equipment;

  @override
  State<_EquipmentDialog> createState() => _EquipmentDialogState();
}

class _EquipmentDialogState extends State<_EquipmentDialog> {
  late final TextEditingController _name;
  late final TextEditingController _manufacturer;
  late final TextEditingController _model;
  late final TextEditingController _serial;
  late final TextEditingController _capacity;
  late final TextEditingController _installedOn;
  late final TextEditingController _installer;
  late String _typeKey;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final equipment = widget.equipment;
    _name = TextEditingController(text: equipment?.name ?? '');
    _manufacturer = TextEditingController(text: equipment?.manufacturer ?? '');
    _model = TextEditingController(text: equipment?.model ?? '');
    _serial = TextEditingController(text: equipment?.serial ?? '');
    _capacity = TextEditingController(text: equipment?.capacity ?? '');
    _installedOn = TextEditingController(text: equipment?.installedOn ?? '');
    _installer = TextEditingController(text: equipment?.installer ?? '');
    _typeKey = equipment?.typeKey ?? EnumDb.equipmentType(EquipmentType.centralAc);
  }

  @override
  void dispose() {
    _name.dispose();
    _manufacturer.dispose();
    _model.dispose();
    _serial.dispose();
    _capacity.dispose();
    _installedOn.dispose();
    _installer.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _manufacturer.text.trim().isEmpty) {
      setState(() => _error = 'Name and manufacturer are required.');
      return;
    }
    final installedOn = _installedOn.text.trim();
    if (installedOn.isNotEmpty && !FieldValidators.isIsoDate(installedOn)) {
      setState(() => _error = 'Install date must be YYYY-MM-DD.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final existing = widget.equipment;
      final saved = await context.read<CustomerController>().saveEquipment(
            PropertyEquipment(
              id: existing?.id ?? '',
              propertyId: widget.propertyId,
              name: _name.text.trim(),
              manufacturer: _manufacturer.text.trim(),
              model: _model.text.trim(),
              serial: _serial.text.trim(),
              typeKey: _typeKey,
              typeLabel: EquipmentTypeCatalogData.labelForKey(_typeKey),
              capacity: _capacity.text.trim(),
              installedOn: installedOn,
              installer: _installer.text.trim(),
              warranties: existing?.warranties ?? const [],
              photos: existing?.photos ?? const [],
              manuals: existing?.manuals ?? const [],
              serviceJobIds: existing?.serviceJobIds ?? const [],
            ),
          );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save equipment.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.equipment != null;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(isEdit ? 'Edit equipment' : 'New equipment'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: _name, label: 'Name'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _manufacturer, label: 'Manufacturer'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _model, label: 'Model'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _serial, label: 'Serial'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _capacity, label: 'Capacity'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _installedOn, label: 'Installed on (YYYY-MM-DD)'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _installer, label: 'Installer'),
              const SizedBox(height: AppSpacing.sm),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Equipment type'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _typeKey,
                    isExpanded: true,
                    items: [
                      for (final type in EquipmentType.values)
                        DropdownMenuItem(value: EnumDb.equipmentType(type), child: Text(type.label)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _typeKey = value);
                    },
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        AppPrimaryButton(label: 'Save', onPressed: _saving ? null : _submit),
      ],
    );
  }
}

class _CreateWarrantyDialog extends StatefulWidget {
  const _CreateWarrantyDialog({required this.equipment});

  final List<PropertyEquipment> equipment;

  @override
  State<_CreateWarrantyDialog> createState() => _CreateWarrantyDialogState();
}

class _CreateWarrantyDialogState extends State<_CreateWarrantyDialog> {
  late String _equipmentId = widget.equipment.first.id;
  final _title = TextEditingController();
  final _serial = TextEditingController();
  final _expiresOn = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _serial.dispose();
    _expiresOn.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _expiresOn.text.trim().isEmpty) {
      setState(() => _error = 'Title and expiry date are required.');
      return;
    }
    if (!FieldValidators.isIsoDate(_expiresOn.text.trim())) {
      setState(() => _error = 'Expiry date must be YYYY-MM-DD.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await context.read<CustomerController>().saveWarranty(
            equipmentId: _equipmentId,
            warranty: PropertyWarranty(
              title: _title.text.trim(),
              serial: _serial.text.trim(),
              expiresOn: _expiresOn.text.trim(),
            ),
          );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save warranty.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('New warranty'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Equipment'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _equipmentId,
                  isExpanded: true,
                  items: [
                    for (final unit in widget.equipment)
                      DropdownMenuItem(
                        value: unit.id,
                        child: Text(unit.catalogLine),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _equipmentId = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(controller: _title, label: 'Title'),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(controller: _serial, label: 'Serial'),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(controller: _expiresOn, label: 'Expires on (YYYY-MM-DD)'),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        AppPrimaryButton(label: 'Save', onPressed: _saving ? null : _submit),
      ],
    );
  }
}
