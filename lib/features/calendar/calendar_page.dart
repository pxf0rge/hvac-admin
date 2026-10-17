import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/calendar/management_calendar.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/dispatch/dispatch_page.dart';
import 'package:hvac_admin/features/jobs/create_job_dialog.dart';
import 'package:hvac_admin/features/properties/property_history_widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum _CalendarView { day, week }

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  _CalendarView _view = _CalendarView.week;
  DateTime _anchor = DateTime.now();
  String _technicianFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerController>().load();
      context.read<JobController>().loadDispatch();
    });
  }

  void _shift(int days) {
    setState(() => _anchor = _anchor.add(Duration(days: days)));
  }

  List<HistoryJob> _visibleJobs(JobController jobs) {
    if (_view == _CalendarView.day) {
      return ManagementCalendar.jobsOnDay(
        jobs: jobs.jobs,
        day: _anchor,
        technicianFilter: _technicianFilter,
      );
    }
    final days = ManagementCalendar.weekDays(_anchor);
    return ManagementCalendar.jobsBetween(
      jobs: jobs.jobs,
      start: days.first,
      end: days.last,
      technicianFilter: _technicianFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobController>();
    final directory = context.watch<CustomerController>();

    if (jobs.isLoading && jobs.jobs.isEmpty) {
      return const LoadingState(message: 'Loading schedule…');
    }

    if (jobs.loadError != null && jobs.jobs.isEmpty) {
      return ErrorState(
        message: jobs.loadError!,
        onRetry: () => jobs.loadDispatch(force: true),
      );
    }

    final visibleJobs = _visibleJobs(jobs);
    final rangeLabel = _view == _CalendarView.day
        ? formatDate(ManagementCalendar.isoDate(_anchor))
        : _weekRangeLabel(_anchor);

    return Padding(
      key: const Key('calendar-page'),
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
                    Text('Calendar', style: AppTypography.headlineMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Same jobs as Dispatch — assign and reschedule stay in sync.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              AppPrimaryButton(
                label: 'New job',
                icon: Icons.add,
                onPressed: () => showCreateJobDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              IconButton(
                key: const Key('calendar-prev'),
                onPressed: () => _shift(_view == _CalendarView.day ? -1 : -7),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(rangeLabel, textAlign: TextAlign.center, style: AppTypography.titleMedium),
              ),
              IconButton(
                key: const Key('calendar-next'),
                onPressed: () => _shift(_view == _CalendarView.day ? 1 : 7),
                icon: const Icon(Icons.chevron_right),
              ),
              AppSecondaryButton(
                label: 'Today',
                onPressed: () => setState(() => _anchor = DateTime.now()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<_CalendarView>(
                segments: const [
                  ButtonSegment(value: _CalendarView.day, label: Text('Day')),
                  ButtonSegment(value: _CalendarView.week, label: Text('Week')),
                ],
                selected: {_view},
                onSelectionChanged: (selection) => setState(() => _view = selection.first),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  key: const Key('calendar-technician-filter'),
                  isExpanded: true,
                  value: _technicianFilter,
                  decoration: const InputDecoration(labelText: 'Technician'),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All technicians')),
                    const DropdownMenuItem(
                      value: ManagementCalendar.unassignedFilter,
                      child: Text('Unassigned'),
                    ),
                    for (final tech in jobs.technicians)
                      DropdownMenuItem(value: tech.id, child: Text(tech.displayName)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _technicianFilter = value);
                  },
                ),
              ),
            ],
          ),
          if (jobs.loadError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(jobs.loadError!, style: AppTypography.bodySmall.copyWith(color: AppColors.warning)),
          ],
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: visibleJobs.isEmpty
                ? const EmptyState(
                    key: Key('calendar-empty'),
                    title: 'No jobs on this schedule',
                    message: 'Create a job or adjust the technician filter.',
                    icon: Icons.event_busy_outlined,
                  )
                : _view == _CalendarView.day
                    ? _DayView(jobs: visibleJobs, directory: directory)
                    : _WeekView(anchor: _anchor, jobs: visibleJobs, directory: directory),
          ),
        ],
      ),
    );
  }

  String _weekRangeLabel(DateTime anchor) {
    final days = ManagementCalendar.weekDays(anchor);
    final formatter = DateFormat('MMM d');
    return '${formatter.format(days.first)} – ${formatter.format(days.last)}';
  }
}

