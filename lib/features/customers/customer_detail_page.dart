import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/messaging/message_thread_builder.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/communication/message_thread_widgets.dart';
import 'package:hvac_admin/features/customers/create_crm_dialog.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:provider/provider.dart';

class CustomerDetailPage extends StatefulWidget {
  const CustomerDetailPage({super.key, required this.customerId});

  final String customerId;

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final directory = context.read<CustomerController>();
    await directory.load();
    await context.read<JobController>().loadDispatch();
    await directory.ensureCustomerLoaded(widget.customerId);
    if (mounted) setState(() => _resolving = false);
  }

  @override
  Widget build(BuildContext context) {
    final directory = context.watch<CustomerController>();
    final jobs = context.watch<JobController>();
    final customer = directory.customerById(widget.customerId);
    final properties = directory.propertiesForCustomer(widget.customerId);
    final propertyIds = properties.map((item) => item.id).toSet();
    final customerJobs = jobs.jobs.where((job) => propertyIds.contains(job.propertyId)).toList();
    final messageEntities = MessageThreadBuilder.forCustomer(
      customerId: widget.customerId,
      properties: properties,
      jobs: customerJobs,
    );

    if (_resolving || (directory.isLoading && customer == null)) {
      return const LoadingState(message: 'Loading customer…');
    }
    if (customer == null) {
      return const EmptyState(title: 'Customer not found', icon: Icons.person_off_outlined);
    }

    return ListView(
      key: const Key('customer-detail'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      children: [
        Row(
          children: [
            Expanded(child: Text(customer.displayName, style: AppTypography.headlineMedium)),
            AppSecondaryButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              onPressed: () => showEditCustomerDialog(context, customer),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(formatPhone(customer.phone), style: AppTypography.bodyMedium),
        Text(customer.email, style: AppTypography.bodyMedium),
        Text('${customer.city}, ${customer.state}', style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        StatusChip(
          label: 'Messages: ${customer.preferredLanguage.label}',
          background: AppColors.primaryMuted,
          foreground: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            const Expanded(child: SectionHeader(title: 'Properties')),
            AppSecondaryButton(
              label: 'Add property',
              icon: Icons.add_home_work_outlined,
              onPressed: () => showCreatePropertyDialog(context, customerId: customer.id),
            ),
          ],
        ),
        if (properties.isEmpty)
          const Text('No properties on file.', style: AppTypography.bodySmall)
        else
          for (final property in properties) ...[
            MobileListTile(
              title: property.label ?? property.address,
              subtitle: property.fullAddress,
              meta: property.type.label,
              onTap: () => context.go('${AdminModule.properties.path}/${property.id}'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Messages'),
        MessageThreadPanel(
          listKey: Key('customer-messages-${customer.id}'),
          entities: messageEntities,
          replyEntityType: CommunicationEntityType.customer,
          replyEntityId: customer.id,
        ),
      ],
    );
  }
}
