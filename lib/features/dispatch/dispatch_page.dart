import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/features/communication/communication_page.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/fleet_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/jobs/create_job_dialog.dart';
import 'package:hvac_admin/features/properties/property_history_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';
import 'package:provider/provider.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        AppPrimaryButton(label: confirmLabel, onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  return result ?? false;
}

class DispatchPage extends StatefulWidget {
  const DispatchPage({super.key});

  @override
  State<DispatchPage> createState() => _DispatchPageState();
}

class _DispatchPageState extends State<DispatchPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerController>().load();
      context.read<JobController>().loadDispatch();
      context.read<FleetController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobController>();
    final directory = context.watch<CustomerController>();
    final strings = adminStrings(context);

    if (jobs.isLoading && jobs.jobs.isEmpty) {
      return LoadingState(message: strings.loadingDispatch);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.module(AdminModule.dispatch), style: AppTypography.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(strings.dispatchBoard, style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              AppPrimaryButton(
                label: strings.createJob,
                icon: Icons.add,
                onPressed: () => showCreateJobDialog(context),
              ),
            ],
          ),
        ),
        if (jobs.technicianLoadError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
            child: ErrorState(
              message: 'Could not load technicians. ${jobs.technicianLoadError}',
              onRetry: () => jobs.reloadTechnicians(),
            ),
          )
        else if (jobs.technicians.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
            child: EmptyState(
              title: 'No technician columns',
              message: 'Add a technician under Technicians, then refresh this page.',
              icon: Icons.engineering_outlined,
              action: AppSecondaryButton(
                label: 'Open technicians',
                onPressed: () => context.go(AdminModule.technicians.path),
              ),
            ),
          ),
        Expanded(
          child: ListView(
            key: const Key('dispatch-board'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
            children: [
              _TechnicianColumn(
                columnId: 'unassigned',
                title: 'Unassigned',
                subtitle: 'Queue',
                jobs: jobs.jobsForTechnician(null),
                directory: directory,
                assigningJobId: jobs.assigningJobId,
                isAssigning: jobs.isAssigning,
              ),
              for (final technician in jobs.technicians)
                _TechnicianColumn(
                  columnId: technician.id,
                  title: technician.displayName,
                  subtitle: jobs.boardStatusFor(technician).label,
                  jobs: jobs.jobsForTechnician(technician.id),
                  directory: directory,
                  assigningJobId: jobs.assigningJobId,
                  isAssigning: jobs.isAssigning,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TechnicianColumn extends StatelessWidget {
  const _TechnicianColumn({
    required this.columnId,
    required this.title,
    required this.subtitle,
    required this.jobs,
    required this.directory,
    required this.assigningJobId,
    required this.isAssigning,
  });

  final String columnId;
  final String title;
  final String subtitle;
  final List<HistoryJob> jobs;
  final CustomerController directory;
  final String? assigningJobId;
  final bool isAssigning;

  @override
  Widget build(BuildContext context) {
    final slots = _groupBySlot(jobs);
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data.isNotEmpty && !isAssigning,
      onAcceptWithDetails: (details) async {
        final technicianId = columnId == 'unassigned' ? null : columnId;
        final jobController = context.read<JobController>();
        final conflicts = jobController.assignmentConflicts(jobId: details.data, technicianId: technicianId);
        if (conflicts.isNotEmpty) {
          final names = conflicts.map((job) => job.jobNumber).join(', ');
          final proceed = await showConfirmDialog(
            context,
            title: 'Schedule conflict',
            message: 'This technician already has overlapping jobs: $names. Assign anyway?',
            confirmLabel: 'Assign anyway',
          );
          if (!proceed) return;
        }
        try {
          await jobController.assignJob(jobId: details.data, technicianId: technicianId);
        } catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not assign job: $error')),
          );
        }
      },
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty;
        return Container(
          key: Key('dispatch-column-$columnId'),
          width: 280,
          margin: const EdgeInsets.only(right: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hovering ? AppColors.primaryMuted : AppColors.surface,
            borderRadius: AppRadii.lgAll,
            border: Border.all(color: hovering ? AppColors.primary : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: AppTypography.titleLarge),
              const SizedBox(height: 2),
              Text('$subtitle  ·  ${jobs.length}', style: AppTypography.labelMedium),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: jobs.isEmpty
                    ? const Center(child: Text('Drop jobs here', style: AppTypography.bodySmall))
                    : ListView(
                        children: [
                          for (final entry in slots.entries) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6, top: 4),
                              child: Text(entry.key, style: AppTypography.labelMedium),
                            ),
                            for (final job in entry.value)
                              _DispatchJobCard(
                                job: job,
                                directory: directory,
                                isAssigning: assigningJobId == job.id,
                                dragEnabled: !isAssigning,
                              ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, List<HistoryJob>> _groupBySlot(List<HistoryJob> jobs) {
    final grouped = <String, List<HistoryJob>>{};
    for (final job in jobs) {
      final slot = timeToMinutes(job.startTime) < 12 * 60 ? 'Morning' : 'Afternoon';
      (grouped[slot] ??= []).add(job);
    }
    return grouped;
  }
}

class _DispatchJobCard extends StatelessWidget {
  const _DispatchJobCard({
    required this.job,
    required this.directory,
    required this.isAssigning,
    required this.dragEnabled,
  });

  final HistoryJob job;
  final CustomerController directory;
  final bool isAssigning;
  final bool dragEnabled;

  @override
  Widget build(BuildContext context) {
    final property = directory.propertyById(job.propertyId);
    final customer = property == null ? null : directory.customerById(property.customerId);
    final truck = job.truckAssetId == null
        ? null
        : context.watch<FleetController>().assetById(job.truckAssetId!);
    final card = Material(
      color: AppColors.background,
      borderRadius: AppRadii.lgAll,
      child: AsyncActionOverlay(
        active: isAssigning,
        borderRadius: AppRadii.lgAll,
        child: InkWell(
          onTap: isAssigning ? null : () => context.go('${AdminModule.jobs.path}/${job.id}'),
          borderRadius: AppRadii.lgAll,
          child: Container(
            width: 248,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: AppRadii.lgAll,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(job.jobNumber, style: AppTypography.titleMedium)),
                    JobStatusChip(status: job.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(job.type.label, style: AppTypography.bodySmall),
                Text(customer?.displayName ?? '', style: AppTypography.bodyMedium),
                Text(property?.address ?? '', style: AppTypography.labelMedium),
                const SizedBox(height: 4),
                Text(
                  '${formatRelativeDate(job.date)}  ·  ${formatTimeRange(job.startTime, job.endTime)}',
                  style: AppTypography.labelSmall,
                ),
                if (truck != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Truck ${truck.label}',
                    key: Key('dispatch-truck-${job.id}'),
                    style: AppTypography.labelSmall,
                  ),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    key: Key('dispatch-message-${job.id}'),
                    tooltip: 'Message customer',
                    icon: const Icon(Icons.sms_outlined, size: 18),
                    onPressed: isAssigning
                        ? null
                        : () => context.go(
                              communicationPath(
                                entityType: CommunicationEntityType.job,
                                entityId: job.id,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Draggable<String>(
        key: Key('dispatch-job-${job.id}'),
        data: job.id,
        maxSimultaneousDrags: dragEnabled ? 1 : 0,
        feedback: Material(
          elevation: 6,
          color: Colors.transparent,
          child: Opacity(opacity: 0.92, child: card),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: card),
        child: card,
      ),
    );
  }
}
