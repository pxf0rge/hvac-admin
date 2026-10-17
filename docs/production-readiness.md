# Arctic HVAC Solutions Admin — Production readiness report (Phase 36)

**Date:** 2026-09-07 (Wave 2 acceptance refresh)  
**Scope:** Flutter admin app `hvac_admin` + shared Supabase backend in `../hvac_client/`  
**Wave 2:** See [`../phases/wave-2-acceptance.md`](../phases/wave-2-acceptance.md) — **partially accepted** (code shipped; ops gates remain).  
**Build verification (local):**

| Check | Result |
|-------|--------|
| `flutter analyze` | **PASS** (0 errors, 24 warnings, 71 info) |
| `flutter test` | **PASS** (248 passed, 5 skipped integration) |
| `flutter build web` (staging defines) | **PASS** → `build/web/` |
| `flutter build windows` (staging defines) | **PASS** → `build/windows/x64/runner/Release/hvac_admin.exe` |

---

## Verdict

### **NOT PRODUCTION READY** for customer go-live

The **admin codebase** is production-capable: live Supabase wiring for all domains, RLS-backed backend, CI/CD, security tests, boot guards, audit logging, and file hardening are in place. **Operational go-live** still requires a dedicated production Supabase project, provider secrets on edge functions, `verify_rls` on that project, manual E2E sign-off, and cross-app smoke (admin assign → technician field app).

