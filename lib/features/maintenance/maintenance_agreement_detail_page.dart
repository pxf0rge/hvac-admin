import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/maintenance_agreement_controller.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/maintenance/maintenance_widgets.dart';
import 'package:provider/provider.dart';

class MaintenanceAgreementDetailPage extends StatefulWidget {
  const MaintenanceAgreementDetailPage({super.key, required this.agreementId});

  final String agreementId;

  @override
  State<MaintenanceAgreementDetailPage> createState() => _MaintenanceAgreementDetailPageState();
}

class _MaintenanceAgreementDetailPageState extends State<MaintenanceAgreementDetailPage> {
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
    final agreement = agreements.agreementById(widget.agreementId);
    final property = agreement == null ? null : directory.propertyById(agreement.propertyId);
    final customer = property == null ? null : directory.customerById(property.customerId);

    if (agreements.isLoading && agreement == null) {
      return const LoadingState(message: 'Loading agreement…');
    }
    if (agreement == null) {
      return const EmptyState(title: 'Agreement not found', icon: Icons.assignment_outlined);
    }

    return ListView(
      key: const Key('maintenance-agreement-detail'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      children: [
        Row(
          children: [
            AppTextAction(
              label: 'Back to maintenance',
              onPressed: () => context.go(AdminModule.maintenanceAgreements.path),
            ),
            const Spacer(),
            MaintenanceAgreementStatusChip(status: agreement.status),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(agreement.title, style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customer?.displayName ?? '', style: AppTypography.titleMedium),
              Text(property?.fullAddress ?? '', style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Text('${agreement.frequency.label}  ·  ${agreement.status.label}', style: AppTypography.bodyMedium),
              Text(
                '${formatDate(agreement.startOn)} → ${formatDate(agreement.endOn)}',
                style: AppTypography.labelMedium,
              ),
              if (agreement.nextServiceOn != null)
                Text('Next service ${formatDate(agreement.nextServiceOn!)}', style: AppTypography.labelMedium),
              Text('Renewal reminder ${formatDate(agreement.renewalReminderOn)}', style: AppTypography.labelMedium),
              if (canViewFinancials && agreement.annualAmount != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Annual amount ${formatCurrency(agreement.annualAmount!)}', style: AppTypography.titleMedium),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(agreement.notes, style: AppTypography.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            if (agreement.status == MaintenanceAgreementStatus.active)
              AppSecondaryButton(
                label: 'Pause',
                onPressed: () => agreements.setStatus(agreement.id, MaintenanceAgreementStatus.paused),
              ),
            if (agreement.status == MaintenanceAgreementStatus.paused)
              AppPrimaryButton(
                label: 'Resume',
                onPressed: () => agreements.setStatus(agreement.id, MaintenanceAgreementStatus.active),
              ),
            if (agreement.status != MaintenanceAgreementStatus.cancelled)
              AppSecondaryButton(
                label: 'Cancel agreement',
                onPressed: () => agreements.setStatus(agreement.id, MaintenanceAgreementStatus.cancelled),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (customer != null)
          AppTextAction(
            label: 'Open customer',
            onPressed: () => context.go('${AdminModule.customers.path}/${customer.id}'),
          ),
        if (property != null)
          AppTextAction(
            label: 'Open property',
            onPressed: () => context.go('${AdminModule.properties.path}/${property.id}'),
          ),
      ],
    );
  }
}
