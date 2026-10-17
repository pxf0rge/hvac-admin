import 'package:flutter/material.dart';
import 'package:hvac_admin/core/controllers/fleet_controller.dart';
import 'package:hvac_admin/core/controllers/technician_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/fleet_asset.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/fleet/assign_fleet_dialog.dart';
import 'package:hvac_admin/features/fleet/create_fleet_dialog.dart';
import 'package:provider/provider.dart';

class FleetPage extends StatefulWidget {
  const FleetPage({super.key});

  @override
  State<FleetPage> createState() => _FleetPageState();
}

class _FleetPageState extends State<FleetPage> {
  String _query = '';
  String _kind = 'All';
  String? _expandedAssetId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TechnicianController>().load();
      context.read<FleetController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final technicians = context.watch<TechnicianController>();
    final fleet = context.watch<FleetController>();
    final kind = FleetAssetKind.values.where((item) => item.label == _kind).firstOrNull;
    final rows = fleet.assetsFor(query: _query, kind: kind);

    if (fleet.isLoading && fleet.assets.isEmpty) {
      return const LoadingState(message: 'Loading fleet…');
    }

    if (fleet.loadError != null && fleet.assets.isEmpty) {
      return ErrorState(message: fleet.loadError!, onRetry: () => fleet.load(force: true));
    }

    return Padding(
      key: const Key('fleet-page'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fleet', style: AppTypography.headlineMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Trucks and shop devices are separate from employees — reassign without editing technician records.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              AppPrimaryButton(
                label: 'Add asset',
                icon: Icons.add,
                onPressed: () => showCreateFleetAssetDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppSearchField(
            hint: 'Search label or identifier',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final option in const ['All', 'Truck', 'Device'])
                FilterChip(
                  label: Text(option),
                  selected: _kind == option,
                  onSelected: (_) => setState(() => _kind = option),
                ),
            ],
          ),
          if (fleet.loadError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(fleet.loadError!, style: AppTypography.bodySmall.copyWith(color: AppColors.warning)),
          ],
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: rows.isEmpty
                ? const EmptyState(
                    key: Key('fleet-empty'),
                    title: 'No fleet assets',
                    message: 'Add trucks or devices to track assignments.',
                    icon: Icons.local_shipping_outlined,
                  )
                : ListView.separated(
                    key: const Key('fleet-asset-list'),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final asset = rows[index];
                      final technician = asset.currentTechnicianId == null
                          ? null
                          : technicians.technicianById(asset.currentTechnicianId!);
                      final expanded = _expandedAssetId == asset.id;
                      return SurfaceCard(
                        key: Key('fleet-row-${asset.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InkWell(
                              onTap: () async {
                                setState(() => _expandedAssetId = expanded ? null : asset.id);
                                if (!expanded) {
                                  await context.read<FleetController>().loadHistory(asset.id);
                                }
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    asset.kind == FleetAssetKind.truck
                                        ? Icons.local_shipping_outlined
                                        : Icons.build_circle_outlined,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(asset.label, style: AppTypography.titleMedium),
                                        Text(
                                          [
                                            asset.kind.label,
                                            if (asset.identifier.isNotEmpty) asset.identifier,
                                            if (asset.inventoryLocationId != null) 'Stock bin linked',
                                            if (!asset.isActive) 'Inactive',
                                          ].join('  ·  '),
                                          style: AppTypography.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusChip(
                                    label: technician?.displayName ?? 'Unassigned',
                                    background: AppColors.surfaceHover,
                                    foreground: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                AppSecondaryButton(
                                  key: Key('fleet-assign-${asset.id}'),
                                  label: technician == null ? 'Assign' : 'Reassign',
                                  onPressed: () => _openAssign(context, asset, technician?.id, technicians),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                AppSecondaryButton(
                                  label: 'Edit',
                                  onPressed: () => showCreateFleetAssetDialog(context, asset: asset),
                                ),
                                if (technician != null) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  AppSecondaryButton(
                                    key: Key('fleet-unassign-${asset.id}'),
                                    label: 'Unassign',
                                    onPressed: () => context.read<FleetController>().unassignAsset(
                                          fleetAssetId: asset.id,
                                          notes: 'Unassigned from fleet page',
                                        ),
                                  ),
                                ],
                              ],
                            ),
                            if (expanded) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text('Assignment history', style: AppTypography.titleMedium),
                              const SizedBox(height: AppSpacing.sm),
                              ..._historyTiles(fleet.historyFor(asset.id), technicians),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _historyTiles(List<FleetAssignment> history, TechnicianController technicians) {
    if (history.isEmpty) {
      return [Text('No assignment history yet.', style: AppTypography.bodySmall)];
    }
    return [
      for (final row in history)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            '${technicians.technicianById(row.technicianId)?.displayName ?? row.technicianId}'
            '  ·  ${formatDate(row.assignedAt.length >= 10 ? row.assignedAt.substring(0, 10) : row.assignedAt)}'
            '${row.unassignedAt == null ? '  ·  current' : ' → ${formatDate(row.unassignedAt!.substring(0, 10))}'}'
            '${row.notes.isNotEmpty ? '  ·  ${row.notes}' : ''}',
            style: AppTypography.bodySmall,
          ),
        ),
    ];
  }

  Future<void> _openAssign(
    BuildContext context,
    FleetAsset asset,
    String? currentTechnicianId,
    TechnicianController technicians,
  ) async {
    final technicianId = await showAssignFleetDialog(
      context: context,
      asset: asset,
      technicians: technicians.technicians,
      currentTechnicianId: currentTechnicianId,
    );
    if (!context.mounted || technicianId == null) return;
    await context.read<FleetController>().assignAsset(
          fleetAssetId: asset.id,
          technicianId: technicianId,
          notes: 'Assigned from fleet page',
        );
  }
}
