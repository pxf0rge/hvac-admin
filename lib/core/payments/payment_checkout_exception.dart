/// Raised when checkout is unavailable or the edge function rejects a request.
class PaymentCheckoutException implements Exception {
  PaymentCheckoutException(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  bool get isNotConfigured => code == 'PAYMENTS_NOT_CONFIGURED';

  @override
  String toString() => 'PaymentCheckoutException($code): $message';

  static PaymentCheckoutException fromFunctionResponse({
    required int? status,
    required dynamic data,
  }) {
    if (data is Map) {
      final code = data['error']?.toString() ?? data['code']?.toString() ?? 'checkout_failed';
      final message = data['message']?.toString() ?? data['error']?.toString() ?? 'Checkout failed';
      return PaymentCheckoutException(code, message, statusCode: status);
    }
    return PaymentCheckoutException(
      'checkout_failed',
      data?.toString() ?? 'Checkout failed',
      statusCode: status,
    );
  }
}
