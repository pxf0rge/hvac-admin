import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/controllers/technician_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:hvac_admin/features/technicians/create_technician_dialog.dart';
import 'package:hvac_admin/features/technicians/technician_widgets.dart';
import 'package:provider/provider.dart';

class TechniciansPage extends StatefulWidget {
  const TechniciansPage({super.key});

  @override
  State<TechniciansPage> createState() => _TechniciansPageState();
}

class _TechniciansPageState extends State<TechniciansPage> {
  TechnicianStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TechnicianController>().load();
      context.read<JobController>().loadDispatch();
    });
  }

  List<OfficeTechnician> _filtered(
    TechnicianController technicians,
    JobController jobs,
  ) {
    if (_statusFilter == null) return technicians.technicians;
    return [
      for (final tech in technicians.technicians)
        if (_liveStatus(tech, jobs) == _statusFilter) tech,
    ];
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

    if (technicians.isLoading && technicians.technicians.isEmpty) {
      return const LoadingState(message: 'Loading technicians…');
    }

    if (technicians.loadError != null && technicians.technicians.isEmpty) {
      return ErrorState(
        message: technicians.loadError!,
        onRetry: () => technicians.load(force: true),
      );
    }

    final visible = _filtered(technicians, jobs);

    return Padding(
      key: const Key('technicians-page'),
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
                    Text('Technicians', style: AppTypography.headlineMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text('Field team directory — status stays in sync with dispatch.', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              AppSecondaryButton(
                label: 'Map view',
                icon: Icons.map_outlined,
                onPressed: () => context.go('${AdminModule.technicians.path}/map'),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppPrimaryButton(
                label: 'Add technician',
                icon: Icons.person_add_outlined,
                onPressed: () async {
                  final saved = await showCreateTechnicianDialog(context);
                  if (saved != null && context.mounted) {
                    await context.read<JobController>().reloadTechnicians();
                    context.go('${AdminModule.technicians.path}/${saved.id}');
                  }
                },
              ),
            ],
          ),
          if (technicians.loadError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(technicians.loadError!, style: AppTypography.bodySmall.copyWith(color: AppColors.warning)),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _statusFilter == null,
                onSelected: (_) => setState(() => _statusFilter = null),
              ),
              for (final status in TechnicianStatus.values)
                FilterChip(
                  label: Text(status.label),
                  selected: _statusFilter == status,
                  onSelected: (_) => setState(() => _statusFilter = status),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: visible.isEmpty
                ? const EmptyState(
                    key: Key('technicians-empty'),
                    title: 'No technicians',
                    message: 'Add a field technician or adjust the status filter.',
                    icon: Icons.engineering_outlined,
                  )
                : ListView.separated(
                    key: const Key('technicians-list'),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final tech = visible[index];
                      final status = _liveStatus(tech, jobs);
                      final activeJobs = jobs.jobsForTechnician(tech.id).length;
                      final phone = tech.phone.isNotEmpty ? formatPhone(tech.phone) : tech.email;
                      return MobileListTile(
                        key: Key('technician-row-${tech.id}'),
                        title: tech.displayName,
                          subtitle: phone,
                          meta: activeJobs == 0 ? 'No open jobs' : '$activeJobs open job${activeJobs == 1 ? '' : 's'}',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!tech.accountEnabled)
                                const Padding(
                                  padding: EdgeInsets.only(right: AppSpacing.sm),
                                  child: StatusChip(
                                    label: 'Disabled',
                                    background: AppColors.dangerMuted,
                                    foreground: AppColors.danger,
                                  ),
                                ),
                              TechnicianStatusChip(status: status),
                            ],
                          ),
                          onTap: () => context.go('${AdminModule.technicians.path}/${tech.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
