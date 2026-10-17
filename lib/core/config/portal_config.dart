/// Customer portal base URL for estimate/invoice/document magic links.
class PortalConfig {
  static const _override = String.fromEnvironment('PORTAL_BASE_URL');

  /// Absolute origin without trailing slash.
  /// Prefer `--dart-define=PORTAL_BASE_URL=https://office.example.com`.
  /// Dev fallback: localhost Flutter web.
  static String get baseUrl {
    final raw = _override.trim();
    if (raw.isNotEmpty) {
      return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    }
    return 'http://localhost:8080';
  }

  static bool get isConfigured => _override.trim().isNotEmpty;

  static String estimateUrl(String token) => '$baseUrl/e/$token';
  static String invoiceUrl(String token) => '$baseUrl/i/$token';
  static String documentUrl(String token) => '$baseUrl/d/$token';
}
