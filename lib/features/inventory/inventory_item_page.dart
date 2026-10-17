import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/fleet_controller.dart';
import 'package:hvac_admin/core/controllers/inventory_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/core/errors/failure_mapper.dart';
import 'package:hvac_admin/core/validation/inventory_validators.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/dispatch/dispatch_page.dart';
import 'package:hvac_admin/features/shared/widgets/form_error_banner.dart';
import 'package:provider/provider.dart';

class InventoryItemPage extends StatefulWidget {
  const InventoryItemPage({super.key, required this.itemId});

  final String itemId;

  @override
  State<InventoryItemPage> createState() => _InventoryItemPageState();
}

class _InventoryItemPageState extends State<InventoryItemPage> {
  late final TextEditingController _assignQty;
  late final TextEditingController _assignReason;
  late final TextEditingController _receiveQty;
  late final TextEditingController _receiveReason;
  late final TextEditingController _consumeQty;
  late final TextEditingController _consumeReason;
  String? _assignTargetId;
  String? _consumeLocationId;
  String? _jobId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _assignQty = TextEditingController(text: '1');
    _assignReason = TextEditingController(text: 'Stage for job');
    _receiveQty = TextEditingController(text: '5');
    _receiveReason = TextEditingController(text: 'Vendor delivery');
    _consumeQty = TextEditingController(text: '1');
    _consumeReason = TextEditingController(text: 'Installed on job');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InventoryController>().load();
      context.read<JobController>().loadDispatch();
      context.read<FleetController>().load();
    });
  }

  @override
  void dispose() {
    _assignQty.dispose();
    _assignReason.dispose();
    _receiveQty.dispose();
    _receiveReason.dispose();
    _consumeQty.dispose();
    _consumeReason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryController>();
    final jobs = context.watch<JobController>();
    final fleet = context.watch<FleetController>();
    final item = inventory.itemById(widget.itemId);

    if (inventory.isLoading && item == null) {
      return const LoadingState(message: 'Loading part…');
    }
    if (item == null) {
      return const EmptyState(title: 'Part not found', icon: Icons.inventory_2_outlined);
    }

    final targets = inventory.assignableLocations;
    _assignTargetId ??= targets.isEmpty ? null : targets.first.id;
    _consumeLocationId ??= targets.isEmpty ? null : targets.first.id;
    final movements = inventory.movementsForItem(item.id);

    return ListView(
      key: const Key('inventory-item'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      children: [
        if (_error != null) ...[
          FormErrorBanner(message: _error!),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTypography.headlineMedium),
                  Text('${item.sku} · ${item.category}', style: AppTypography.bodySmall),
                ],
              ),
            ),
            AppSecondaryButton(
              label: 'Edit',
              onPressed: () => context.go('${AdminModule.inventory.path}/${item.id}/edit'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key: const Key('warehouse-qty'),
                'Warehouse ${inventory.warehouseQty(item.id)} ${item.unit}',
                style: AppTypography.titleMedium,
              ),
              Text('Reorder level ${item.minQty} ${item.unit}', style: AppTypography.bodySmall),
              if (inventory.isLow(item))
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: StatusChip(
                    label: 'Below minimum',
                    background: AppColors.warningMuted,
                    foreground: AppColors.warning,
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              const SectionHeader(title: 'Trucks and devices'),
              for (final location in targets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${location.kind.label} · ${location.name} · '
                    '${inventory.quantityAt(itemId: item.id, locationId: location.id)} ${item.unit}'
                    '${_fleetLabel(fleet, location.id)}',
                    style: AppTypography.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Receive stock'),
        SurfaceCard(
          child: Column(
            children: [
              AppTextField(controller: _receiveQty, label: 'Quantity', keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _receiveReason, label: 'Reason'),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                key: const Key('receive-stock'),
                label: 'Receive into warehouse',
                expanded: true,
                onPressed: () async {
                  final qtyError = InventoryValidators.positiveQuantity(_receiveQty.text, label: 'Quantity');
                  if (qtyError != null) {
                    setState(() => _error = qtyError);
                    return;
                  }
                  final qty = int.parse(_receiveQty.text.trim());
                  setState(() => _error = null);
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Receive stock',
                    message: 'Receive $qty ${item.unit} of ${item.name} into the warehouse?',
                    confirmLabel: 'Receive',
                  );
                  if (!confirmed || !mounted) return;
                  try {
                    await inventory.receive(
                      itemId: item.id,
                      quantity: qty,
                      reason: _receiveReason.text.trim().isEmpty ? 'Stock received' : _receiveReason.text.trim(),
                    );
                  } catch (error) {
                    if (!mounted) return;
                    setState(() => _error = FailureMapper.messageFor(error));
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Assign from warehouse'),
        SurfaceCard(
          child: Column(
            children: [
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Destination'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('assign-target'),
                    value: _assignTargetId,
                    isExpanded: true,
                    items: [
                      for (final location in targets)
                        DropdownMenuItem(
                          value: location.id,
                          child: Text('${location.kind.label} · ${location.name}'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _assignTargetId = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Job context (optional)'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    key: const Key('assign-job'),
                    value: _jobId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('No job')),
                      for (final job in jobs.jobs)
                        DropdownMenuItem<String?>(
                          value: job.id,
                          child: Text('${job.jobNumber} · ${job.type.label}'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _jobId = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                key: const Key('assign-qty'),
                controller: _assignQty,
                label: 'Quantity',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _assignReason, label: 'Reason'),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                key: const Key('assign-submit'),
                label: 'Assign stock',
                expanded: true,
                onPressed: () async {
                  final target = _assignTargetId;
                  if (target == null) return;
                  final qtyError = InventoryValidators.positiveQuantity(_assignQty.text, label: 'Quantity');
                  if (qtyError != null) {
                    setState(() => _error = qtyError);
                    return;
                  }
                  final qty = int.parse(_assignQty.text.trim());
                  setState(() => _error = null);
                  final targetLocation = inventory.locationById(target);
                  final job = _jobId == null ? null : jobs.jobById(_jobId!);
                  final destination = targetLocation == null
                      ? 'the selected destination'
                      : '${targetLocation.kind.label} · ${targetLocation.name}';
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Assign stock',
                    message: 'Assign $qty ${item.unit} of ${item.name} to $destination'
                        '${job == null ? '' : ' for job ${job.jobNumber}'}?',
                    confirmLabel: 'Assign',
                  );
                  if (!confirmed || !mounted) return;
                  try {
                    await inventory.assignToLocation(
                      itemId: item.id,
                      toLocationId: target,
                      quantity: qty,
                      reason: _assignReason.text.trim().isEmpty ? 'Assigned from warehouse' : _assignReason.text.trim(),
                      jobId: _jobId,
                    );
                  } catch (error) {
                    if (!mounted) return;
                    setState(() => _error = FailureMapper.messageFor(error));
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Consume on job'),
        SurfaceCard(
          child: Column(
            children: [
              InputDecorator(
                decoration: const InputDecoration(labelText: 'From location'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('consume-location'),
                    value: _consumeLocationId,
                    isExpanded: true,
                    items: [
                      for (final location in targets)
                        DropdownMenuItem(
                          value: location.id,
                          child: Text('${location.kind.label} · ${location.name}'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _consumeLocationId = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Job'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    key: const Key('consume-job'),
                    value: _jobId,
                    isExpanded: true,
                    items: [
                      for (final job in jobs.jobs)
                        DropdownMenuItem<String?>(
                          value: job.id,
                          child: Text('${job.jobNumber} · ${job.type.label}'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _jobId = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _consumeQty, label: 'Quantity', keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _consumeReason, label: 'Reason'),
              const SizedBox(height: AppSpacing.md),
              AppSecondaryButton(
                key: const Key('consume-submit'),
                label: 'Record job usage',
                expanded: true,
                onPressed: _jobId == null || _consumeLocationId == null
                    ? null
                    : () async {
                        final qtyError = InventoryValidators.positiveQuantity(_consumeQty.text, label: 'Quantity');
                        if (qtyError != null) {
                          setState(() => _error = qtyError);
                          return;
                        }
                        final qty = int.parse(_consumeQty.text.trim());
                        setState(() => _error = null);
                        try {
                          await inventory.consumeForJob(
                            itemId: item.id,
                            fromLocationId: _consumeLocationId!,
                            quantity: qty,
                            jobId: _jobId!,
                            reason: _consumeReason.text.trim().isEmpty ? 'Used on job' : _consumeReason.text.trim(),
                          );
                        } catch (error) {
                          if (!mounted) return;
                          setState(() => _error = FailureMapper.messageFor(error));
                        }
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Movements'),
        if (movements.isEmpty)
          const Text('No movements yet.', style: AppTypography.bodySmall)
        else
          SurfaceCard(
            child: Column(
              children: [
                for (var i = 0; i < movements.length; i++) ...[
                  _MovementRow(
                    key: Key('movement-row-${movements[i].id}'),
                    kind: movements[i].kind.label,
                    detail:
                        '${movements[i].quantity} ${item.unit} · ${inventory.locationById(movements[i].fromLocationId)?.name ?? ''} → ${inventory.locationById(movements[i].toLocationId)?.name ?? ''}',
                    meta:
                        '${formatDate(movements[i].at)} · ${movements[i].reason}${movements[i].jobId == null ? '' : ' · ${jobs.jobById(movements[i].jobId!)?.jobNumber ?? movements[i].jobId}'}',
                  ),
                  if (i < movements.length - 1) const Divider(height: 20, color: AppColors.border),
                ],
              ],
            ),
          ),
      ],
    );
  }

  String _fleetLabel(FleetController fleet, String locationId) {
    final asset = fleet.assetForInventoryLocation(locationId);
    if (asset?.currentTechnicianId == null) return '';
    return ' · Fleet: ${asset!.label}';
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({super.key, required this.kind, required this.detail, required this.meta});

  final String kind;
  final String detail;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusChip(label: kind),
        const SizedBox(height: 4),
        Text(detail, style: AppTypography.bodyMedium),
        Text(meta, style: AppTypography.labelMedium),
      ],
    );
  }
}
