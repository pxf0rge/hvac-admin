import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/accounting/accounting_export_service.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/controllers/reports_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/l10n/admin_strings.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/invoices/invoice_widgets.dart';
import 'package:hvac_admin/features/reports/report_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:provider/provider.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _section = 'all';
  DateTime _exportFrom = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _exportTo = DateTime.now();
  bool _exporting = false;
  String? _exportMessage;
  String? _exportError;
  late AdminStrings _strings;

  AdminStrings get _s => _strings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerController>().load();
      context.read<ReportsController>().load();
    });
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _exportFrom,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _exportFrom = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _exportTo,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _exportTo = picked);
  }

  Future<void> _runExport() async {
    final auth = context.read<ManagementAuthController>();
    if (!auth.canViewFinancials) {
      setState(() {
        _exportError = _s.exportOnlyOffice;
        _exportMessage = null;
      });
      return;
    }

    final directory = context.read<CustomerController>();
    final export = context.read<AccountingExportService>();
    setState(() {
      _exporting = true;
      _exportError = null;
      _exportMessage = null;
    });

    try {
      final propertiesById = <String, OfficeProperty>{
        for (final p in directory.properties) p.id: p,
      };
      final customersById = <String, OfficeCustomer>{
        for (final c in directory.customers) c.id: c,
      };
      final result = await export.exportForAccounting(
        from: _exportFrom,
        to: _exportTo,
        propertiesById: propertiesById,
        customersById: customersById,
      );
      if (!result.downloaded) {
        await Clipboard.setData(ClipboardData(text: result.csv));
      }
      if (!mounted) return;
      setState(() {
        _exporting = false;
        _exportMessage = result.downloaded
            ? _s.downloadedFile(result.filename, result.rowCount)
            : _s.csvCopied(result.filename, result.rowCount);
      });
    } on AccountingExportException catch (e) {
      if (!mounted) return;
      setState(() {
        _exporting = false;
        _exportError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _exporting = false;
        _exportError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _strings = adminStrings(context);
    final s = _s;
    final reports = context.watch<ReportsController>();
    final directory = context.watch<CustomerController>();
    final canViewFinancials = context.watch<ManagementAuthController>().canViewFinancials;
    final snap = reports.snapshot;
    final showFinancial = canViewFinancials && (_section == 'all' || _section == 'financial');
    final showJobs = _section == 'all' || _section == 'jobs';

    if (reports.isLoading && !snap.hasOperationalData && !snap.hasFinancialData) {
      return LoadingState(message: s.loadingReports);
    }

    return SingleChildScrollView(
      key: const Key('reports'),
      restorationId: 'reports-scroll',
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.reportsTitle, style: AppTypography.headlineMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text(s.reportsSubtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              AppSecondaryButton(
                label: s.refresh,
                icon: Icons.refresh,
                onPressed: () => reports.load(force: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              canViewFinancials ? s.kpisNote : s.financialReportsRestricted,
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              if (canViewFinancials) ...[
                FilterChip(
                  label: Text(s.sectionAll),
                  selected: _section == 'all',
                  onSelected: (_) => setState(() => _section = 'all'),
                ),
                FilterChip(
                  label: Text(s.sectionFinancial),
                  selected: _section == 'financial',
                  onSelected: (_) => setState(() => _section = 'financial'),
                ),
              ],
              FilterChip(
                label: Text(s.sectionJobs),
                selected: _section == 'jobs',
                onSelected: (_) => setState(() => _section = 'jobs'),
              ),
            ],
          ),
          if (showFinancial) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: s.exportForAccounting),
            SurfaceCard(
              key: const Key('reports-accounting-export'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.exportAccountingNote,
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppSecondaryButton(
                        key: const Key('reports-export-from'),
                        label: '${s.exportFrom} ${formatDate(_exportFrom.toIso8601String().split('T').first)}',
                        icon: Icons.calendar_today_outlined,
                        onPressed: _exporting ? null : _pickFrom,
                      ),
                      AppSecondaryButton(
                        key: const Key('reports-export-to'),
                        label: '${s.exportTo} ${formatDate(_exportTo.toIso8601String().split('T').first)}',
                        icon: Icons.event_outlined,
                        onPressed: _exporting ? null : _pickTo,
                      ),
                      AppPrimaryButton(
                        key: const Key('reports-export-accounting'),
                        label: _exporting ? s.exporting : s.exportButton,
                        icon: Icons.download_outlined,
                        onPressed: _exporting ? null : _runExport,
                      ),
                    ],
                  ),
                  if (_exportError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _exportError!,
                      key: const Key('reports-export-error'),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
                    ),
                  ],
                  if (_exportMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _exportMessage!,
                      key: const Key('reports-export-success'),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.success),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: s.revenue),
            if (!snap.hasFinancialData)
              SurfaceCard(
                child: Text(
                  s.noInvoiceDataYet,
                  style: AppTypography.bodyMedium,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  SizedBox(
                    width: 220,
                    child: KpiCard(
                      key: const Key('reports-paid'),
                      label: s.paidKpi,
                      value: formatCurrency(snap.paid),
                      icon: Icons.payments_outlined,
                      valueColor: AppColors.success,
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: KpiCard(
                      key: const Key('reports-outstanding'),
                      label: s.outstandingKpi,
                      value: formatCurrency(snap.outstanding),
                      icon: Icons.request_quote_outlined,
                      valueColor: AppColors.primary,
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: KpiCard(
                      key: const Key('reports-overdue'),
                      label: s.overdueKpi,
                      value: formatCurrency(snap.overdue),
                      icon: Icons.warning_amber_outlined,
                      valueColor: AppColors.danger,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: s.invoiceTracking),
            KeyedSubtree(
              key: const Key('reports-invoices'),
              child: snap.invoices.isEmpty
                  ? SurfaceCard(
                      child: Text(s.noInvoicesOnFile, style: AppTypography.bodyMedium),
                    )
                  : Column(
                      children: [
                        for (final invoice in snap.invoices) ...[
                          MobileListTile(
                            key: Key('reports-invoice-${invoice.id}'),
                            title: invoice.number,
                            subtitle:
                                '${directory.propertyById(invoice.propertyId)?.fullAddress ?? invoice.propertyId}  ·  ${formatDate(invoice.date)}',
                            meta: formatCurrency(invoice.amount),
                            trailing: InvoiceStatusChip(status: invoice.status),
                            onTap: () => context.go('${AdminModule.invoices.path}/${invoice.id}'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
            ),
          ],
          if (showJobs) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: s.jobStatistics),
            if (!snap.hasOperationalData)
              SurfaceCard(
                child: Text(s.noJobsYetCharts, style: AppTypography.bodyMedium),
              )
            else
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  SizedBox(
                    width: 180,
                    child: KpiCard(label: s.completed, value: '${snap.jobsCompleted}', icon: Icons.task_alt_outlined),
                  ),
                  SizedBox(
                    width: 180,
                    child: KpiCard(label: s.openKpi, value: '${snap.jobsOpen}', icon: Icons.work_outline),
                  ),
                  SizedBox(
                    width: 180,
                    child: KpiCard(label: s.totalKpi, value: '${snap.jobsTotal}', icon: Icons.analytics_outlined),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: s.jobVolumeByType),
            if (!snap.hasOperationalData)
              const SizedBox.shrink()
            else
              SurfaceCard(
                child: ReportBarChart(
                  key: const Key('reports-volume'),
                  bars: snap.volume,
                  emptyLabel: s.noJobsToChart,
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: s.technicianPerformance),
            SurfaceCard(
              child: !snap.hasOperationalData
                  ? Text(s.noJobsYetPerformance, style: AppTypography.bodyMedium)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!snap.hasWorkflowData)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Text(
                              s.countsUseCurrentState,
                              style: AppTypography.bodySmall,
                            ),
                          ),
                        TechnicianSummaryList(
                          rows: snap.technicians,
                          emptyLabel: s.noAssignmentsYet,
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
