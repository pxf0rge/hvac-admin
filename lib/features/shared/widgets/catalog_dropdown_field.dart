import 'package:flutter/material.dart';
import 'package:hvac_admin/core/models/catalog_option.dart';
import 'package:hvac_admin/design_system/design_system.dart';

const catalogAddCustomToken = '__catalog_add_custom__';

Future<String?> showAddCatalogOptionDialog(
  BuildContext context, {
  required String title,
  String fieldLabel = 'Name',
  String confirmLabel = 'Save',
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: AppTextField(
          controller: controller,
          label: fieldLabel,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        AppPrimaryButton(
          label: confirmLabel,
          onPressed: () {
            final value = controller.text.trim();
            if (value.isEmpty) return;
            Navigator.pop(ctx, value);
          },
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

class CatalogDropdownField extends StatelessWidget {
  const CatalogDropdownField({
    super.key,
    required this.label,
    required this.valueKey,
    required this.options,
    required this.onChanged,
    this.onAddCustom,
    this.addCustomLabel = 'Add custom type…',
    this.addDialogTitle = 'New equipment type',
    this.enabled = true,
  });

  final String label;
  final String valueKey;
  final List<CatalogOption> options;
  final ValueChanged<String> onChanged;
  final Future<CatalogOption> Function(String label)? onAddCustom;
  final String addCustomLabel;
  final String addDialogTitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selected = options.any((option) => option.key == valueKey) ? valueKey : null;
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          items: [
            for (final option in options)
              DropdownMenuItem(value: option.key, child: Text(option.label)),
            if (onAddCustom != null)
              DropdownMenuItem(
                value: catalogAddCustomToken,
                child: Text(
                  addCustomLabel,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
          ],
          onChanged: !enabled
              ? null
              : (value) async {
                  if (value == null) return;
                  if (value == catalogAddCustomToken) {
                    final label = await showAddCatalogOptionDialog(
                      context,
                      title: addDialogTitle,
                      fieldLabel: 'Type name',
                    );
                    if (label == null || !context.mounted) return;
                    final created = await onAddCustom!(label);
                    if (!context.mounted) return;
                    onChanged(created.key);
                    return;
                  }
                  onChanged(value);
                },
        ),
      ),
    );
  }
}
