import 'package:hvac_admin/core/logging/hvac_log.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/payments/payment_checkout_exception.dart';
import 'package:hvac_admin/core/payments/payment_provider.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';
import 'package:hvac_admin/data/mappers/payment_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Online checkout via `create-checkout` edge function (Stripe secrets server-side).
class SupabasePaymentProvider implements PaymentProvider {
  SupabasePaymentProvider(this._client);

  final SupabaseClient _client;

  @override
  Future<PaymentCheckoutSession> createCheckout({
    required OfficeInvoice invoice,
    required double amount,
  }) async {
    if (!MapperHelpers.isUuid(invoice.id)) {
      throw PaymentCheckoutException(
        'invalid_invoice',
        'Supabase checkout requires invoice UUID',
      );
    }

    try {
      final response = await _client.functions.invoke(
        'create-checkout',
        body: {
          'invoice_id': invoice.id,
          'amount': amount,
          'currency': 'usd',
          'invoice_number': invoice.number,
        },
      );

      final status = response.status;
      final data = response.data;
      if (status >= 400) {
        final error = PaymentCheckoutException.fromFunctionResponse(status: status, data: data);
        HvacLog.warn('payment.checkout_failed', fields: {
          'code': error.code,
          'invoice_id': invoice.id,
          'status': status,
        });
        throw error;
      }

      if (data is! Map) {
        throw PaymentCheckoutException('invalid_response', 'create-checkout returned unexpected payload');
      }

      final row = MapperHelpers.row(Map<String, dynamic>.from(data));
      final payment = PaymentMapper.fromRow({
        'id': row['payment_id'] ?? row['id'],
        'invoice_id': row['invoice_id'] ?? invoice.id,
        'job_id': row['job_id'] ?? invoice.jobId,
        'property_id': row['property_id'] ?? invoice.propertyId,
        'amount': row['amount'] ?? amount,
        'currency': row['currency'] ?? 'usd',
        'status': row['status'] ?? 'requires_payment',
        'provider': row['provider'] ?? 'mock',
        'provider_payment_id': row['provider_payment_id'],
        'provider_checkout_url': row['checkout_url'] ?? row['provider_checkout_url'],
        'created_at': row['created_at'] ?? DateTime.now().toIso8601String(),
        'failure_reason': '',
      });
      final checkoutUrl = MapperHelpers.str(row['checkout_url'] ?? row['provider_checkout_url']);
      if (checkoutUrl.isEmpty) {
        throw PaymentCheckoutException('invalid_response', 'create-checkout missing checkout_url');
      }

      HvacLog.info('payment.checkout_started', fields: {
        'invoice_id': invoice.id,
        'payment_id': payment.id,
        'provider': payment.provider,
        'provider_payment_id': payment.providerPaymentId,
      });

      return PaymentCheckoutSession(payment: payment, checkoutUrl: checkoutUrl);
    } on PaymentCheckoutException {
      rethrow;
    } catch (error, stack) {
      HvacLog.error('payment.checkout_failed', error: error, stack: stack, fields: {
        'invoice_id': invoice.id,
      });
      throw PaymentCheckoutException('checkout_failed', error.toString());
    }
  }
}
