import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/maintenance_agreement_controller.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/maintenance_agreement.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/customers/create_crm_dialog.dart';
import 'package:hvac_admin/features/equipment/create_equipment_dialog.dart';
import 'package:hvac_admin/features/maintenance/create_maintenance_agreement_dialog.dart';
import 'package:hvac_admin/features/maintenance/maintenance_widgets.dart';
import 'package:hvac_admin/features/properties/property_history_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:provider/provider.dart';

class PropertyDetailPage extends StatefulWidget {
  const PropertyDetailPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> with SingleTickerProviderStateMixin {
  bool _resolving = true;
  TabController? _tabs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final directory = context.read<CustomerController>();
    await directory.load();
    await directory.ensurePropertyLoaded(widget.propertyId);
    await directory.loadPropertyHistory(widget.propertyId);
    await context.read<MaintenanceAgreementController>().load();
    if (!mounted) return;
    final tabCount = context.read<ManagementAuthController>().canViewFinancials ? 5 : 4;
    _tabs = TabController(length: tabCount, vsync: this);
    setState(() => _resolving = false);
  }

  @override
  Widget build(BuildContext context) {
    final directory = context.watch<CustomerController>();
    final auth = context.watch<ManagementAuthController>();
    final maintenance = context.watch<MaintenanceAgreementController>();
    final property = directory.propertyById(widget.propertyId);
    final customer = property == null ? null : directory.customerById(property.customerId);
    final history = directory.historyFor(widget.propertyId);
    final propertyAgreements = maintenance.agreementsFor(propertyId: widget.propertyId);
    final canViewFinancials = auth.canViewFinancials;

    if (_resolving || (directory.isLoading && property == null)) {
      return const LoadingState(message: 'Loading property…');
    }
    if (property == null || customer == null) {
      return const EmptyState(title: 'Property not found', icon: Icons.home_work_outlined);
    }

    final tabs = _tabs;
    if (tabs == null) {
      return const LoadingState(message: 'Loading property…');
    }

    return Column(
      key: const Key('property-history'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(property.fullAddress, style: AppTypography.headlineMedium)),
                  AppSecondaryButton(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    onPressed: () => showEditPropertyDialog(context, property),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [if (property.label != null) property.label, property.type.label].join(' · '),
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () => context.go('${AdminModule.customers.path}/${customer.id}'),
                child: Text(customer.displayName),
              ),
            ],
          ),
        ),
        TabBar(
          controller: tabs,
          isScrollable: true,
          tabs: canViewFinancials
              ? [
                  const Tab(text: 'Overview'),
                  Tab(text: 'Jobs (${history.jobs.length})'),
                  Tab(text: 'Equipment (${history.equipment.length})'),
                  const Tab(text: 'Timeline'),
                  const Tab(text: 'Financial'),
                ]
              : [
                  const Tab(text: 'Overview'),
                  Tab(text: 'Jobs (${history.jobs.length})'),
                  Tab(text: 'Equipment (${history.equipment.length})'),
                  const Tab(text: 'Timeline'),
                ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: canViewFinancials
                ? [
                    _OverviewTab(
                      history: history,
                      customer: customer,
                      property: property,
                      propertyAgreements: propertyAgreements,
                    ),
                    _JobsTab(history: history),
                    _EquipmentTab(history: history, propertyId: property.id),
                    _TimelineTab(history: history),
                    _FinancialTab(history: history),
                  ]
                : [
                    _OverviewTab(
                      history: history,
                      customer: customer,
                      property: property,
                      propertyAgreements: propertyAgreements,
                    ),
                    _JobsTab(history: history),
                    _EquipmentTab(history: history, propertyId: property.id),
                    _TimelineTab(history: history),
                  ],
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.history,
    required this.customer,
    required this.property,
    required this.propertyAgreements,
  });

  final PropertyHistory history;
  final OfficeCustomer customer;
  final OfficeProperty property;
  final List<MaintenanceAgreement> propertyAgreements;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _SummaryCard(
              label: 'Equipment',
              value: '${history.equipment.length}',
              icon: Icons.hvac_outlined,
            ),
            _SummaryCard(
              label: 'Active warranties',
              value: '${history.activeWarrantyCount}',
              icon: Icons.verified_outlined,
            ),
            _SummaryCard(
              label: 'Jobs',
              value: '${history.jobs.length}',
              icon: Icons.work_outline,
            ),
            _SummaryCard(
              label: 'Technicians',
              value: '${history.technicians.length}',
              icon: Icons.engineering_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Customer', style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(customer.displayName, style: AppTypography.bodyMedium),
              Text(formatPhone(customer.phone), style: AppTypography.bodyMedium),
              Text(customer.email, style: AppTypography.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Maintenance agreements'),
        AppSecondaryButton(
          key: const Key('add-maintenance-agreement'),
          label: 'Add agreement',
          icon: Icons.assignment_outlined,
          onPressed: () async {
            final created = await showCreateMaintenanceAgreementDialog(
              context,
              customerId: customer.id,
              propertyId: property.id,
            );
            if (created != null && context.mounted) {
              context.go('${AdminModule.maintenanceAgreements.path}/${created.id}');
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        if (propertyAgreements.isEmpty)
          const Text('No maintenance agreements on file.', style: AppTypography.bodySmall)
        else
          for (final agreement in propertyAgreements) ...[
            MobileListTile(
              key: Key('property-maintenance-${agreement.id}'),
              title: agreement.title,
              subtitle: agreement.frequency.label,
              meta: 'Reminder ${formatDate(agreement.renewalReminderOn)}',
              trailing: MaintenanceAgreementStatusChip(status: agreement.status),
              onTap: () => context.go('${AdminModule.maintenanceAgreements.path}/${agreement.id}'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Previous technicians'),
        SurfaceCard(
          child: history.technicians.isEmpty
              ? const Text('No technicians recorded.', style: AppTypography.bodySmall)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final name in history.technicians)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(name, style: AppTypography.bodyMedium),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: KpiCard(label: label, value: value, icon: icon),
    );
  }
}

class _JobsTab extends StatelessWidget {
  const _JobsTab({required this.history});

  final PropertyHistory history;

  @override
  Widget build(BuildContext context) {
    if (history.jobs.isEmpty) {
      return const EmptyState(title: 'No jobs yet', icon: Icons.work_outline);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: history.jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final job = history.jobs[index];
        return MobileListTile(
          title: job.jobNumber,
          subtitle: '${job.type.label}  ·  ${job.technicianName}',
          meta: '${formatDate(job.date)}  ·  ${formatTimeRange(job.startTime, job.endTime)}',
          trailing: JobStatusChip(status: job.status),
          onTap: () => context.go('${AdminModule.jobs.path}/${job.id}'),
        );
      },
    );
  }
}

class _EquipmentTab extends StatelessWidget {
  const _EquipmentTab({required this.history, required this.propertyId});

  final PropertyHistory history;
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: AppSpacing.sm,
            children: [
              AppSecondaryButton(
                key: const Key('add-equipment'),
                label: 'Add equipment',
                icon: Icons.add_outlined,
                onPressed: () async {
                  final saved = await showCreateEquipmentDialog(context, propertyId: propertyId);
                  if (saved != null && context.mounted) {
                    await context.read<CustomerController>().loadPropertyHistory(propertyId);
                  }
                },
              ),
              if (history.equipment.isNotEmpty)
                AppSecondaryButton(
                  key: const Key('add-warranty'),
                  label: 'Add warranty',
                  icon: Icons.verified_outlined,
                  onPressed: () async {
                    final saved = await showCreateWarrantyDialog(context, equipment: history.equipment);
                    if (saved != null && context.mounted) {
                      await context.read<CustomerController>().loadPropertyHistory(propertyId);
                    }
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (history.equipment.isEmpty)
          const EmptyState(title: 'No equipment on file', icon: Icons.hvac_outlined)
        else
          for (var index = 0; index < history.equipment.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            Builder(
              builder: (context) {
                final unit = history.equipment[index];
                return MobileListTile(
                  title: unit.catalogLine,
                  subtitle: '${unit.name}  ·  ${unit.typeLabel}',
                  meta: unit.serial.isEmpty ? unit.capacity : 'Serial ${unit.serial}',
                  trailing: unit.warrantyState == null ? null : WarrantyChip(state: unit.warrantyState!),
                  onTap: () => context.go('${AdminModule.equipment.path}/${unit.id}'),
                );
              },
            ),
          ],
      ],
    );
  }
}

class _TimelineTab extends StatelessWidget {
  const _TimelineTab({required this.history});

  final PropertyHistory history;

  @override
  Widget build(BuildContext context) {
    if (history.timeline.isEmpty) {
      return const EmptyState(title: 'No timeline events', icon: Icons.timeline_outlined);
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        SurfaceCard(
          child: Column(
            children: [
              for (var i = 0; i < history.timeline.length; i++)
                TimelineRow(event: history.timeline[i], isLast: i == history.timeline.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinancialTab extends StatelessWidget {
  const _FinancialTab({required this.history});

  final PropertyHistory history;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SectionHeader(title: 'Estimates'),
        if (history.estimates.isEmpty)
          const Text('No estimates on file.', style: AppTypography.bodySmall)
        else
          for (final estimate in history.estimates) ...[
            MobileListTile(
              title: estimate.number,
              subtitle: estimate.status,
              meta: '${formatCurrency(estimate.amount)}  ·  ${formatDate(estimate.date)}',
              onTap: estimate.id == null
                  ? null
                  : () => context.go('${AdminModule.estimates.path}/${estimate.id}'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Invoices'),
        if (history.invoices.isEmpty)
          const Text('No invoices on file.', style: AppTypography.bodySmall)
        else
          for (final invoice in history.invoices) ...[
            MobileListTile(
              title: invoice.number,
              subtitle: invoice.status,
              meta: '${formatCurrency(invoice.amount)}  ·  ${formatDate(invoice.date)}',
              onTap: invoice.id == null
                  ? null
                  : () => context.go('${AdminModule.invoices.path}/${invoice.id}'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}
