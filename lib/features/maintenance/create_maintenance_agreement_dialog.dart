import 'package:flutter/material.dart';
import 'package:hvac_admin/core/controllers/maintenance_agreement_controller.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/maintenance_agreement.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:provider/provider.dart';

Future<MaintenanceAgreement?> showCreateMaintenanceAgreementDialog(
  BuildContext context, {
  required String customerId,
  required String propertyId,
  String? defaultTitle,
}) {
  return showDialog<MaintenanceAgreement>(
    context: context,
    builder: (_) => _CreateMaintenanceAgreementDialog(
      customerId: customerId,
      propertyId: propertyId,
      defaultTitle: defaultTitle,
    ),
  );
}

class _CreateMaintenanceAgreementDialog extends StatefulWidget {
  const _CreateMaintenanceAgreementDialog({
    required this.customerId,
    required this.propertyId,
    this.defaultTitle,
  });

  final String customerId;
  final String propertyId;
  final String? defaultTitle;

  @override
  State<_CreateMaintenanceAgreementDialog> createState() => _CreateMaintenanceAgreementDialogState();
}

class _CreateMaintenanceAgreementDialogState extends State<_CreateMaintenanceAgreementDialog> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _amount = TextEditingController();
  MaintenanceAgreementFrequency _frequency = MaintenanceAgreementFrequency.annual;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title.text = widget.defaultTitle ?? 'Annual maintenance plan';
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final start = DateTime.now();
      final end = DateTime(start.year + 1, start.month, start.day);
      final reminder = end.subtract(const Duration(days: 45));
      final amountText = _amount.text.trim();
      double? amount;
      if (amountText.isNotEmpty) {
        amount = double.tryParse(amountText);
        if (amount == null) {
          setState(() {
            _error = 'Annual amount must be a number';
            _saving = false;
          });
          return;
        }
      }
      final canViewFinancials = context.read<ManagementAuthController>().canViewFinancials;

      final agreement = MaintenanceAgreement(
        id: '',
        customerId: widget.customerId,
        propertyId: widget.propertyId,
        title: title,
        status: MaintenanceAgreementStatus.active,
        frequency: _frequency,
        startOn: _formatDate(start),
        endOn: _formatDate(end),
        nextServiceOn: _formatDate(start.add(const Duration(days: 90))),
        renewalReminderOn: _formatDate(reminder),
        notes: _notes.text.trim(),
      );

      final saved = await context.read<MaintenanceAgreementController>().saveAgreement(
            agreement,
            annualAmount: canViewFinancials ? amount : null,
          );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final canViewFinancials = context.watch<ManagementAuthController>().canViewFinancials;

    return AlertDialog(
      title: const Text('New maintenance agreement'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<MaintenanceAgreementFrequency>(
              value: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: [
                for (final frequency in MaintenanceAgreementFrequency.values)
                  DropdownMenuItem(value: frequency, child: Text(frequency.label)),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _frequency = value);
                    },
            ),
            if (canViewFinancials) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Annual amount (optional)'),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        AppPrimaryButton(label: 'Create', onPressed: _saving ? null : _save),
      ],
    );
  }
}
