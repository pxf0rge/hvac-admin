# Manual E2E checklist (Phase 35)

Run on **staging** after migrations and demo seed are applied. Record pass/fail in `docs/e2e-security-tests.md`.

## Prerequisites

- Staging Supabase project with all migrations applied (`hvac_client/supabase/migrations/`).
- Demo users from shared auth seed (`diana@hvacpro.com`, `marcus@hvacpro.com`, `carlos@hvacpro.com`).
- Admin app built with staging dart-defines (see `docs/environments.md`).

```bash
flutter run \
  --dart-define=HVAC_ENV=staging \
  --dart-define=SUPABASE_URL=https://YOUR_STAGING_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
  --dart-define=SUPABASE_PROJECT_REF=YOUR_STAGING_REF
```

## Scenario A — CRM → job → dispatch assign

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | Owner (`diana@hvacpro.com`) | Sign in → Customers → Add customer | Customer appears in list |
| 2 | Owner | Customer detail → Add property | Property saved |
| 3 | Owner | Jobs → New job on that property | Job created, status unassigned |
| 4 | Owner | Dispatch → drag job to Carlos | Job in technician column; status assigned |
| 5 | Technician (`carlos@hvacpro.com`) | Field app → open job → complete workflow | Status advances (cross-app) |
| 6 | Owner | Property → Previous jobs | Job visible with notes/photos |

## Scenario B — Security denials (must fail closed)

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | Technician | Attempt admin office sign-in (`carlos@hvacpro.com`) | **Rejected** — not a management role |
| 2 | Office staff (`marcus@hvacpro.com`) | Dashboard | No revenue widgets; no Invoices nav |
| 3 | Office staff | Direct URL `/invoices` | Redirect to dashboard |
| 4 | Office staff | SQL/API: `select * from invoices` | **0 rows** (RLS) |
| 5 | Technician | Query random job UUID (not assigned) | **0 rows** |
| 6 | Postgres | Run `hvac_client/tool/verify_rls.ps1` | `ALL PASSED` |

## Scenario C — Financial + audit smoke (owner only)

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | Owner | Invoices → open seeded `INV-RLS-21` (if present) | Invoice detail loads |
| 2 | Owner | Reports → financial section | Revenue metrics visible |
| 2b | Owner | Reports → Export for accounting (date range) | CSV downloads / clipboard; empty range shows clear error |
| 2c | Office staff | Reports → Export for accounting | Hidden or blocked (no financial access) |
| 3 | Owner | Settings → Audit log | Login and settings events listed |
| 4 | Office staff | Settings → Audit log URL | Blocked / redirect |

## Scenario D — Wave 2 product smoke (owner)

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | Owner | Office Personnel → invite / role change | User listed; role persists |
| 2 | Owner | Settings → Language → Español | Sidebar/primary actions switch |
| 3 | Owner | GPS map → Both / Techs / Jobs | Layers filter markers |
| 4 | Owner | Customer preferred language ES → compose invoice template | Spanish template preview |
| 5 | Owner | Settings → Automated reminders toggles | Saved on company_settings |
| 6 | Owner | Job create/detail → assign truck | Truck shown on dispatch/detail |
| 7 | Owner + Tech | Team messages ↔ tech Messages | Thread updates both apps |
| 8 | Owner | Estimate/Invoice Send → open portal URL | Anonymous portal view loads |
| 9 | Owner | Invoice Pay online (if Stripe configured) | Checkout URL; no secrets in app |
| 10 | Owner | Reports → Export for accounting | CSV + audit `accounting.export` |

Full Persian booklet: [`../../docs/دفترچه-تست.md`](../../docs/دفترچه-تست.md) section Wave 2. Acceptance: [`../../phases/wave-2-acceptance.md`](../../phases/wave-2-acceptance.md).

## Sign-off

- [ ] Scenario A passed on staging build `________`
- [ ] Scenario B denials verified (UI + `verify_rls`)
- [ ] Scenario C passed (if financial seed present)
- [ ] Scenario D Wave 2 smoke (as prioritized by client)
- [ ] No secrets in browser console or `HvacLog` output
- [ ] CI green on merge commit
- [ ] Wave 2 acceptance reviewed (`phases/wave-2-acceptance.md`)

Automated coverage: `flutter test` (mocks) + optional `flutter test test/integration/staging_supabase_test.dart --dart-define=RUN_INTEGRATION_TESTS=true ...`.
