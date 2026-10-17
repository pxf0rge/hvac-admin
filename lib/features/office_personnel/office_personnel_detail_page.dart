import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/controllers/office_personnel_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/models/office_user.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:provider/provider.dart';

class OfficePersonnelDetailPage extends StatefulWidget {
  const OfficePersonnelDetailPage({super.key, required this.userId});

  final String userId;

  @override
  State<OfficePersonnelDetailPage> createState() => _OfficePersonnelDetailPageState();
}

class _OfficePersonnelDetailPageState extends State<OfficePersonnelDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OfficePersonnelController>().load();
    });
  }

  List<UserRole> _rolesFor(UserRole? actor) {
    final roles = <UserRole>[UserRole.officeStaff, UserRole.admin];
    if (actor == UserRole.owner) roles.add(UserRole.owner);
    return roles;
  }

  Future<void> _changeRole(OfficeUser user) async {
    final actor = context.read<ManagementAuthController>().role;
    final roles = _rolesFor(actor);
    var selected = roles.contains(user.role) ? user.role : UserRole.officeStaff;

    final confirmed = await showDialog<UserRole>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Change role'),
              content: DropdownButton<UserRole>(
                key: const Key('office-user-role-dropdown'),
                isExpanded: true,
                value: selected,
                items: [
                  for (final role in roles)
                    DropdownMenuItem(value: role, child: Text(role.displayLabel)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setLocal(() => selected = value);
                },
              ),
              actions: [
                AppSecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
                AppPrimaryButton(
                  label: 'Save role',
                  onPressed: () => Navigator.pop(ctx, selected),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed == null || !mounted) return;
    final saved = await context.read<OfficePersonnelController>().changeRole(
          userId: user.id,
          role: confirmed,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved != null ? 'Role updated to ${saved.role.displayLabel}' : (context.read<OfficePersonnelController>().loadError ?? 'Could not change role'),
        ),
      ),
    );
  }

  Future<void> _toggleActive(OfficeUser user) async {
    final nextActive = !user.isActive;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(nextActive ? 'Reactivate account?' : 'Deactivate account?'),
        content: Text(
          nextActive
              ? '${user.displayName} will be able to sign in again.'
              : '${user.displayName} will be blocked from signing in to the admin app.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          AppSecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx, false)),
          AppPrimaryButton(
            label: nextActive ? 'Reactivate' : 'Deactivate',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final saved = await context.read<OfficePersonnelController>().setActive(
          userId: user.id,
          isActive: nextActive,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved != null
              ? (nextActive ? 'Account reactivated' : 'Account deactivated')
              : (context.read<OfficePersonnelController>().loadError ?? 'Could not update account'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OfficePersonnelController>();
    final auth = context.watch<ManagementAuthController>();
    final canManage = auth.canViewFinancials;
    final selfId = auth.session?.userId;
    final user = controller.userById(widget.userId);

    if (controller.isLoading && user == null) {
      return const LoadingState(message: 'Loading office user…');
    }

    if (user == null) {
      return EmptyState(
        title: 'Office user not found',
        message: 'This profile is not in the office personnel directory.',
        action: AppSecondaryButton(
          label: 'Back to list',
          onPressed: () => context.go(AdminModule.officePersonnel.path),
        ),
      );
    }

    final isSelf = selfId == user.id;

    return ListView(
      key: const Key('office-personnel-detail'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      children: [
        Row(
          children: [
            Expanded(child: Text(user.displayName, style: AppTypography.headlineMedium)),
            StatusChip(
              label: user.role.displayLabel,
              background: AppColors.primaryMuted,
              foreground: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!user.isActive)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: StatusChip(
              label: 'Deactivated',
              background: AppColors.dangerMuted,
              foreground: AppColors.danger,
            ),
          ),
        Text(user.email ?? 'No email on profile', style: AppTypography.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('Profile ID: ${user.id}', style: AppTypography.labelSmall),
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle('Profile'),
        SurfaceCard(
          child: Column(
            children: [
              _infoRow('First name', user.firstName),
              const Divider(height: 1),
              _infoRow('Last name', user.lastName),
              const Divider(height: 1),
              _infoRow('Email', user.email ?? '—'),
              const Divider(height: 1),
              _infoRow('Role', user.role.displayLabel),
              const Divider(height: 1),
              _infoRow('Status', user.isActive ? 'Active' : 'Deactivated'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle('Account actions'),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                canManage
                    ? 'Invite is on the list page. Role changes and deactivate require owner/admin.'
                    : 'Only owners and admins can change roles or deactivate accounts.',
                style: AppTypography.bodySmall,
              ),
              if (canManage) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppSecondaryButton(
                      key: const Key('office-user-change-role'),
                      label: 'Change role',
                      icon: Icons.manage_accounts_outlined,
                      onPressed: controller.isMutating || isSelf ? null : () => _changeRole(user),
                    ),
                    AppSecondaryButton(
                      key: const Key('office-user-toggle-active'),
                      label: user.isActive ? 'Deactivate' : 'Reactivate',
                      icon: user.isActive ? Icons.person_off_outlined : Icons.person_outline,
                      onPressed: controller.isMutating || isSelf ? null : () => _toggleActive(user),
                    ),
                  ],
                ),
                if (isSelf) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'You cannot change or deactivate your own account from here.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go(AdminModule.officePersonnel.path),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Office Personnel'),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title, style: AppTypography.titleMedium),
    );
  }

  Widget _infoRow(String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: AppTypography.labelMedium),
      subtitle: Text(value, style: AppTypography.bodyMedium),
    );
  }
}
