import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/equipment/create_equipment_dialog.dart';
import 'package:hvac_admin/features/properties/property_history_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:provider/provider.dart';

class EquipmentDetailPage extends StatefulWidget {
  const EquipmentDetailPage({super.key, required this.equipmentId});

  final String equipmentId;

  @override
  State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<CustomerController>().ensureEquipmentLoaded(widget.equipmentId);
    if (mounted) setState(() => _resolving = false);
  }

  @override
  Widget build(BuildContext context) {
    final directory = context.watch<CustomerController>();
    final unit = directory.equipmentById(widget.equipmentId);
    final property = unit == null ? null : directory.propertyById(unit.propertyId);
    final customer = property == null ? null : directory.customerById(property.customerId);

    if (_resolving || (directory.isLoading && unit == null)) {
      return const LoadingState(message: 'Loading equipment…');
    }
    if (unit == null) {
      return const EmptyState(title: 'Equipment not found', icon: Icons.thermostat_outlined);
    }

    final history = directory.historyFor(unit.propertyId);
    final jobs = history.jobs.where((job) => unit.serviceJobIds.contains(job.id)).toList();

    return ListView(
      key: const Key('equipment-detail'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      children: [
        Row(
          children: [
            Expanded(child: Text(unit.catalogLine, style: AppTypography.headlineMedium)),
            AppSecondaryButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              onPressed: () async {
                final saved = await showEditEquipmentDialog(context, unit);
                if (saved != null && mounted) await _load();
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${unit.name}  ·  ${unit.typeLabel}', style: AppTypography.bodyMedium),
              Text('Serial ${unit.serial}', style: AppTypography.bodySmall),
              Text('Capacity ${unit.capacity}', style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Text('Installed ${formatDate(unit.installedOn)}', style: AppTypography.bodySmall),
              Text('Installer ${unit.installer}', style: AppTypography.bodySmall),
              if (customer != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(customer.displayName, style: AppTypography.titleMedium),
                Text(property!.fullAddress, style: AppTypography.bodySmall),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Warranty'),
        if (unit.warranties.isEmpty)
          const Text('No warranty on file.', style: AppTypography.bodySmall)
        else
          SurfaceCard(
            child: Column(
              children: [
                for (var i = 0; i < unit.warranties.length; i++) ...[
                  _InfoRow(
                    title: unit.warranties[i].title,
                    body: 'Serial ${unit.warranties[i].serial}',
                    meta: 'Expires ${formatDate(unit.warranties[i].expiresOn)}',
                    trailing: WarrantyChip(state: unit.warranties[i].state),
                  ),
                  if (i < unit.warranties.length - 1) const Divider(height: 20, color: AppColors.border),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Warranty photos'),
        _NamedList(items: unit.photos, empty: 'Photo attachments arrive with later storage work.'),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Manuals'),
        _NamedList(items: unit.manuals, empty: 'No manuals on file.'),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Service history'),
        if (jobs.isEmpty)
          const Text('No linked jobs yet.', style: AppTypography.bodySmall)
        else
          for (final job in jobs) ...[
            MobileListTile(
              title: job.jobNumber,
              subtitle: '${job.type.label}  ·  ${job.technicianName}',
              meta: '${formatDate(job.date)}  ·  ${formatTimeRange(job.startTime, job.endTime)}',
              trailing: JobStatusChip(status: job.status),
              onTap: () => context.go('${AdminModule.jobs.path}/${job.id}'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.lg),
        if (property != null)
          AppSecondaryButton(
            label: 'Back to property',
            onPressed: () => context.go('${AdminModule.properties.path}/${property.id}'),
          ),
      ],
    );
  }
}

class _NamedList extends StatelessWidget {
  const _NamedList({required this.items, required this.empty});

  final List<NamedRecord> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SurfaceCard(child: Text(empty, style: AppTypography.bodySmall));
    }
    return SurfaceCard(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _InfoRow(
              title: items[i].title,
              meta: [formatDate(items[i].date), ?items[i].meta].where((part) => part != null && part.isNotEmpty).join('  ·  '),
            ),
            if (i < items.length - 1) const Divider(height: 20, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, this.body, this.meta, this.trailing});

  final String title;
  final String? body;
  final String? meta;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMedium),
              if (body != null) ...[
                const SizedBox(height: 2),
                Text(body!, style: AppTypography.bodySmall),
              ],
              if (meta != null && meta!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(meta!, style: AppTypography.labelMedium),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
