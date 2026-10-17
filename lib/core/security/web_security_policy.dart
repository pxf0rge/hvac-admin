/// Recommended HTTP response headers for admin web deployments.
///
/// Prefer serving these from your CDN / reverse proxy. The CSP value is also
/// mirrored in `web/index.html` for static hosting without header injection.
abstract final class WebSecurityPolicy {
  WebSecurityPolicy._();

  /// Flutter web + Supabase realtime. Tighten `connect-src` per environment host.
  static final contentSecurityPolicy = [
    "default-src 'self'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
    "object-src 'none'",
    "script-src 'self' 'wasm-unsafe-eval'",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob: https:",
    "font-src 'self' data:",
    "connect-src 'self' https://*.supabase.co wss://*.supabase.co https://storage.googleapis.com",
    "worker-src 'self' blob:",
  ].join('; ');

  static const referrerPolicy = 'strict-origin-when-cross-origin';

  static const permissionsPolicy = 'camera=(), microphone=(), geolocation=()';
}