Promote to **PRODUCTION READY** only when every item in [Go-live gates](#go-live-gates) is checked on the **target production project**.

---

## Final domain checklist

| Domain | Code / schema | Production wiring (`main.dart`) | Ops gate |
|--------|---------------|----------------------------------|----------|
| Auth (owner / admin / office staff) | ✅ | ✅ `SupabaseManagementAuthService` | Prod users; no demo seed |
| Technician login blocked | ✅ | ✅ `technicianNotAllowed` | Smoke |
| RLS + authorization | ✅ shared migrations | N/A (server) | `verify_rls` on prod |
| CRM (customers, properties) | ✅ | ✅ `SupabaseCustomerRepository` | Smoke on prod |
| Equipment + warranty | ✅ | ✅ via customer repo | Smoke on prod |
| Jobs core + workflow | ✅ | ✅ `SupabaseJobRepository` | Smoke on prod |
| Dispatch + assignments | ✅ | ✅ | Cross-app: tech sees job |
| Calendar | ✅ | ✅ | Smoke on prod |
| Technician directory | ✅ | ✅ `SupabaseTechnicianRepository` | Smoke on prod |
| Fleet | ✅ | ✅ `SupabaseFleetRepository` | Smoke on prod |
| GPS map (technician locations) | ✅ | ✅ `SupabaseTechnicianLocationRepository` | Realtime + location smoke |
| Realtime (office channel) | ✅ | ✅ `SupabaseRealtimeService` | Publication on prod |
| Document templates | ✅ | ✅ `SupabaseDocumentTemplateRepository` | Seed templates |
| Communication (outbound) | ✅ edge `send-message` | ✅ `SupabaseMessageSender` | Twilio/Resend secrets |
| Message history + webhooks UI | ✅ | ✅ `SupabaseCommunicationRepository` | `WEBHOOK_SHARED_SECRET` |
| Billing (estimates/invoices) | ✅ | ✅ `SupabaseBillingRepository` | Owner/admin only |
| Payments (Stripe Checkout) | ✅ edge functions | ✅ `SupabasePaymentProvider` | Stripe keys + webhook |
| Inventory | ✅ | ✅ `SupabaseInventoryRepository` | Smoke on prod |
| Maintenance agreements | ✅ | ✅ `SupabaseMaintenanceAgreementRepository` | Smoke on prod |
| Reports + KPIs | ✅ | ✅ `SupabaseReportsRepository` | Financial gate |
| Accounting CSV export | ✅ Reports UI | ✅ local CSV + audit | QB/Xero manual import |
| Office Personnel + invite/roles | ✅ | ✅ Edge `manage-office-user` | Deploy function on target |
| Admin EN/ES locale | ✅ | ✅ `LocaleController` | Secondary strings may remain EN |
| Customer preferred language | ✅ | ✅ CRM + templates | Twilio/Resend for live send |
| Automated reminders | ✅ edge `send-reminders` | ✅ Settings toggles | Cron + `REMINDER_CRON_SECRET` |
| Job ↔ truck binding | ✅ | ✅ fleet/job UI | — |
| Internal team messaging | ✅ | ✅ `/team-messages` | Realtime publication |
| Customer portal links | ✅ `/e|/i|/d` | ✅ token RPCs | `PORTAL_BASE_URL` + hosted web |
| Translate (job notes) | ✅ edge `translate-text` | ✅ admin widget | DeepL secret |
| Settings / company | ✅ | ✅ `SupabaseSettingsRepository` | Smoke on prod |
| Audit log viewer | ✅ | ✅ `SupabaseAuditLogRepository` | Owner/admin only |
| Global search + pagination | ✅ | ✅ `GlobalSearchService` | Role-filtered hits |
| Validation + errors | ✅ | ✅ `FailureMapper` | — |
| Security + file hardening | ✅ | ✅ `SecureMediaAccess`, CSP | `verify_rls` |
| Environments + backups | ✅ | ✅ `EnvironmentGuard` | PITR + cutover |
| CI/CD | ✅ | ✅ `.github/workflows/ci.yml` | GitHub secrets |
| E2E + security tests | ✅ | ✅ 248 unit/widget tests | Manual checklist |

---

## Completed (phases 01–36)

- Full admin UI: CRM, dispatch, calendar, GPS map, billing, inventory, reports, settings, search.
- All domain repositories wired to `Supabase*` when `HvacSupabase.initialize()` succeeds (`lib/main.dart`).
- `ProductionBootGuard` + `EnvironmentGuard` for staging/production builds.
- Role-based module guards (`office_staff` denied financial modules + audit log).
- CI: analyze, test, security gates, web + Windows staging artifacts; production deploy workflow.
- Documentation set under `hvac_admin/docs/` (this file + architecture, deployment, security, permissions, integrations).

---

## Remaining (operational — not code blockers)

1. **Provision production Supabase** — separate from dev/staging ref; apply all migrations from `hvac_client/supabase/migrations/`.
2. **Run `supabase/sql/production_cutover.sql`** — lock environment, remove demo users.
3. **Configure edge secrets** — Stripe, Twilio, Resend, webhook HMAC (see `docs/integrations.md`).
4. **Run `../hvac_client/tool/verify_rls.ps1`** against production `DATABASE_URL`.
5. **Manual E2E** — `docs/e2e-manual-checklist.md` on staging, then prod smoke.
6. **Cross-app verification** — owner assigns job in admin → Carlos sees it in `hvac_client`.
7. **Deploy admin web** — static hosting with production dart-defines; distribute Windows exe if needed.
8. **Enable Supabase Auth** leaked-password protection (dashboard).

---

## Intentional mocks (not used in production boot)

| Symbol | When |
|--------|------|
| `RepositoryWiring._createMockBundle()` | `HvacAdminApp(supabase: null)` widget tests only |
| `MockPaymentProvider` | Widget tests when payments not injected |
| `MockMessageSender` | Widget tests |
| `NoopRealtimeService` | Widget tests |
| `LocalAdminMediaStorage` | Mock bundle only |
| `InMemoryAuditLog` | Mock bundle audit writer |

Production boot path (`lib/main.dart`): always `RepositoryWiring.create(client: supabase)` with live client — **no mocks**.

---

## Known product gaps (non-blocking for backend go-live)

| Item | Notes |
|------|-------|
| Web hosting URL | CI uploads artifacts; Firebase/Vercel/Supabase Hosting TBD per org |
| Provider delivery | SMS/email/payments depend on Twilio/Resend/Stripe configuration |
| Windows code signing | CI builds unsigned exe; Authenticode for distribution is ops |
| `flutter analyze` warnings | Cleanup optional |
| Wave 2 ops | Reminder cron, portal base URL, Stripe keys, DeepL — see [`../phases/wave-2-acceptance.md`](../phases/wave-2-acceptance.md) |
| QB/Xero live API | ✅ Xero connector shipped (Phase 24): Edge OAuth + one-way invoice sync; Settings card. CSV remains the offline fallback; QuickBooks Online still CSV-only |
| Per-user notification prefs | ✅ done (Phase 21): admin Settings + tech Profile, RLS-guarded, safe defaults, critical job-assign in-app never muted |
| Invoice tax | ✅ done (Phase 22): invoice-level `tax_rate_pct`; totals in UI/portal/CSV/checkout. Estimates mirror later if requested |

---

## Go-live gates

Check all before declaring **PRODUCTION READY**:

- [ ] Production Supabase project created; **not** dev ref `zzmhomajzyqoibgqiymg`
- [ ] All migrations applied; `production_cutover.sql` executed
- [ ] `verify_rls` + `security_audit_checks` **PASSED** on production
- [ ] Edge functions deployed; provider secrets set
- [ ] Admin `flutter build web` + `flutter build windows` with `HVAC_ENV=production` + prod dart-defines
- [ ] Technician app built against **same** production Supabase URL
- [ ] Manual E2E checklist signed off (`docs/e2e-manual-checklist.md`)
- [ ] Cross-app dispatch assign verified
- [ ] Backup/PITR enabled (`docs/backups-and-migration.md`)
- [ ] No demo passwords in production Auth users
- [ ] GitHub `production` environment approval configured for deploy workflow

---

## Documentation map

| Doc | Topic |
|-----|-------|
| [architecture.md](architecture.md) | Layers, boot, routing, modules |
| [deployment.md](deployment.md) | Web + Windows builds, dart-defines |
| [security.md](security.md) | Trust boundaries, verification |
| [permissions.md](permissions.md) | Role × module matrix |
| [integrations.md](integrations.md) | Messaging, payments, edge functions |
| [environments.md](environments.md) | `HVAC_ENV`, project refs |
| [ci-cd.md](ci-cd.md) | GitHub Actions pipeline |
| [backups-and-migration.md](backups-and-migration.md) | DB workflow, restore drill |
| [e2e-security-tests.md](e2e-security-tests.md) | Automated test layers |
| [e2e-manual-checklist.md](e2e-manual-checklist.md) | Staging smoke scenarios |
| [payments.md](payments.md) | Stripe Checkout flow |
| [accounting-export.md](accounting-export.md) | Accounting CSV + QB/Xero mapping |
| [portal.md](portal.md) | Customer magic links |
| [`../phases/wave-2-acceptance.md`](../phases/wave-2-acceptance.md) | Wave 2 acceptance + deferred list |
| `../hvac_client/docs/db/*` | Canonical database docs |

---

## Sign-off template

| Role | Name | Date | Notes |
|------|------|------|-------|
| Engineering | | | CI green, docs complete, builds pass |
| Security | | | `verify_rls` on prod |
| Operations | | | Backups + cutover + hosting |
| Product | | | E2E + cross-app checklist |
