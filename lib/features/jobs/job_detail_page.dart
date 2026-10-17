import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/fleet_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/core/messaging/message_thread_builder.dart';
import 'package:hvac_admin/core/messaging/message_templates.dart';
import 'package:hvac_admin/features/communication/communication_page.dart';
import 'package:hvac_admin/features/communication/message_thread_widgets.dart';
import 'package:hvac_admin/features/invoices/invoice_editor_page.dart';
import 'package:hvac_admin/features/estimates/estimate_editor_page.dart';
import 'package:hvac_admin/features/jobs/create_job_dialog.dart';
import 'package:hvac_admin/features/jobs/job_status_timeline.dart';
import 'package:hvac_admin/features/properties/property_history_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';
import 'package:hvac_admin/features/shared/widgets/translatable_text_block.dart';
import 'package:provider/provider.dart';

class JobDetailPage extends StatefulWidget {
  const JobDetailPage({super.key, required this.jobId});

  final String jobId;

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<CustomerController>().load();
    await Future.wait([
      context.read<JobController>().loadJobDetail(widget.jobId),
      context.read<FleetController>().load(),
    ]);
    if (mounted) setState(() => _resolving = false);
  }

  Future<void> _setTruck(String? truckAssetId) async {
    await context.read<JobController>().setJobTruck(
          jobId: widget.jobId,
          truckAssetId: truckAssetId,
        );
    if (mounted) await _load();
  }

  Future<void> _cancelJob() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel job'),
        content: const Text('Cancel this job? Technicians will no longer see it on their schedule.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep job')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel job')),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    await context.read<JobController>().cancelJob(widget.jobId);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobController>();
    final directory = context.watch<CustomerController>();
    final fleet = context.watch<FleetController>();
    final detail = jobs.detailFor(widget.jobId);
    final job = detail?.job ?? jobs.jobById(widget.jobId);
    final property = job == null ? null : directory.propertyById(job.propertyId);
    final customer = property == null ? null : directory.customerById(property.customerId);
    final trucks = fleet.truckOptionsForJob(technicianId: job?.technicianId);
    final selectedTruckId = trucks.any((t) => t.id == job?.truckAssetId) ? job?.truckAssetId : null;
    final boundTruck = job?.truckAssetId == null ? null : fleet.assetById(job!.truckAssetId!);
    final messageEntities = MessageThreadBuilder.forJob(
      jobId: job?.id ?? widget.jobId,
      customerId: customer?.id,
    );

    if (_resolving || (job == null && detail == null)) {
      return const LoadingState(message: 'Loading job…');
    }
    if (job == null) {
      return const EmptyState(title: 'Job not found', icon: Icons.work_off_outlined);
    }

    return ListView(
      key: const Key('job-detail'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      children: [
        Row(
          children: [
            Expanded(child: Text(job.jobNumber, style: AppTypography.headlineMedium)),
            JobStatusChip(status: job.status),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job.type.label, style: AppTypography.titleMedium),
              if (job.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(job.description, style: AppTypography.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(customer?.displayName ?? '', style: AppTypography.bodyMedium),
              Text(property?.fullAddress ?? '', style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${formatDate(job.date)}  ·  ${formatTimeRange(job.startTime, job.endTime)}',
                style: AppTypography.bodySmall,
              ),
              Text(job.technicianName, style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                boundTruck == null
                    ? 'Truck: not set'
                    : 'Truck: ${boundTruck.label}${boundTruck.identifier.isEmpty ? '' : ' (${boundTruck.identifier})'}',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Truck (optional)'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    key: const Key('job-detail-truck'),
                    value: selectedTruckId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('No truck')),
                      for (final truck in trucks)
                        DropdownMenuItem(
                          value: truck.id,
                          child: Text(
                            [
                              truck.label,
                              if (truck.identifier.isNotEmpty) '(${truck.identifier})',
                              if (job.technicianId != null &&
                                  truck.currentTechnicianId == job.technicianId)
                                '· assigned to tech',
                            ].join(' '),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: job.isOpen ? (value) => _setTruck(value) : null,
                  ),
                ),
              ),
              if (job.isOpen) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    AppSecondaryButton(
                      label: 'Create invoice',
                      icon: Icons.receipt_long_outlined,
                      onPressed: () => context.go(
                        invoiceEditorPath(jobId: job.id, propertyId: job.propertyId),
                      ),
                    ),
                    AppSecondaryButton(
                      label: 'Create estimate',
                      icon: Icons.request_quote_outlined,
                      onPressed: () => context.go(
                        estimateEditorPath(jobId: job.id, propertyId: job.propertyId),
                      ),
                    ),
                    AppSecondaryButton(
                      label: 'Message customer',
                      icon: Icons.sms_outlined,
                      onPressed: () => context.go(
                        communicationPath(
                          entityType: CommunicationEntityType.job,
                          entityId: job.id,
                          template: MessageTemplateKind.appointmentReminder,
                        ),
                      ),
                    ),
                    AppSecondaryButton(
                      label: 'Reschedule',
                      icon: Icons.schedule_outlined,
                      onPressed: () async {
                        await showRescheduleJobDialog(context, job);
                        if (mounted) await _load();
                      },
                    ),
                    AppSecondaryButton(
                      key: const Key('cancel-job'),
                      label: 'Cancel job',
                      icon: Icons.cancel_outlined,
                      onPressed: _cancelJob,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Status history'),
        SurfaceCard(child: JobStatusTimeline(events: detail?.statusHistory ?? const [])),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Linked equipment'),
        if ((detail?.equipment ?? const []).isEmpty)
          const Text('No equipment linked yet.', style: AppTypography.bodySmall)
        else
          for (final unit in detail!.equipment) ...[
            MobileListTile(
              title: unit.catalogLine,
              subtitle: unit.typeLabel,
              meta: unit.serial.isEmpty ? unit.capacity : 'Serial ${unit.serial}',
              onTap: () => context.go('${AdminModule.equipment.path}/${unit.id}'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(title: adminStrings(context).technicianNotes),
        SurfaceCard(
          child: job.notes.isEmpty && job.partsUsed.isEmpty
              ? Text(adminStrings(context).noNotesYet, style: AppTypography.bodySmall)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (job.notes.isNotEmpty)
                      TranslatableTextBlock(
                        text: job.notes,
                        style: AppTypography.bodyMedium,
                        targetLocale: 'es',
                      ),
                    if (job.partsUsed.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(adminStrings(context).partsUsed, style: AppTypography.labelMedium),
                      TranslatableTextBlock(
                        text: job.partsUsed,
                        style: AppTypography.bodySmall,
                        targetLocale: 'es',
                        emptyLabel: '',
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Job photos'),
        SurfaceCard(
          child: (detail?.photos ?? const []).isEmpty
              ? const Text('No photos uploaded yet.', style: AppTypography.bodySmall)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final photo in detail!.photos) ...[
                      Text(photo.caption.isEmpty ? 'Photo' : photo.caption, style: AppTypography.titleMedium),
                      Text(formatDate(photo.createdAt.split('T').first), style: AppTypography.bodySmall),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Documents'),
        SurfaceCard(
          child: (detail?.documents ?? const []).isEmpty
              ? const Text('No documents on this job yet.', style: AppTypography.bodySmall)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final document in detail!.documents) ...[
                      Text(document.title, style: AppTypography.titleMedium),
                      Text(
                        document.signed ? 'Signed by ${document.signerName ?? 'customer'}' : 'Awaiting signature',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Messages'),
        MessageThreadPanel(
          listKey: Key('job-messages-${job.id}'),
          entities: messageEntities,
          replyEntityType: CommunicationEntityType.job,
          replyEntityId: job.id,
        ),
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
