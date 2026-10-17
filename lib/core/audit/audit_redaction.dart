/// Strips secrets and payment artifacts from log/audit payloads.
class AuditRedaction {
  AuditRedaction._();

  static final _sensitiveKey = RegExp(
    r'(password|passwd|secret|token|api[_-]?key|authorization|bearer|card|cvv|cvc|pan|ssn|stripe|sk_live|sk_test|webhook_secret)',
    caseSensitive: false,
  );

  static final _secretValue = RegExp(
    r'^(sk_live_|sk_test_|re_[A-Za-z0-9]{20,}|eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.)',
  );

  static Map<String, Object?> sanitizeFields(Map<String, Object?> fields) {
    return {
      for (final entry in fields.entries) entry.key: _sanitizeValue(entry.key, entry.value),
    };
  }

  static Map<String, Object?> sanitizeMetadata(Map<String, Object?> metadata) => sanitizeFields(metadata);

  static Object? _sanitizeValue(String key, Object? value) {
    if (_sensitiveKey.hasMatch(key)) return '[REDACTED]';
    if (value is String && _secretValue.hasMatch(value)) return '[REDACTED]';
    if (value is Map) {
      return sanitizeFields(Map<String, Object?>.from(value));
    }
    if (value is Iterable) {
      return value.map((item) => item is Map<String, Object?> ? sanitizeFields(item) : item).toList();
    }
    return value;
  }
}
