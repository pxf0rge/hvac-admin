import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/audit/audit_redaction.dart';
import 'package:hvac_admin/core/logging/hvac_log.dart';

void main() {
  test('AuditRedaction masks sensitive keys', () {
    final sanitized = AuditRedaction.sanitizeFields({
      'payment_id': 'pay_1',
      'password': 'hunter2',
      'stripe_secret_key': 'sk_live_abc123',
      'authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9.test',
    });

    expect(sanitized['payment_id'], 'pay_1');
    expect(sanitized['password'], '[REDACTED]');
    expect(sanitized['stripe_secret_key'], '[REDACTED]');
    expect(sanitized['authorization'], '[REDACTED]');
  });

  test('HvacLog never writes raw secrets to sink', () {
    final sink = MemoryHvacLogSink();
    final previous = HvacLog.sink;
    HvacLog.sink = sink;
    addTearDown(() => HvacLog.sink = previous);

    HvacLog.info('auth.sign_in', fields: {'email': 'user@example.com', 'password': 'secret123'});
    HvacLog.warn('payment.checkout_failed', fields: {'card_number': '4111111111111111'});

    expect(sink.lines.length, 2);
    expect(sink.lines.join('\n'), isNot(contains('secret123')));
    expect(sink.lines.join('\n'), isNot(contains('4111111111111111')));
    expect(sink.lines.first, contains('[REDACTED]'));
  });
}
