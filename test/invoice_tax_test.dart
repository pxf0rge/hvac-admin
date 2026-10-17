import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/accounting/accounting_csv_builder.dart';
import 'package:hvac_admin/core/accounting/accounting_export_provider.dart';
import 'package:hvac_admin/core/accounting/accounting_export_schema.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/data/mappers/billing_mapper.dart';

/// Phase 22 — invoice tax fields: mapper round-trip + CSV tax_amount.
void main() {
  final items = const [
    BillingLineItem(description: 'Labor', quantity: 2, unitPrice: 100),
    BillingLineItem(description: 'Capacitor', quantity: 1, unitPrice: 45),
  ];

  test('tax-inclusive totals compute from invoice-level rate', () {
    final invoice = OfficeInvoice(
      id: 'inv_1',
      number: 'INV-TAX',
      status: InvoiceStatus.sent,
      date: '2026-09-01',
      dueDate: '2026-09-15',
      propertyId: 'p1',
      jobId: 'j1',
      notes: '',
      items: items,
      taxRatePct: 8.25,
    );
    expect(invoice.amount, 245);
    expect(invoice.taxAmount, closeTo(20.2125, 0.0001));
    expect(invoice.grandTotal, closeTo(265.2125, 0.0001));
  });

  test('legacy tax-free invoices stay valid (0 tax)', () {
    final invoice = OfficeInvoice(
      id: 'inv_2',
      number: 'INV-OLD',
      status: InvoiceStatus.sent,
      date: '2026-09-01',
      dueDate: '2026-09-15',
      propertyId: 'p1',
      jobId: 'j1',
      notes: '',
      items: items,
    );
    expect(invoice.taxRatePct, isNull);
    expect(invoice.taxAmount, 0);
    expect(invoice.grandTotal, invoice.amount);
  });

  test('billing mapper round-trips tax_rate_pct (null and value)', () {
    final withTax = OfficeInvoice(
      id: 'inv_3',
      number: 'INV-RT',
      status: InvoiceStatus.draft,
      date: '2026-09-01',
      dueDate: '2026-09-15',
      propertyId: 'p1',
      jobId: 'j1',
      notes: '',
      items: items,
      taxRatePct: 8.25,
    );
    final row = BillingMapper.invoiceToRow(withTax);
    expect(row['tax_rate_pct'], 8.25);
    final parsed = BillingMapper.invoiceFromRow({
      ...row,
      'estimate_id': null,
    }, items: items);
    expect(parsed.taxRatePct, 8.25);

    final withoutTax = BillingMapper.invoiceFromRow({
      ...BillingMapper.invoiceToRow(withTax),
      'tax_rate_pct': null,
      'estimate_id': null,
    }, items: items);
    expect(withoutTax.taxRatePct, isNull);
  });

  test('CSV tax_amount is non-zero when tax set', () async {
    final invoice = OfficeInvoice(
      id: 'inv_tax_csv',
      number: 'INV-CSV',
      status: InvoiceStatus.sent,
      date: '2026-09-01',
      dueDate: '2026-09-15',
      propertyId: 'p1',
      jobId: 'j1',
      notes: '',
      items: items,
      taxRatePct: 8.25,
    );
    final rows = await const LocalAccountingCsvProvider().buildRows(
      invoices: [invoice],
      payments: const [],
      propertiesById: const {},
      customersById: const {},
    );
    expect(rows.single.taxAmount, closeTo(20.2125, 0.0001));

    final csv = buildAccountingCsv(rows);
    final taxColumn = AccountingExportColumns.headers.indexOf('tax_amount');
    final line = csv.split('\n').firstWhere((l) => l.contains('INV-CSV'));
    expect(line.split(',')[taxColumn], isNot('0.00'));
  });
}
