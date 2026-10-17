import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/inventory_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/models/office_inventory.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:provider/provider.dart';

class InventoryItemEditorPage extends StatefulWidget {
  const InventoryItemEditorPage({super.key, this.itemId});

  final String? itemId;

  @override
  State<InventoryItemEditorPage> createState() => _InventoryItemEditorPageState();
}

class _InventoryItemEditorPageState extends State<InventoryItemEditorPage> {
  final _sku = TextEditingController();
  final _name = TextEditingController();
  final _category = TextEditingController(text: 'Electrical');
  final _unit = TextEditingController(text: 'ea');
  final _minQty = TextEditingController(text: '5');
  final _initialQty = TextEditingController(text: '10');
  bool _saving = false;
  bool _loading = true;

  bool get _isEdit => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final inventory = context.read<InventoryController>();
    await inventory.load(force: true);
    final item = widget.itemId == null ? null : inventory.itemById(widget.itemId!);
    if (item != null) {
      _sku.text = item.sku;
      _name.text = item.name;
      _category.text = item.category;
      _unit.text = item.unit;
      _minQty.text = '${item.minQty}';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _sku.dispose();
    _name.dispose();
    _category.dispose();
    _unit.dispose();
    _minQty.dispose();
    _initialQty.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final inventory = context.read<InventoryController>();
      final existing = widget.itemId == null ? null : inventory.itemById(widget.itemId!);
      final item = InventoryItem(
        id: existing?.id ?? 'part_${DateTime.now().microsecondsSinceEpoch}',
        sku: _sku.text.trim(),
        name: _name.text.trim(),
        category: _category.text.trim(),
        unit: _unit.text.trim().isEmpty ? 'ea' : _unit.text.trim(),
        minQty: int.tryParse(_minQty.text.trim()) ?? 0,
      );
      final saved = await inventory.saveItem(item);
      if (!_isEdit) {
        final qty = int.tryParse(_initialQty.text.trim()) ?? 0;
        if (qty > 0) {
          await inventory.receive(itemId: saved.id, quantity: qty, reason: 'Initial warehouse stock');
        }
      }
      if (!mounted) return;
      context.go('${AdminModule.inventory.path}/${saved.id}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState(message: 'Loading part…');

    return ListView(
      key: Key(_isEdit ? 'inventory-item-edit' : 'inventory-item-new'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      children: [
        Text(_isEdit ? 'Edit part' : 'New part', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(controller: _sku, label: 'SKU'),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: _name, label: 'Name'),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: _category, label: 'Category'),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: _unit, label: 'Unit'),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: _minQty, label: 'Reorder level', keyboardType: TextInputType.number),
        if (!_isEdit) ...[
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const Key('initial-qty'),
            controller: _initialQty,
            label: 'Initial warehouse quantity',
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppPrimaryButton(
          key: const Key('save-inventory-item'),
          label: _isEdit ? 'Save changes' : 'Create part',
          expanded: true,
          isLoading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
