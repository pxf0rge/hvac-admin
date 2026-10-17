import 'package:hvac_admin/core/accounting/accounting_csv_builder.dart';
import 'package:hvac_admin/core/accounting/accounting_export_provider.dart';
import 'package:hvac_admin/core/accounting/csv_download.dart';
import 'package:hvac_admin/core/audit/audit_actions.dart';
import 'package:hvac_admin/core/billing/invoice_policy.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/data/repositories/audit_repository.dart';
import 'package:hvac_admin/data/repositories/billing_repository.dart';

class AccountingExportException implements Exception {
  AccountingExportException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AccountingExportResult {
  const AccountingExportResult({
    required this.csv,
    required this.filename,
    required this.rowCount,
    required this.downloaded,
  });

  final String csv;
  final String filename;
  final int rowCount;
  final bool downloaded;
}

class AccountingExportService {
  AccountingExportService({
    required BillingRepository billing,
    required AuditRepository audit,
    AccountingExportProvider? provider,
  })  : _billing = billing,
        _audit = audit,
        _provider = provider ?? const LocalAccountingCsvProvider();

  final BillingRepository _billing;
  final AuditRepository _audit;
  final AccountingExportProvider _provider;

  /// Builds and downloads CSV for invoices whose [issued_on] falls in [from]–[to] (inclusive, date-only).
  Future<AccountingExportResult> exportForAccounting({
    required DateTime from,
    required DateTime to,
    required Map<String, OfficeProperty> propertiesById,
    required Map<String, OfficeCustomer> customersById,
  }) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    if (end.isBefore(start)) {
      throw AccountingExportException('End date must be on or after the start date.');
    }

    final invoices = [
      for (final invoice in await _billing.getInvoices())
        InvoicePolicy.withEffectiveStatus(invoice),
    ];
    final payments = await _billing.getPayments();

    final inRange = [
      for (final invoice in invoices)
        if (_issuedInRange(invoice.date, start, end)) invoice,
    ]..sort((a, b) => a.date.compareTo(b.date));

    if (inRange.isEmpty) {
      throw AccountingExportException('No invoices in this date range.');
    }

    final rows = await _provider.buildRows(
      invoices: inRange,
      payments: payments,
      propertiesById: propertiesById,
      customersById: customersById,
    );
    final csv = buildAccountingCsv(rows);
    final filename =
        'hvac_accounting_${_ymd(start)}_${_ymd(end)}.csv';

    await _audit.recordAction(
      action: AuditActions.accountingExport,
      entityType: 'accounting_export',
      entityId: '${_ymd(start)}_${_ymd(end)}',
      metadata: {
        'provider': _provider.id,
        'from': _ymd(start),
        'to': _ymd(end),
        'row_count': rows.length,
        'filename': filename,
      },
    );

    final downloaded = downloadTextFile(filename: filename, content: csv);
    return AccountingExportResult(
      csv: csv,
      filename: filename,
      rowCount: rows.length,
      downloaded: downloaded,
    );
  }

  bool _issuedInRange(String issuedOn, DateTime start, DateTime end) {
    final parsed = DateTime.tryParse(issuedOn.trim());
    if (parsed == null) return false;
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
