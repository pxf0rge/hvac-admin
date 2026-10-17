import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/maintenance_agreement_controller.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/maintenance/create_maintenance_agreement_dialog.dart';
import 'package:hvac_admin/features/maintenance/maintenance_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:provider/provider.dart';

class MaintenanceAgreementsPage extends StatefulWidget {
  const MaintenanceAgreementsPage({super.key});

  @override
  State<MaintenanceAgreementsPage> createState() => _MaintenanceAgreementsPageState();
}

class _MaintenanceAgreementsPageState extends State<MaintenanceAgreementsPage> {
  String _query = '';
  MaintenanceAgreementStatus? _status;
  bool _expiringOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerController>().load();
      context.read<MaintenanceAgreementController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final directory = context.watch<CustomerController>();
    final agreements = context.watch<MaintenanceAgreementController>();
    final canViewFinancials = context.watch<ManagementAuthController>().canViewFinancials;
    final rows = agreements.agreementsFor(query: _query, status: _status, expiringOnly: _expiringOnly);

    if (agreements.isLoading && agreements.agreements.isEmpty) {
      return const LoadingState(message: 'Loading maintenance agreements…');
    }

    return Padding(
      key: const Key('maintenance-page'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Maintenance agreements', style: AppTypography.headlineMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Track service plans per property with renewal reminders.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              AppPrimaryButton(
                label: 'New agreement',
                icon: Icons.add,
                onPressed: () => _createAgreement(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              'Renewal reminders send automatically via SMS/email when due (Settings → Automated reminders).',
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSearchField(
            hint: 'Search title or notes',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _status == null,
                onSelected: (_) => setState(() => _status = null),
              ),
              for (final status in MaintenanceAgreementStatus.values)
                FilterChip(
                  label: Text(status.label),
                  selected: _status == status,
                  onSelected: (_) => setState(() => _status = status),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FilterChip(
            key: const Key('maintenance-expiring-only'),
            label: const Text('Expiring in 30 days'),
            selected: _expiringOnly,
            onSelected: (value) => setState(() => _expiringOnly = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: rows.isEmpty
                ? const EmptyState(
                    title: 'No maintenance agreements',
                    message: 'Create one from a property or adjust filters.',
                  )
                : ListView.separated(
                    key: const Key('maintenance-agreement-list'),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final agreement = rows[index];
                      final property = directory.propertyById(agreement.propertyId);
                      final customer = property == null ? null : directory.customerById(property.customerId);
                      final expiring = agreement.isRenewalDueWithinDays(30);
                      return MobileListTile(
                        key: Key('maintenance-row-${agreement.id}'),
                        title: agreement.title,
                        subtitle: '${customer?.displayName ?? ''}  ·  ${property?.address ?? ''}',
                        meta: [
                          agreement.frequency.label,
                          'Reminder ${formatDate(agreement.renewalReminderOn)}',
                          if (canViewFinancials && agreement.annualAmount != null)
                            formatCurrency(agreement.annualAmount!),
                          if (expiring) 'Due soon',
                        ].join('  ·  '),
                        trailing: MaintenanceAgreementStatusChip(status: agreement.status),
                        onTap: () => context.go('${AdminModule.maintenanceAgreements.path}/${agreement.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _createAgreement(BuildContext context) async {
    final directory = context.read<CustomerController>();
    await directory.load();
    if (!context.mounted) return;
    final property = directory.properties.isNotEmpty ? directory.properties.first : null;
    if (property == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a property before creating an agreement.')),
      );
      return;
    }
    final customer = directory.customerById(property.customerId);
    if (customer == null) return;
    final created = await showCreateMaintenanceAgreementDialog(
      context,
      customerId: customer.id,
      propertyId: property.id,
    );
    if (created != null && context.mounted) {
      context.go('${AdminModule.maintenanceAgreements.path}/${created.id}');
    }
  }
}
