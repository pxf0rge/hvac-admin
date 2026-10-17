# HVAC Admin — Security overview

Client-safe secrets only. Server-side enforcement via Postgres RLS + Edge Functions (shared backend in `../hvac_client/`).

**Go-live gates:** [production-readiness.md](production-readiness.md) · **Permissions:** [permissions.md](permissions.md)

## Trust boundaries

| Layer | Responsibility |
|-------|----------------|
| Admin Flutter app | Publishable key, JWT, UI role gates, input validation |
| Supabase Auth | Identity, session, `profiles.role` (not `user_metadata`) |
| Postgres RLS | Row access (office / financial / technician-scoped) |
| Edge Functions | Stripe, Twilio, Resend, webhooks (`service_role` only) |
| Storage policies | Private buckets; signed URLs for logos/media |

**Never in Flutter:** `service_role`, webhook secrets, Stripe/Twilio/Resend API keys.

## Admin-specific authorization

| Actor | Admin app login | Financial modules | CRM / dispatch |
|-------|-----------------|-------------------|----------------|
| Owner / Admin | ✅ | ✅ | ✅ |
| Office staff | ✅ | **Deny** (UI + RLS) | ✅ |
| Technician | **Rejected** (`technicianNotAllowed`) | N/A | Use `hvac_client` |

Audit log (`/settings/audit`): owner/admin only — `requiresOwnerAdminAccess` in route guard.

**RLS is authoritative.** UI gates prevent confusion; they are not a substitute for server policy.

## Client controls

| Control | Location | Purpose |
|---------|----------|---------|
| `ProductionBootGuard` | `lib/core/config/production_boot_guard.dart` | No `Mock*` repos in staging/production boot |
| `EnvironmentGuard` | `lib/core/config/environment_guard.dart` | Wrong Supabase project per `HVAC_ENV` |
| `AuthRolePolicy` | `lib/core/security/auth_role_policy.dart` | Privileged metadata detection |
| `SecureMediaAccess` | `lib/core/media/secure_media_access.dart` | Storage path validation + signed URLs |
| `WebSecurityPolicy` / CSP | `web/index.html`, `lib/core/security/web_security_policy.dart` | XSS / framing / connect-src limits |
| `FailureMapper` | `lib/core/errors/failure_mapper.dart` | RLS `42501` → `UnauthorizedFailure` |
| `AuditRedaction` | `lib/core/audit/audit_redaction.dart` | No secrets in audit metadata |
| `HvacLog` | `lib/core/logging/hvac_log.dart` | Structured logs without credentials |
| `DemoCredentials` | `lib/core/config/demo_credentials.dart` | Login hints **development only** |

## Verification before go-live

1. `flutter test test/security_denial_test.dart test/rls_admin_gating_test.dart`
2. `../hvac_client/tool/verify_rls.ps1` on **target** Supabase project
3. [e2e-manual-checklist.md](e2e-manual-checklist.md) Scenario B (denials)
4. Supabase dashboard: enable leaked-password protection
5. Run `supabase/sql/production_cutover.sql` on production
6. Optional: `flutter test test/integration/staging_supabase_test.dart --dart-define=RUN_INTEGRATION_TESTS=true ...`

## Related docs

- `../hvac_client/docs/db/auth-and-rls.md` — role matrix + SQL
- `../hvac_client/docs/db/security-production.md` — production audit checklist
- `../hvac_client/docs/db/security-file-hardening.md` — storage + `audit_log` grants
- [e2e-security-tests.md](e2e-security-tests.md) — automated test layers
- [backups-and-migration.md](backups-and-migration.md) — environment isolation
