import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/jobs/create_job_dialog.dart';
import 'package:hvac_admin/features/properties/property_history_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:hvac_admin/features/shared/widgets/paged_search_list.dart';
import 'package:provider/provider.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  JobStatus? _status;
  String? _technicianId;
  String? _customerId;
  final _dateFrom = TextEditingController();
  final _dateTo = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateFrom.addListener(() => setState(() {}));
    _dateTo.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerController>().load();
      context.read<JobController>().loadTechnicians();
    });
  }

  @override
  void dispose() {
    _dateFrom.dispose();
    _dateTo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobController>();
    final directory = context.watch<CustomerController>();
    final strings = adminStrings(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(strings.jobsTitle, style: AppTypography.headlineMedium)),
              AppPrimaryButton(
                label: strings.createJob,
                icon: Icons.add,
                onPressed: () async {
                  await showCreateJobDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                width: 180,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Status'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<JobStatus?>(
                      value: _status,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All statuses')),
                        for (final status in JobStatus.values)
                          DropdownMenuItem(value: status, child: Text(status.label)),
                      ],
                      onChanged: (value) => setState(() => _status = value),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Technician'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _technicianId,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All technicians')),
                        for (final tech in jobs.technicians)
                          DropdownMenuItem(value: tech.id, child: Text(tech.displayName)),
                      ],
                      onChanged: (value) => setState(() => _technicianId = value),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Customer'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _customerId,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All customers')),
                        for (final customer in directory.customers)
                          DropdownMenuItem(value: customer.id, child: Text(customer.displayName)),
                      ],
                      onChanged: (value) => setState(() => _customerId = value),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: AppTextField(
                  controller: _dateFrom,
                  label: 'From (YYYY-MM-DD)',
                ),
              ),
              SizedBox(
                width: 160,
                child: AppTextField(
                  controller: _dateTo,
                  label: 'To (YYYY-MM-DD)',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: PagedSearchList(
              key: ValueKey(
                'jobs-${_status?.name ?? 'all'}-${_technicianId ?? 'all'}-${_customerId ?? 'all'}-${_dateFrom.text}-${_dateTo.text}-${jobs.refreshToken}',
              ),
              searchHint: 'Search job number, type, customer, or technician',
              emptyTitle: 'No jobs',
              emptyMessage: 'No jobs match this search.',
              fetchPage: (offset, query) => jobs.fetchJobsPage(
                offset: offset,
                search: query,
                status: _status,
                technicianId: _technicianId,
                customerId: _customerId,
                dateFrom: _dateFrom.text.trim().isEmpty ? null : _dateFrom.text.trim(),
                dateTo: _dateTo.text.trim().isEmpty ? null : _dateTo.text.trim(),
              ),
              itemBuilder: (context, job) {
                final property = directory.propertyById(job.propertyId);
                final customer = property == null ? null : directory.customerById(property.customerId);
                return MobileListTile(
                  title: job.jobNumber,
                  subtitle: '${job.type.label}  ·  ${customer?.displayName ?? property?.address ?? ''}',
                  meta:
                      '${formatRelativeDate(job.date)}  ·  ${formatTimeRange(job.startTime, job.endTime)}  ·  ${job.technicianName}',
                  trailing: JobStatusChip(status: job.status),
                  onTap: () => context.go('${AdminModule.jobs.path}/${job.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
