import 'package:flutter/material.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/fleet_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/core/errors/failure_mapper.dart';
import 'package:hvac_admin/core/validation/field_validators.dart';
import 'package:hvac_admin/core/validation/scheduling_validators.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/form_error_banner.dart';
import 'package:provider/provider.dart';

Future<void> showCreateJobDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const CreateJobDialog(),
  );
}

class CreateJobDialog extends StatefulWidget {
  const CreateJobDialog({super.key});

  @override
  State<CreateJobDialog> createState() => _CreateJobDialogState();
}

class _CreateJobDialogState extends State<CreateJobDialog> {
  String? _propertyId;
  String? _truckAssetId;
  JobType _type = JobType.diagnostic;
  final _description = TextEditingController();
  late final TextEditingController _date;
  late final TextEditingController _start;
  late final TextEditingController _end;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = TextEditingController(text: todayIso());
    _start = TextEditingController(text: '09:00');
    _end = TextEditingController(text: '11:00');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FleetController>().load();
    });
  }

  @override
  void dispose() {
    _description.dispose();
    _date.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final directory = context.watch<CustomerController>();
    final fleet = context.watch<FleetController>();
    final properties = directory.properties;
    final trucks = fleet.truckOptionsForJob();
    _propertyId ??= properties.isEmpty ? null : properties.first.id;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('New job'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Property'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _propertyId,
                    isExpanded: true,
                    items: [
                      for (final property in properties)
                        DropdownMenuItem(
                          value: property.id,
                          child: Text(
                            '${directory.customerById(property.customerId)?.displayName ?? ''} — ${property.address}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _propertyId = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Job type'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<JobType>(
                    value: _type,
                    isExpanded: true,
                    items: [
                      for (final type in JobType.values)
                        DropdownMenuItem(value: type, child: Text(type.label)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _type = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Truck (optional)'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    key: const Key('create-job-truck'),
                    value: trucks.any((t) => t.id == _truckAssetId) ? _truckAssetId : null,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('No truck')),
                      for (final truck in trucks)
                        DropdownMenuItem(
                          value: truck.id,
                          child: Text(
                            truck.identifier.isEmpty
                                ? truck.label
                                : '${truck.label} (${truck.identifier})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _truckAssetId = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _description, label: 'Description'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _date, label: 'Date (YYYY-MM-DD)'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _start, label: 'Start (HH:mm)'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _end, label: 'End (HH:mm)'),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                FormErrorBanner(message: _error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        AppSecondaryButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        AppPrimaryButton(
          label: 'Create job',
          onPressed: _propertyId == null || _saving
              ? null
              : () async {
                  final dateError = FieldValidators.isoDate(_date.text, label: 'Date');
                  final startError = FieldValidators.timeHHmm(_start.text, label: 'Start time');
                  final endError = FieldValidators.timeHHmm(_end.text, label: 'End time');
                  final validationError = dateError ??
                      startError ??
                      endError ??
                      SchedulingValidators.endAfterStart(_start.text, _end.text);
                  if (validationError != null) {
                    setState(() => _error = validationError);
                    return;
                  }
                  setState(() {
                    _saving = true;
                    _error = null;
                  });
                  try {
                    await context.read<JobController>().createJob(
                          propertyId: _propertyId!,
                          type: _type,
                          date: _date.text.trim(),
                          startTime: _start.text.trim(),
                          endTime: _end.text.trim(),
                          description: _description.text.trim(),
                          truckAssetId: _truckAssetId,
                        );
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (error) {
                    if (!context.mounted) return;
                    setState(() {
                      _saving = false;
                      _error = FailureMapper.messageFor(error);
                    });
                  }
                },
        ),
      ],
    );
  }
}

Future<void> showRescheduleJobDialog(BuildContext context, HistoryJob job) async {
  final date = TextEditingController(text: job.date);
  final start = TextEditingController(text: job.startTime);
  final end = TextEditingController(text: job.endTime);

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Reschedule job'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(controller: date, label: 'Date (YYYY-MM-DD)'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: start, label: 'Start (HH:mm)'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: end, label: 'End (HH:mm)'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        AppPrimaryButton(label: 'Save', onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );

  final nextDate = date.text.trim();
  final nextStart = start.text.trim();
  final nextEnd = end.text.trim();
  date.dispose();
  start.dispose();
  end.dispose();
  if (saved != true || !context.mounted) return;

  final validationError = FieldValidators.isoDate(nextDate, label: 'Date') ??
      FieldValidators.timeHHmm(nextStart, label: 'Start time') ??
      FieldValidators.timeHHmm(nextEnd, label: 'End time');
  if (validationError != null) return;

  await context.read<JobController>().rescheduleJob(
        jobId: job.id,
        date: nextDate,
        startTime: nextStart,
        endTime: nextEnd,
      );
}
