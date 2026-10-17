import 'package:flutter/material.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/controllers/office_personnel_controller.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/models/office_user.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:provider/provider.dart';

Future<OfficeUser?> showInviteOfficeUserDialog(BuildContext context) {
  return showDialog<OfficeUser>(
    context: context,
    builder: (_) => const _InviteOfficeUserDialog(),
  );
}

class _InviteOfficeUserDialog extends StatefulWidget {
  const _InviteOfficeUserDialog();

  @override
  State<_InviteOfficeUserDialog> createState() => _InviteOfficeUserDialogState();
}

class _InviteOfficeUserDialogState extends State<_InviteOfficeUserDialog> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  UserRole _role = UserRole.officeStaff;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  List<UserRole> _rolesFor(UserRole? actor) {
    final roles = <UserRole>[UserRole.officeStaff, UserRole.admin];
    if (actor == UserRole.owner) roles.add(UserRole.owner);
    return roles;
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty || email.isEmpty) {
      setState(() => _error = 'First name, last name, and email are required');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await context.read<OfficePersonnelController>().invite(
          email: email,
          firstName: _firstName.text,
          lastName: _lastName.text,
          role: _role,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      setState(() {
        _error = context.read<OfficePersonnelController>().loadError ?? 'Invite failed';
      });
      return;
    }
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final actor = context.watch<ManagementAuthController>().role;
    final roles = _rolesFor(actor);
    if (!roles.contains(_role)) _role = UserRole.officeStaff;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Invite office user'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: _firstName, label: 'First name'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(controller: _lastName, label: 'Last name'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
            ),
            const SizedBox(height: AppSpacing.md),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Role'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<UserRole>(
                  isExpanded: true,
                  value: _role,
                  items: [
                    for (final role in roles)
                      DropdownMenuItem(value: role, child: Text(role.displayLabel)),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _role = value);
                        },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Supabase sends an invite email so the user can set a password and sign in.',
              style: AppTypography.bodySmall,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        AppSecondaryButton(
          label: 'Cancel',
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        AppPrimaryButton(
          key: const Key('invite-office-user-submit'),
          label: _saving ? 'Sending…' : 'Send invite',
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }
}
