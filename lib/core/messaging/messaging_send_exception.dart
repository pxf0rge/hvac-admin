class MessagingSendException implements Exception {
  MessagingSendException(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  bool get isNotConfigured => code == 'MESSAGING_NOT_CONFIGURED';

  @override
  String toString() => 'MessagingSendException($code): $message';

  static MessagingSendException fromFunctionResponse({
    required int? status,
    required dynamic data,
  }) {
    if (data is Map) {
      final code = data['error']?.toString() ?? data['code']?.toString() ?? 'send_failed';
      final message = data['message']?.toString() ?? data['error']?.toString() ?? 'Outbound send failed';
      return MessagingSendException(code, message, statusCode: status);
    }
    return MessagingSendException(
      'send_failed',
      data?.toString() ?? 'Outbound send failed',
      statusCode: status,
    );
  }
}
