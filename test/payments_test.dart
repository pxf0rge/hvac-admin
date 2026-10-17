import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/models/office_payment.dart';
import 'package:hvac_admin/core/payments/payment_checkout_exception.dart';
import 'package:hvac_admin/core/payments/payment_provider.dart';
import 'package:hvac_admin/core/payments/payment_service.dart';
import 'package:hvac_admin/core/payments/payments_status_service.dart';
import 'package:hvac_admin/core/controllers/invoice_controller.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  const invoice = OfficeInvoice(
    id: MockSeedIds.invoiceId,
    number: 'INV-TEST',
    status: InvoiceStatus.sent,
    date: '2026-08-29',
    dueDate: '2026-09-12',
    propertyId: MockSeedIds.propertyId,
    jobId: MockSeedIds.jobId,
    notes: 'Checkout test',
    items: [BillingLineItem(description: 'Service', quantity: 1, unitPrice: 129)],
  );

  test('PaymentCheckoutException parses edge function 503', () {
    final error = PaymentCheckoutException.fromFunctionResponse(
      status: 503,
      data: {
        'error': 'PAYMENTS_NOT_CONFIGURED',
        'message': 'Stripe credentials are not configured',
      },
    );
    expect(error.isNotConfigured, isTrue);
    expect(error.code, 'PAYMENTS_NOT_CONFIGURED');
  });

  test('PaymentService skips duplicate save when provider returns server payment id', () async {
    final repo = MockBillingRepository();
    final provider = _PrefilledPaymentProvider();
    final service = PaymentService(repository: repo, provider: provider);

    final before = (await repo.getPayments()).length;
    final session = await service.startCheckout(invoice);
    final after = (await repo.getPayments()).length;

    expect(session.payment.id, MockSeedIds.paymentId);
    expect(session.checkoutUrl, contains('checkout'));
    expect(after, before);
  });

  test('mock checkout webhook marks invoice paid', () async {
    final repo = MockBillingRepository();
    final service = PaymentService(repository: repo, provider: MockPaymentProvider(start: 9100));
    final session = await service.startCheckout(invoice);

    final paid = await service.ingestWebhook(
      signatureValid: true,
      provider: 'mock',
      externalPaymentId: session.payment.providerPaymentId!,
      status: PaymentStatus.succeeded,
    );
    expect(paid.status, PaymentStatus.succeeded);

    final loaded = await repo.getInvoice(MockSeedIds.invoiceId);
    expect(loaded?.status, InvoiceStatus.paid);
  });

  test('invalid webhook signature throws without mutating payment', () async {
    final repo = MockBillingRepository();
    final service = PaymentService(repository: repo, provider: MockPaymentProvider(start: 9101));
    final session = await service.startCheckout(invoice);

    expect(
      () => service.ingestWebhook(
        signatureValid: false,
        provider: 'mock',
        externalPaymentId: session.payment.providerPaymentId!,
        status: PaymentStatus.succeeded,
      ),
      throwsStateError,
    );

    final payments = await repo.getPayments(invoiceId: MockSeedIds.invoiceId);
    expect(payments.first.status, PaymentStatus.requiresPayment);
  });

  test('InvoiceController records manual payment', () async {
    final repo = MockBillingRepository();
    final controller = InvoiceController(repo);
    final payment = await controller.recordManualPayment(MockSeedIds.invoiceId);
    expect(payment.provider, 'manual');
    expect(payment.status, PaymentStatus.succeeded);
    final invoice = await repo.getInvoice(MockSeedIds.invoiceId);
    expect(invoice?.status, InvoiceStatus.paid);
  });

  test('MockBillingRepository seeds pending checkout on overdue invoice', () async {
    final repo = MockBillingRepository(seed: MockSeedData());
    final payments = await repo.getPayments(invoiceId: MockSeedIds.overdueInvoiceId);
    expect(payments, hasLength(1));
    expect(payments.first.status, PaymentStatus.requiresPayment);
  });

  test('PaymentsReadiness parses status payload', () {
    final status = PaymentsReadiness.fromJson({
      'stripe_configured': true,
      'test_mode': true,
      'redirects_configured': true,
      'webhook_secret_configured': true,
      'ready': true,
      'label': 'Pay online (Stripe test)',
    });
    expect(status.ready, isTrue);
    expect(status.label, 'Pay online (Stripe test)');
  });
}

class _PrefilledPaymentProvider implements PaymentProvider {
  @override
  Future<PaymentCheckoutSession> createCheckout({
    required OfficeInvoice invoice,
    required double amount,
  }) async {
    final payment = OfficePayment(
      id: MockSeedIds.paymentId,
      invoiceId: invoice.id,
      jobId: invoice.jobId,
      propertyId: invoice.propertyId,
      amount: amount,
      status: PaymentStatus.requiresPayment,
      provider: 'mock',
      providerPaymentId: 'mock_pi_server',
      checkoutUrl: 'https://pay.hvacpro.example/checkout/mock_pi_server',
      createdAt: DateTime.now().toIso8601String(),
    );
    return PaymentCheckoutSession(payment: payment, checkoutUrl: payment.checkoutUrl!);
  }
}
