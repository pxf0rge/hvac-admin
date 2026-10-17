import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/models/office_payment.dart';

class PaymentCheckoutSession {
  const PaymentCheckoutSession({
    required this.payment,
    required this.checkoutUrl,
  });

  final OfficePayment payment;
  final String checkoutUrl;
}

/// Swappable online payment provider (mock in dev/tests; Stripe via edge function in prod).
abstract class PaymentProvider {
  Future<PaymentCheckoutSession> createCheckout({
    required OfficeInvoice invoice,
    required double amount,
  });
}

class MockPaymentProvider implements PaymentProvider {
  MockPaymentProvider({int start = 5000}) : _next = start;

  int _next;

  @override
  Future<PaymentCheckoutSession> createCheckout({
    required OfficeInvoice invoice,
    required double amount,
  }) async {
    final providerId = 'mock_pi_$_next';
    _next += 1;
    final payment = OfficePayment(
      id: 'pay_${DateTime.now().microsecondsSinceEpoch}',
      invoiceId: invoice.id,
      jobId: invoice.jobId,
      propertyId: invoice.propertyId,
      amount: amount,
      status: PaymentStatus.requiresPayment,
      provider: 'mock',
      providerPaymentId: providerId,
      checkoutUrl: 'https://pay.hvacpro.example/checkout/$providerId',
      createdAt: DateTime.now().toIso8601String(),
    );
    return PaymentCheckoutSession(payment: payment, checkoutUrl: payment.checkoutUrl!);
  }
}
