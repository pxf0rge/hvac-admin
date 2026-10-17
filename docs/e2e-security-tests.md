# E2E + security tests (Phase 35)

Automated and manual coverage for critical admin paths and RLS denial cases.

## Test layers

| Layer | Location | Runs in CI | Database |
|-------|----------|------------|----------|
| Security denials | `test/security_denial_test.dart` | Yes | No |
| Admin UI financial gate | `test/rls_admin_gating_test.dart` | Yes | No |
| Route guards | `test/admin_route_guard_test.dart` | Yes | No |
| Migration/SQL contract | `test/rls_migration_contract_test.dart` | Yes | No |
| Supabase repo contracts | `test/supabase_repository_contract_test.dart` | Yes | No |
| Widget flows (mocks) | `test/widget_test.dart` | Yes | No |
| Live Supabase integration | `test/integration/staging_supabase_test.dart` | Optional | Yes |
| Server RLS matrix | `hvac_client/supabase/sql/rls_authorization_tests.sql` | Manual / `tool/verify_rls.*` | Yes |
| Manual E2E | `docs/e2e-manual-checklist.md` | Release gate | Staging |

## Critical denial paths (must stay green)

1. **Office staff financial access → DENIED**
   - Client: `canAccessAdminModule(officeStaff, invoices|estimates|reports)` → `false`
   - Server: `rls_authorization_tests.sql` — office_staff `invoices` count = 0
   - Integration (opt-in): `staging_supabase_test.dart` — empty selects

2. **Technician management login → DENIED**
   - Mock: `management_auth_controller_test.dart` — `technicianNotAllowed`
   - Source: `supabase_management_auth_service.dart` — `!role.isManagement` signs out
   - Integration (opt-in): technician credentials rejected at admin login

3. **Technician guessed job UUID → DENIED**
   - Fixture: `RlsTestFixtures.guessedJobUuid` in `test/integration/integration_config.dart`
   - Server: `rls_authorization_tests.sql` — count = 0 for technician

4. **RLS errors → user-safe UnauthorizedFailure**
   - `FailureMapper` maps Postgrest `42501` and RLS policy text

## Run automated suite (local)

```bash
# CI-equivalent (no database)
flutter test test/security_denial_test.dart test/rls_admin_gating_test.dart \
  test/admin_route_guard_test.dart test/supabase_repository_contract_test.dart

# Full unit + widget
flutter test

# Optional live staging/dev (requires seeded project; never production)
flutter test test/integration/staging_supabase_test.dart \
  --dart-define=RUN_INTEGRATION_TESTS=true \
  --dart-define=HVAC_ENV=staging \
  --dart-define=SUPABASE_URL=https://YOUR_STAGING_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

## Run server RLS suite

```powershell
$env:DATABASE_URL = "postgresql://..."
cd ..\hvac_client
./tool/verify_rls.ps1
```

Expected: `RLS authorization tests: ALL PASSED`.

## Manual E2E

See [e2e-manual-checklist.md](e2e-manual-checklist.md) before staging/production promotion.

## Regression protocol

1. PR: `flutter test` must pass (includes security + gating tests).
2. Before staging release: run `verify_rls` + manual checklist Scenario B.
3. If a denial test fails, **fix RLS or client gate** — do not weaken assertions.

## Mock E2E flow (widget test)

`widget_test.dart` includes **owner E2E mock**: create customer → property → job → dispatch assign (no database).

## Readiness note (Phase 36)

Record results in the final acceptance doc:

- CI commit SHA
- `verify_rls` output date
- Manual checklist sign-off name/date
- Optional integration test run against staging
