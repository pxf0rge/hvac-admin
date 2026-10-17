import 'package:hvac_admin/core/models/office_payment.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';

abstract final class PaymentMapper {
  static OfficePayment fromRow(Map<String, dynamic> row) {
    return OfficePayment(
      id: MapperHelpers.uuid(row['id']),
      invoiceId: MapperHelpers.uuid(row['invoice_id']),
      jobId: MapperHelpers.strOrNull(row['job_id']),
      propertyId: MapperHelpers.strOrNull(row['property_id']),
      amount: MapperHelpers.dbl(row['amount']),
      currency: MapperHelpers.str(row['currency'], fallback: 'usd'),
      status: PaymentStatusX.tryParse(MapperHelpers.str(row['status'])) ?? PaymentStatus.requiresPayment,
      provider: MapperHelpers.str(row['provider'], fallback: 'mock'),
      providerPaymentId: MapperHelpers.strOrNull(row['provider_payment_id']),
      checkoutUrl: MapperHelpers.strOrNull(row['provider_checkout_url']),
      createdAt: MapperHelpers.isoTimestamp(row['created_at']),
      paidAt: row['paid_at'] == null ? null : MapperHelpers.isoTimestamp(row['paid_at']),
      failureReason: MapperHelpers.str(row['failure_reason']),
    );
  }

  static Map<String, dynamic> toRow(OfficePayment payment) => {
        if (MapperHelpers.isUuid(payment.id)) 'id': payment.id,
        'invoice_id': payment.invoiceId,
        if (payment.jobId != null) 'job_id': payment.jobId,
        if (payment.propertyId != null) 'property_id': payment.propertyId,
        'amount': payment.amount,
        'currency': payment.currency,
        'status': payment.status.sqlValue,
        'provider': payment.provider,
        if (payment.providerPaymentId != null) 'provider_payment_id': payment.providerPaymentId,
        if (payment.checkoutUrl != null) 'provider_checkout_url': payment.checkoutUrl,
        if (payment.paidAt != null) 'paid_at': payment.paidAt,
        'failure_reason': payment.failureReason,
      };
}
