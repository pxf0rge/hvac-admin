import 'package:supabase_flutter/supabase_flutter.dart';

/// Server-side Stripe readiness (no secrets). From Edge Function `payments-status`.
class PaymentsReadiness {
  const PaymentsReadiness({
    required this.stripeConfigured,
    required this.testMode,
    required this.redirectsConfigured,
    required this.webhookSecretConfigured,
    required this.ready,
    required this.label,
  });

  final bool stripeConfigured;
  final bool testMode;
  final bool redirectsConfigured;
  final bool webhookSecretConfigured;
  final bool ready;
  final String label;

  static const fallback = PaymentsReadiness(
    stripeConfigured: false,
    testMode: true,
    redirectsConfigured: false,
    webhookSecretConfigured: false,
    ready: false,
    label: 'Pay online (test)',
  );

  factory PaymentsReadiness.fromJson(Map<String, dynamic> json) {
    return PaymentsReadiness(
      stripeConfigured: json['stripe_configured'] == true,
      testMode: json['test_mode'] == true,
      redirectsConfigured: json['redirects_configured'] == true,
      webhookSecretConfigured: json['webhook_secret_configured'] == true,
      ready: json['ready'] == true,
      label: (json['label'] as String?)?.trim().isNotEmpty == true
          ? json['label'] as String
          : fallback.label,
    );
  }
}

class PaymentsStatusService {
  PaymentsStatusService(this._client);

  final SupabaseClient? _client;

  /// Widget tests / offline — always returns [PaymentsReadiness.fallback].
  PaymentsStatusService.offline() : _client = null;

  Future<PaymentsReadiness> fetch() async {
    final client = _client;
    if (client == null) return PaymentsReadiness.fallback;
    try {
      final response = await client.functions.invoke('payments-status');
      final data = response.data;
      if (response.status >= 400 || data is! Map) {
        return PaymentsReadiness.fallback;
      }
      return PaymentsReadiness.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return PaymentsReadiness.fallback;
    }
  }
}
