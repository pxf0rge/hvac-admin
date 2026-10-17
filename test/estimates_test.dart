import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/billing/estimate_totals.dart';
import 'package:hvac_admin/core/controllers/estimate_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('EstimateTotals computes tax and total', () {
    const items = [BillingLineItem(description: 'Labor', quantity: 2, unitPrice: 95)];
    final totals = EstimateTotals.fromItems(items, taxRate: 0.1);
    expect(totals.subtotal, 190);
    expect(totals.tax, closeTo(19, 0.01));
    expect(totals.total, closeTo(209, 0.01));
  });

  test('MockBillingRepository filters estimates by status', () async {
    final repo = MockBillingRepository();
    final sent = await repo.getEstimates(status: EstimateStatus.sent);
    expect(sent.every((item) => item.status == EstimateStatus.sent), isTrue);
    expect(sent.any((item) => item.id == MockSeedIds.openEstimateId), isTrue);
  });

  test('MockBillingRepository saves and loads draft estimate', () async {
    final repo = MockBillingRepository();
    final controller = EstimateController(repo);
    final saved = await controller.saveDraft(
      propertyId: MockSeedIds.propertyId,
      jobId: MockSeedIds.jobId,
      notes: 'Test draft',
      items: const [BillingLineItem(description: 'Diagnostic fee', quantity: 1, unitPrice: 89)],
    );
    expect(saved.status, EstimateStatus.draft);
    final loaded = await repo.getEstimate(saved.id);
    expect(loaded?.notes, 'Test draft');
    expect(loaded?.items.length, 1);
  });

  test('MockBillingRepository converts approved estimate to invoice', () async {
    final repo = MockBillingRepository();
    final existing = await repo.getInvoiceForEstimate(MockSeedIds.estimateId);
    expect(existing, isNotNull);
    final invoice = await repo.convertEstimateToInvoice(MockSeedIds.estimateId);
    expect(invoice.estimateId, MockSeedIds.estimateId);
    expect(invoice.id, existing!.id);

    final saved = await repo.saveEstimate(
      (await repo.getEstimate(MockSeedIds.openEstimateId))!.copyWith(status: EstimateStatus.approved),
    );
    final created = await repo.convertEstimateToInvoice(saved.id);
    expect(created.status, InvoiceStatus.draft);
    expect(created.estimateId, saved.id);
  });
}
