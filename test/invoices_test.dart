import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/billing/estimate_totals.dart';
import 'package:hvac_admin/core/billing/invoice_policy.dart';
import 'package:hvac_admin/core/controllers/invoice_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('InvoicePolicy detects past-due sent invoices', () {
    const invoice = OfficeInvoice(
      id: 'x',
      number: 'INV-TEST',
      status: InvoiceStatus.sent,
      date: '2026-08-01',
      dueDate: '2026-08-15',
      propertyId: 'p',
      jobId: 'j',
      notes: '',
      items: const [BillingLineItem(description: 'Labor', quantity: 1, unitPrice: 100)],
    );
    expect(
      InvoicePolicy.effectiveStatus(invoice, now: DateTime(2026, 8, 30)),
      InvoiceStatus.overdue,
    );
  });

  test('MockBillingRepository filters invoices by status', () async {
    final repo = MockBillingRepository();
    final overdue = await repo.getInvoices(status: InvoiceStatus.overdue);
    expect(overdue.any((item) => item.id == MockSeedIds.overdueInvoiceId), isTrue);
  });

  test('InvoiceController saves draft invoice', () async {
    final repo = MockBillingRepository();
    final controller = InvoiceController(repo);
    final saved = await controller.saveDraft(
      propertyId: MockSeedIds.propertyId,
      jobId: MockSeedIds.jobId,
      notes: 'Diagnostic visit',
      items: const [BillingLineItem(description: 'Service call', quantity: 1, unitPrice: 129)],
    );
    expect(saved.status, InvoiceStatus.draft);
    final loaded = await repo.getInvoice(saved.id);
    expect(loaded?.notes, 'Diagnostic visit');
    expect(loaded?.items.length, 1);
  });

  test('InvoiceController marks paid and void', () async {
    final repo = MockBillingRepository();
    final controller = InvoiceController(repo);
    final paid = await controller.markPaid(MockSeedIds.overdueInvoiceId);
    expect(paid.status, InvoiceStatus.paid);
    final voided = await controller.markVoid(MockSeedIds.overdueInvoiceId);
    expect(voided.status, InvoiceStatus.cancelled);
  });

  test('Invoice totals include tax', () {
    const items = [BillingLineItem(description: 'Part', quantity: 1, unitPrice: 200)];
    final totals = EstimateTotals.fromItems(items);
    expect(totals.total, greaterThan(totals.subtotal));
  });
}
