import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/accounting/accounting_csv_builder.dart';
import 'package:hvac_admin/core/accounting/accounting_export_provider.dart';
import 'package:hvac_admin/core/accounting/accounting_export_schema.dart';
import 'package:hvac_admin/core/accounting/accounting_export_service.dart';
import 'package:hvac_admin/core/audit/audit_actions.dart';
import 'package:hvac_admin/core/audit/in_memory_audit_log.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_audit_log_repository.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('CSV builder escapes commas and quotes', () {
    final csv = buildAccountingCsv([
      const AccountingExportRow(
        invoiceNumber: 'INV-1',
        invoiceId: 'id',
        customerId: 'c1',
        customerName: 'Nguyen, Pat',
        propertyAddress: '77 "Oak" Lane',
        jobId: 'j1',
        issuedOn: '2026-08-28',
        dueOn: '2026-09-11',
        amount: 185,
        currency: 'usd',
        taxAmount: 0,
        invoiceStatus: 'sent',
        paymentStatus: 'unpaid',
        paymentProvider: '',
        paymentAmountTotal: 0,
        paymentPaidAt: '',
        paymentIds: '',
      ),
    ]);
    expect(csv, startsWith(AccountingExportColumns.headers.join(',')));
    expect(csv, contains('"Nguyen, Pat"'));
    expect(csv, contains('"77 ""Oak"" Lane"'));
  });

  test('LocalAccountingCsvProvider maps seed invoices', () async {
    final seed = MockSeedData();
    final properties = {for (final p in seed.properties) p.id: p};
    final customers = {for (final c in seed.customers) c.id: c};
    final rows = await const LocalAccountingCsvProvider().buildRows(
      invoices: seed.invoices,
      payments: seed.payments,
      propertiesById: properties,
      customersById: customers,
    );
    expect(rows, hasLength(2));
    final overdue = rows.firstWhere((r) => r.invoiceId == MockSeedIds.overdueInvoiceId);
    expect(overdue.paymentStatus, 'unpaid');
    expect(overdue.amount, 420);
  });

  test('export service rejects inverted date range', () async {
    final auditLog = InMemoryAuditLog();
    final service = AccountingExportService(
      billing: MockBillingRepository(seed: MockSeedData(), auditLog: auditLog),
      audit: MockAuditLogRepository(auditLog),
    );
    expect(
      () => service.exportForAccounting(
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 8, 1),
        propertiesById: const {},
        customersById: const {},
      ),
      throwsA(
        isA<AccountingExportException>().having(
          (e) => e.message,
          'message',
          contains('End date'),
        ),
      ),
    );
  });

  test('export service returns clear message for empty range', () async {
    final auditLog = InMemoryAuditLog();
    final service = AccountingExportService(
      billing: MockBillingRepository(seed: MockSeedData(), auditLog: auditLog),
      audit: MockAuditLogRepository(auditLog),
    );
    expect(
      () => service.exportForAccounting(
        from: DateTime(2020, 1, 1),
        to: DateTime(2020, 1, 31),
        propertiesById: const {},
        customersById: const {},
      ),
      throwsA(
        isA<AccountingExportException>().having(
          (e) => e.message,
          'message',
          'No invoices in this date range.',
        ),
      ),
    );
  });

  test('export service builds CSV and records audit', () async {
    final auditLog = InMemoryAuditLog();
    final seed = MockSeedData();
    final service = AccountingExportService(
      billing: MockBillingRepository(seed: seed, auditLog: auditLog),
      audit: MockAuditLogRepository(auditLog),
    );
    final properties = {for (final p in seed.properties) p.id: p};
    final customers = {for (final c in seed.customers) c.id: c};

    final result = await service.exportForAccounting(
      from: DateTime(2026, 8, 1),
      to: DateTime(2026, 8, 31),
      propertiesById: properties,
      customersById: customers,
    );

    expect(result.rowCount, greaterThanOrEqualTo(1));
    expect(result.csv, contains('invoice_number'));
    expect(result.csv, contains('INV-'));
    expect(result.filename, contains('hvac_accounting_2026-08-01_2026-08-31.csv'));

    final exports = [
      for (final e in auditLog.entries)
        if (e.action == AuditActions.accountingExport) e,
    ];
    expect(exports, hasLength(1));
    expect(exports.first.metadata['row_count'], result.rowCount);
  });

  test('QuickBooks stub is unimplemented', () async {
    expect(
      () => const QuickBooksAccountingExportStub().buildRows(
        invoices: const [],
        payments: const [],
        propertiesById: const <String, OfficeProperty>{},
        customersById: const <String, OfficeCustomer>{},
      ),
      throwsUnimplementedError,
    );
  });
}
