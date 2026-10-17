import 'package:flutter/material.dart';
import 'package:hvac_admin/core/controllers/technician_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/validation/field_validators.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:provider/provider.dart';

Future<OfficeTechnician?> showCreateTechnicianDialog(
  BuildContext context, {
  OfficeTechnician? technician,
}) {
  return showDialog<OfficeTechnician>(
    context: context,
    builder: (_) => _TechnicianDialog(technician: technician),
  );
}

class _TechnicianDialog extends StatefulWidget {
  const _TechnicianDialog({this.technician});

  final OfficeTechnician? technician;

  @override
  State<_TechnicianDialog> createState() => _TechnicianDialogState();
}

class _TechnicianDialogState extends State<_TechnicianDialog> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _profileId;
  late TechnicianStatus _status;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.technician != null;

  @override
  void initState() {
    super.initState();
    final technician = widget.technician;
    _firstName = TextEditingController(text: technician?.firstName ?? '');
    _lastName = TextEditingController(text: technician?.lastName ?? '');
    _phone = TextEditingController(text: technician?.phone ?? '');
    _email = TextEditingController(text: technician?.email ?? '');
    _profileId = TextEditingController(text: technician?.profileId ?? '');
    _status = technician?.status ?? TechnicianStatus.available;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _profileId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = FieldValidators.requiredText(_firstName.text, label: 'First name') ??
        FieldValidators.requiredText(_lastName.text, label: 'Last name') ??
        (_email.text.trim().isEmpty ? null : FieldValidators.email(_email.text)) ??
        (_phone.text.trim().isEmpty ? null : FieldValidators.phone(_phone.text));
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final profileId = _profileId.text.trim();
      final saved = await context.read<TechnicianController>().saveTechnician(
            id: widget.technician?.id,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim().toLowerCase(),
            profileId: profileId.isEmpty ? null : profileId,
            status: _status,
          );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save technician.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(_editing ? 'Edit technician' : 'Add technician'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: _firstName, label: 'First name'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(controller: _lastName, label: 'Last name'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(controller: _phone, label: 'Phone'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(controller: _email, label: 'Email'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _profileId,
              label: 'Auth profile ID (optional)',
              hint: 'UUID from profiles table',
            ),
            const SizedBox(height: AppSpacing.md),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Directory status'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TechnicianStatus>(
                  isExpanded: true,
                  value: _status,
                  items: [
                    for (final status in TechnicianStatus.values)
                      DropdownMenuItem(value: status, child: Text(status.label)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                  },
                ),
              ),
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
