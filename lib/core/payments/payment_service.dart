import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/logging/hvac_log.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/models/office_payment.dart';
import 'package:hvac_admin/core/payments/payment_provider.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';
import 'package:hvac_admin/data/repositories/billing_repository.dart';

class PaymentService {
  PaymentService({
    required BillingRepository repository,
    required PaymentProvider provider,
  })  : _repository = repository,
        _provider = provider;

  final BillingRepository _repository;
  final PaymentProvider _provider;

  Future<PaymentCheckoutSession> startCheckout(OfficeInvoice invoice) async {
    // Phase 22: charge the tax-inclusive grand total (manual payments match).
    final session = await _provider.createCheckout(invoice: invoice, amount: invoice.grandTotal);
    final persisted = MapperHelpers.isUuid(session.payment.id)
        ? session.payment
        : await _repository.savePayment(session.payment);
    HvacLog.info('payment.checkout_started', fields: {
      'invoice_id': invoice.id,
      'payment_id': persisted.id,
      'provider_payment_id': persisted.providerPaymentId,
      'amount': persisted.amount,
    });
    return PaymentCheckoutSession(payment: persisted, checkoutUrl: session.checkoutUrl);
  }

  /// Mock/test helper — production Stripe webhooks hit the edge function + RPC only.
  Future<OfficePayment> ingestWebhook({
    required bool signatureValid,
    required String provider,
    required String externalPaymentId,
    required PaymentStatus status,
    String failureReason = '',
  }) async {
    if (!signatureValid) {
      HvacLog.warn('payment.webhook_rejected', fields: {
        'provider': provider,
        'external_payment_id': externalPaymentId,
        'reason': 'invalid_signature',
      });
      throw StateError('Payment webhook signature invalid');
    }
    final current = await _repository.paymentByProviderId(provider, externalPaymentId);
    if (current == null) {
      HvacLog.warn('payment.webhook_rejected', fields: {
        'provider': provider,
        'external_payment_id': externalPaymentId,
        'reason': 'payment_not_found',
      });
      throw StateError('Payment not found for webhook');
    }
    final updated = await _repository.savePayment(
      current.copyWith(
        status: status,
        paidAt: status == PaymentStatus.succeeded ? DateTime.now().toIso8601String() : current.paidAt,
        failureReason: failureReason,
      ),
    );
    if (status == PaymentStatus.succeeded) {
      final invoice = await _repository.getInvoice(updated.invoiceId);
      if (invoice != null) {
        await _repository.updateInvoiceStatus(invoice.id, InvoiceStatus.paid);
      }
    }
    HvacLog.info('payment.webhook_ingested', fields: {
      'payment_id': updated.id,
      'invoice_id': updated.invoiceId,
      'status': status.name,
    });
    return updated;
  }

  Future<OfficePayment> recordManualPayment(OfficeInvoice invoice) async {
    final payment = OfficePayment(
      id: 'pay_manual_${DateTime.now().microsecondsSinceEpoch}',
      invoiceId: invoice.id,
      jobId: invoice.jobId,
      propertyId: invoice.propertyId,
      amount: invoice.grandTotal,
      status: PaymentStatus.succeeded,
      provider: 'manual',
      providerPaymentId: 'manual_${invoice.number}',
      createdAt: DateTime.now().toIso8601String(),
      paidAt: DateTime.now().toIso8601String(),
    );
    final saved = await _repository.savePayment(payment);
    await _repository.updateInvoiceStatus(invoice.id, InvoiceStatus.paid);
    HvacLog.info('payment.manual_recorded', fields: {
      'invoice_id': invoice.id,
      'payment_id': saved.id,
      'amount': saved.amount,
    });
    return saved;
  }
}
