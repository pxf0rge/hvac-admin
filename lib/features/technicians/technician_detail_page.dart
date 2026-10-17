import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/fleet_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/controllers/technician_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/properties/property_history_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:hvac_admin/features/technicians/create_technician_dialog.dart';
import 'package:hvac_admin/features/technicians/technician_widgets.dart';
import 'package:provider/provider.dart';

class TechnicianDetailPage extends StatefulWidget {
  const TechnicianDetailPage({super.key, required this.technicianId});

  final String technicianId;

  @override
  State<TechnicianDetailPage> createState() => _TechnicianDetailPageState();
}

class _TechnicianDetailPageState extends State<TechnicianDetailPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<JobController>().loadDispatch();
    await context.read<FleetController>().load();
    await context.read<TechnicianController>().loadDetail(widget.technicianId);
    if (mounted) setState(() => _loading = false);
  }

  TechnicianStatus _liveStatus(OfficeTechnician tech, JobController jobs) {
    if (jobs.technicians.isNotEmpty) {
      return jobs.boardStatusFor(tech);
    }
    return tech.status;
  }

  @override
  Widget build(BuildContext context) {
    final technicians = context.watch<TechnicianController>();
    final jobs = context.watch<JobController>();
    final fleet = context.watch<FleetController>();
    final detail = technicians.detailFor(widget.technicianId);
    final tech = detail?.technician ?? technicians.technicianById(widget.technicianId);

    if (_loading || tech == null) {
      return const LoadingState(message: 'Loading technician…');
    }

    final status = _liveStatus(tech, jobs);
    final openJobs = jobs.jobsForTechnician(tech.id);
    final fleetAssets = fleet.assetsForTechnician(tech.id);

    return ListView(
      key: const Key('technician-detail'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      children: [
        Row(
          children: [
            Expanded(child: Text(tech.displayName, style: AppTypography.headlineMedium)),
            TechnicianStatusChip(status: status),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!tech.accountEnabled)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: StatusChip(
              label: 'Account disabled',
              background: AppColors.dangerMuted,
              foreground: AppColors.danger,
            ),
          ),
        Text(
          [
            if (tech.phone.isNotEmpty) formatPhone(tech.phone),
            if (tech.email.isNotEmpty) tech.email,
          ].join('  ·  '),
          style: AppTypography.bodyMedium,
        ),
        if (tech.lastAddress.isNotEmpty)
          Text(tech.lastAddress, style: AppTypography.bodySmall),
        if (tech.lastUpdated.isNotEmpty)
          Text('Updated ${formatDateTime(tech.lastUpdated)}', style: AppTypography.labelSmall),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppSecondaryButton(
              label: 'Edit profile',
              icon: Icons.edit_outlined,
              onPressed: () async {
                final saved = await showCreateTechnicianDialog(context, technician: tech);
                if (saved != null && mounted) {
                  await context.read<JobController>().reloadTechnicians();
                  await _load();
                }
              },
            ),
            AppSecondaryButton(
              label: tech.accountEnabled ? 'Disable account' : 'Enable account',
              icon: tech.accountEnabled ? Icons.block : Icons.check_circle_outline,
              onPressed: () async {
                await context.read<TechnicianController>().setAccountEnabled(
                      id: tech.id,
                      enabled: !tech.accountEnabled,
                    );
                await context.read<JobController>().reloadTechnicians();
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Fleet assets'),
        if (fleetAssets.isEmpty)
          const Text('No truck or device assigned.', style: AppTypography.bodySmall)
        else
          for (final asset in fleetAssets) ...[
            MobileListTile(
              title: asset.label,
              subtitle: '${asset.kind.label}${asset.identifier.isNotEmpty ? '  ·  ${asset.identifier}' : ''}',
              meta: asset.inventoryLocationId != null ? 'Stock bin linked' : null,
              onTap: () => context.go(AdminModule.fleet.path),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: 'Open jobs (${openJobs.length})'),
        if (openJobs.isEmpty)
          const Text('No open jobs assigned.', style: AppTypography.bodySmall)
        else
          for (final job in openJobs) ...[
            MobileListTile(
              title: job.jobNumber,
              subtitle: '${job.type.label}  ·  ${formatRelativeDate(job.date)}',
              meta: formatTimeRange(job.startTime, job.endTime),
              trailing: JobStatusChip(status: job.status),
              onTap: () => context.go('${AdminModule.jobs.path}/${job.id}'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Recent jobs'),
        if (detail == null || detail.recentJobs.isEmpty)
          const Text('No job history yet.', style: AppTypography.bodySmall)
        else
          for (final job in detail.recentJobs.take(8)) ...[
            MobileListTile(
              title: job.jobNumber,
              subtitle: '${job.type.label}  ·  ${formatDate(job.date)}',
              meta: job.status.label,
              onTap: () => context.go('${AdminModule.jobs.path}/${job.id}'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Activity'),
        if (detail == null || detail.activity.isEmpty)
          const Text('No activity recorded.', style: AppTypography.bodySmall)
        else
          for (var i = 0; i < detail.activity.length; i++)
            _ActivityRow(event: detail.activity[i], isLast: i == detail.activity.length - 1),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event, required this.isLast});

  final TechnicianActivity event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
              if (!isLast) Container(width: 2, height: 28, color: AppColors.border),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: AppTypography.titleMedium),
                Text(formatDateTime(event.at), style: AppTypography.labelSmall),
                const SizedBox(height: 2),
                Text(event.detail, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
