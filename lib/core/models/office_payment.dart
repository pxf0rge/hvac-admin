enum PaymentStatus {
  requiresPayment,
  processing,
  succeeded,
  failed,
  canceled,
  refunded,
}

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.requiresPayment => 'Awaiting payment',
        PaymentStatus.processing => 'Processing',
        PaymentStatus.succeeded => 'Succeeded',
        PaymentStatus.failed => 'Failed',
        PaymentStatus.canceled => 'Canceled',
        PaymentStatus.refunded => 'Refunded',
      };

  String get sqlValue => switch (this) {
        PaymentStatus.requiresPayment => 'requires_payment',
        PaymentStatus.processing => 'processing',
        PaymentStatus.succeeded => 'succeeded',
        PaymentStatus.failed => 'failed',
        PaymentStatus.canceled => 'canceled',
        PaymentStatus.refunded => 'refunded',
      };

  static PaymentStatus? tryParse(String? raw) {
    for (final status in PaymentStatus.values) {
      if (status.sqlValue == raw || status.name == raw) return status;
    }
    return null;
  }
}

class OfficePayment {
  const OfficePayment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.jobId,
    this.propertyId,
    this.currency = 'usd',
    this.provider = 'mock',
    this.providerPaymentId,
    this.checkoutUrl,
    this.paidAt,
    this.failureReason = '',
  });

  final String id;
  final String invoiceId;
  final String? jobId;
  final String? propertyId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String provider;
  final String? providerPaymentId;
  final String? checkoutUrl;
  final String createdAt;
  final String? paidAt;
  final String failureReason;

  bool get isSucceeded => status == PaymentStatus.succeeded;

  OfficePayment copyWith({
    PaymentStatus? status,
    String? paidAt,
    String? failureReason,
    String? checkoutUrl,
  }) {
    return OfficePayment(
      id: id,
      invoiceId: invoiceId,
      jobId: jobId,
      propertyId: propertyId,
      amount: amount,
      currency: currency,
      status: status ?? this.status,
      provider: provider,
      providerPaymentId: providerPaymentId,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      createdAt: createdAt,
      paidAt: paidAt ?? this.paidAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}
