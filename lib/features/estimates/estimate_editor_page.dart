import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/billing/estimate_totals.dart';
import 'package:hvac_admin/core/errors/failure_mapper.dart';
import 'package:hvac_admin/core/validation/billing_validators.dart';
import 'package:hvac_admin/core/validation/field_validators.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/estimate_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/communication/communication_page.dart';
import 'package:hvac_admin/core/messaging/message_templates.dart';
import 'package:hvac_admin/features/estimates/estimate_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/form_error_banner.dart';
import 'package:provider/provider.dart';

class EstimateEditorPage extends StatefulWidget {
  const EstimateEditorPage({super.key, this.jobId, this.propertyId});

  final String? jobId;
  final String? propertyId;

  @override
  State<EstimateEditorPage> createState() => _EstimateEditorPageState();
}

class _EstimateEditorPageState extends State<EstimateEditorPage> {
  final _notes = TextEditingController();
  final List<_LineItemDraft> _items = [_LineItemDraft()];
  String? _propertyId;
  String? _jobId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _propertyId = widget.propertyId;
    _jobId = widget.jobId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CustomerController>().load();
      await context.read<JobController>().loadDispatch();
      if (_jobId != null) {
        final job = context.read<JobController>().jobById(_jobId!);
        if (job != null) _propertyId ??= job.propertyId;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  List<BillingLineItem> _lineItems() {
    return [
      for (final draft in _items)
        if (draft.description.text.trim().isNotEmpty)
          BillingLineItem(
            description: draft.description.text.trim(),
            quantity: double.tryParse(draft.quantity.text) ?? 0,
            unitPrice: double.tryParse(draft.unitPrice.text) ?? 0,
          ),
    ];
  }

  String? _validateDraft() {
    if (_jobId == null || _propertyId == null) return 'Select a job.';
    for (final draft in _items) {
      final description = draft.description.text.trim();
      if (description.isEmpty) continue;
      final qtyError = FieldValidators.positiveDecimal(draft.quantity.text, label: 'Quantity');
      if (qtyError != null) return qtyError;
      final priceError = FieldValidators.positiveDecimal(draft.unitPrice.text, label: 'Unit price');
      if (priceError != null) return priceError;
    }
    try {
      BillingValidators.validateEstimate(
        OfficeEstimate(
          id: 'draft',
          number: 'EST-DRAFT',
          status: EstimateStatus.draft,
          date: isoDate(DateTime.now()),
          propertyId: _propertyId!,
          jobId: _jobId!,
          notes: _notes.text,
          items: _lineItems(),
        ),
      );
    } on BillingValidationException catch (error) {
      return error.message;
    }
    return null;
  }

  Future<void> _save() async {
    final validationError = _validateDraft();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    final propertyId = _propertyId!;
    final jobId = _jobId!;
    final items = _lineItems();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await context.read<EstimateController>().saveDraft(
            propertyId: propertyId,
            jobId: jobId,
            notes: _notes.text.trim(),
            items: items,
          );
      if (!mounted) return;
      context.go('${AdminModule.estimates.path}/${saved.id}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = FailureMapper.messageFor(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobController>();
    final jobOptions = jobs.jobs;
    final preview = OfficeEstimate(
      id: 'preview',
      number: nextEstimateNumber(),
      status: EstimateStatus.draft,
      date: isoDate(DateTime.now()),
      propertyId: _propertyId ?? '',
      jobId: _jobId ?? '',
      notes: _notes.text,
      items: _lineItems(),
    );
    final totals = EstimateTotals.fromItems(preview.items);

    return ListView(
      key: const Key('estimate-editor'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      children: [
        const Text('New estimate', style: AppTypography.headlineMedium),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          FormErrorBanner(message: _error!),
        ],
        const SizedBox(height: AppSpacing.lg),
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Job'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: jobOptions.any((job) => job.id == _jobId) ? _jobId : null,
              isExpanded: true,
              hint: const Text('Select job'),
              items: [
                for (final job in jobOptions)
                  DropdownMenuItem(value: job.id, child: Text('${job.jobNumber} · ${formatDate(job.date)}')),
              ],
              onChanged: (value) => setState(() {
                _jobId = value;
                final job = jobs.jobById(value ?? '');
                if (job != null) _propertyId = job.propertyId;
              }),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(controller: _notes, label: 'Notes'),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Line items'),
        for (var i = 0; i < _items.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: AppTextField(controller: _items[i].description, label: 'Description'),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 72,
                child: AppTextField(controller: _items[i].quantity, label: 'Qty', keyboardType: TextInputType.number),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 96,
                child: AppTextField(
                  controller: _items[i].unitPrice,
                  label: 'Price',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              if (_items.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() {
                    _items.removeAt(i).dispose();
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppSecondaryButton(
          label: 'Add line',
          icon: Icons.add,
          onPressed: () => setState(() => _items.add(_LineItemDraft())),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Estimated total: ${formatCurrency(totals.total)}', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          key: const Key('save-estimate'),
          label: _saving ? 'Saving…' : 'Save draft',
          icon: Icons.save_outlined,
          expanded: true,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

class _LineItemDraft {
  _LineItemDraft() {
    quantity.text = '1';
  }

  final description = TextEditingController();
  final quantity = TextEditingController();
  final unitPrice = TextEditingController();

  void dispose() {
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
  }
}

String estimateEditorPath({String? jobId, String? propertyId}) {
  final params = <String, String>{
    if (jobId != null) 'jobId': jobId,
    if (propertyId != null) 'propertyId': propertyId,
  };
  return Uri(path: '${AdminModule.estimates.path}/new', queryParameters: params).toString();
}
