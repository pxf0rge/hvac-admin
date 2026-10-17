import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/controllers/office_personnel_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/models/office_user.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/office_personnel/invite_office_user_dialog.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:provider/provider.dart';

class OfficePersonnelPage extends StatefulWidget {
  const OfficePersonnelPage({super.key});

  @override
  State<OfficePersonnelPage> createState() => _OfficePersonnelPageState();
}

class _OfficePersonnelPageState extends State<OfficePersonnelPage> {
  UserRole? _roleFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OfficePersonnelController>().load(force: true);
    });
  }

  List<OfficeUser> _filtered(List<OfficeUser> users) {
    if (_roleFilter == null) return users;
    return [for (final user in users) if (user.role == _roleFilter) user];
  }

  Future<void> _invite() async {
    final saved = await showInviteOfficeUserDialog(context);
    if (saved != null && mounted) {
      context.go('${AdminModule.officePersonnel.path}/${saved.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OfficePersonnelController>();
    final canManage = context.watch<ManagementAuthController>().canViewFinancials;
    final strings = adminStrings(context);

    if (controller.isLoading && controller.users.isEmpty) {
      return LoadingState(message: strings.loadingOfficePersonnel);
    }

    if (controller.loadError != null && controller.users.isEmpty) {
      return ErrorState(
        message: controller.loadError!,
        onRetry: () => controller.load(force: true),
      );
    }

    final visible = _filtered(controller.users);

    return Padding(
      key: const Key('office-personnel-page'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.officePersonnelTitle, style: AppTypography.headlineMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      strings.officePersonnelSubtitle,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              if (canManage)
                AppPrimaryButton(
                  key: const Key('invite-office-user'),
                  label: strings.inviteUser,
                  icon: Icons.person_add_outlined,
                  onPressed: controller.isMutating ? null : _invite,
                ),
            ],
          ),
          if (controller.loadError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              controller.loadError!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilterChip(
                label: Text(strings.all),
                selected: _roleFilter == null,
                onSelected: (_) => setState(() => _roleFilter = null),
              ),
              for (final role in const [
                UserRole.owner,
                UserRole.admin,
                UserRole.officeStaff,
              ])
                FilterChip(
                  label: Text(role.displayLabel),
                  selected: _roleFilter == role,
                  onSelected: (_) => setState(() => _roleFilter = role),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: visible.isEmpty
                ? EmptyState(
                    title: strings.noOfficeUsers,
                    message: strings.noOfficeUsersFiltered,
                  )
                : ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final user = visible[index];
                      return MobileListTile(
                        key: Key('office-user-${user.id}'),
                        title: user.displayName,
                        subtitle: [
                          user.email ?? '—',
                          if (!user.isActive) strings.deactivatedLabel,
                        ].join(' · '),
                        trailing: StatusChip(
                          label: strings.role(user.role),
                          background: user.isActive ? AppColors.primaryMuted : AppColors.dangerMuted,
                          foreground: user.isActive ? AppColors.primary : AppColors.danger,
                        ),
                        onTap: () => context.go('${AdminModule.officePersonnel.path}/${user.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