class _DayView extends StatelessWidget {
  const _DayView({required this.jobs, required this.directory});

  final List<HistoryJob> jobs;
  final CustomerController directory;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const Key('calendar-day-view'),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _CalendarJobCard(job: jobs[index], directory: directory),
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({required this.anchor, required this.jobs, required this.directory});

  final DateTime anchor;
  final List<HistoryJob> jobs;
  final CustomerController directory;

  @override
  Widget build(BuildContext context) {
    final days = ManagementCalendar.weekDays(anchor);
    return ListView(
      key: const Key('calendar-week-view'),
      children: [
        for (final day in days) ...[
          Text(
            '${DateFormat('EEE').format(day)}  ·  ${formatDate(ManagementCalendar.isoDate(day))}',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Builder(
            builder: (context) {
              final dayJobs = ManagementCalendar.jobsOnDay(
                jobs: jobs,
                day: day,
                technicianFilter: 'all',
              );
              if (dayJobs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Text('No jobs', style: AppTypography.bodySmall),
                );
              }
              return Column(
                children: [
                  for (final job in dayJobs) ...[
                    _CalendarJobCard(job: job, directory: directory),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _CalendarJobCard extends StatelessWidget {
  const _CalendarJobCard({required this.job, required this.directory});

  final HistoryJob job;
  final CustomerController directory;

  Future<void> _assign(BuildContext context, String? technicianId) async {
    final jobs = context.read<JobController>();
    final conflicts = jobs.assignmentConflicts(jobId: job.id, technicianId: technicianId);
    if (conflicts.isNotEmpty) {
      final names = conflicts.map((item) => item.jobNumber).join(', ');
      final proceed = await showConfirmDialog(
        context,
        title: 'Schedule conflict',
        message: 'Overlaps with $names. Assign anyway?',
        confirmLabel: 'Assign anyway',
      );
      if (!proceed) return;
    }
    await jobs.assignJob(jobId: job.id, technicianId: technicianId);
  }

  Future<void> _showAssignDialog(BuildContext context) async {
    final jobController = context.read<JobController>();
    final selected = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Assign technician'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ManagementCalendar.unassignedFilter),
            child: const Text('Unassigned'),
          ),
          for (final tech in jobController.technicians)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, tech.id),
              child: Text(tech.displayName),
            ),
        ],
      ),
    );
    if (!context.mounted || selected == null) return;
    final technicianId = selected == ManagementCalendar.unassignedFilter ? null : selected;
    await _assign(context, technicianId);
  }

  @override
  Widget build(BuildContext context) {
    final property = directory.propertyById(job.propertyId);
    final customer = property == null ? null : directory.customerById(property.customerId);
    final assigningJobId = context.watch<JobController>().assigningJobId;
    final isAssigning = assigningJobId == job.id;

    return AsyncActionOverlay(
      active: isAssigning,
      borderRadius: AppRadii.lgAll,
      child: SurfaceCard(
        key: Key('calendar-job-${job.id}'),
        child: InkWell(
          onTap: isAssigning ? null : () => context.go('${AdminModule.jobs.path}/${job.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                    if (job.technicianName.isNotEmpty)
                      Text(job.technicianName, style: AppTypography.labelSmall),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'open':
                      context.go('${AdminModule.jobs.path}/${job.id}');
                    case 'reschedule':
                      await showRescheduleJobDialog(context, job);
                    case 'assign':
                      await _showAssignDialog(context);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'open', child: Text('Open job')),
                  PopupMenuItem(value: 'reschedule', child: Text('Reschedule')),
                  PopupMenuItem(value: 'assign', child: Text('Assign technician')),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
