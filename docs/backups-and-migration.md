# Staging / production databases, migrations, and backups

Admin (`hvac_admin`) and technician (`hvac_client`) apps share **one Supabase project per environment**. Schema, migrations, RLS, and backup runbooks live in `../hvac_client/`.

## Project matrix

| Environment | `HVAC_ENV` | Supabase project | Demo users | Seed SQL |
|-------------|------------|------------------|------------|----------|
| Development | `development` | Shared dev (`zzmhomajzyqoibgqiymg`) | UI hints | Allowed |
| Staging | `staging` | **Dedicated staging** | QA accounts | `deployment_config.environment = staging` |
| Production | `production` | **Dedicated production** | **Hidden** | Locked — no demo seed |

**Rule:** staging URL ≠ production URL ≠ dev URL.

## `HVAC_ENV` + dart-defines per deployment

| Target | Required defines |
|--------|------------------|
| Local dev | *(none)* — embedded dev URL |
| Staging web/desktop | `HVAC_ENV=staging`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_PROJECT_REF` |
| Production web/desktop | `HVAC_ENV=production`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_PROJECT_REF` |

**Recommended CI defines** (cross-environment guard):

| Define | Staging pipeline | Production pipeline |
|--------|------------------|---------------------|
| `STAGING_PROJECT_REF` | staging ref | staging ref |
| `PRODUCTION_PROJECT_REF` | production ref | production ref |

`EnvironmentGuard` rejects:

- staging/production → dev project ref
- `HVAC_ENV=production` + staging URL/ref
- `HVAC_ENV=staging` + production URL/ref
- `SUPABASE_URL` ref ≠ `SUPABASE_PROJECT_REF`

See `dart_defines.example.json` and `docs/environments.md`.

### Staging run

```bash
cd hvac_admin
flutter run -d chrome --dart-define-from-file=dart_defines.json
```

### Production build

```bash
flutter build web --release \
  --dart-define=HVAC_ENV=production \
  --dart-define=SUPABASE_URL=https://YOUR_PROD_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
  --dart-define=SUPABASE_PROJECT_REF=YOUR_PROD_REF \
  --dart-define=STAGING_PROJECT_REF=YOUR_STAGING_REF \
  --dart-define=PRODUCTION_PROJECT_REF=YOUR_PROD_REF
```

## Migration workflow (single source of truth)

All SQL lives in `../hvac_client/supabase/migrations/`. **Do not** add migrations under `hvac_admin/`.

### Dev → staging → production checklist

1. **Develop** — apply locally or to dev project:
   ```bash
   cd ../hvac_client
   supabase db push
   flutter test
   ```
2. **Staging** — link staging project and push:
   ```bash
   supabase link --project-ref YOUR_STAGING_REF
   supabase db push
   ./tool/verify_rls.sh
   ```
3. **Smoke admin + client** on staging (same `SUPABASE_URL` for both apps).
4. **Production** — link prod, push, then cutover:
   ```bash
   supabase link --project-ref YOUR_PROD_REF
   supabase db push
   psql "$PROD_DATABASE_URL" -f supabase/sql/production_cutover.sql
   ./tool/verify_rls.sh
   ```
5. **Deploy** admin + client with production dart-defines.

### Post-migration verification

```bash
cd ../hvac_client
psql "$DATABASE_URL" -f supabase/sql/security_audit_checks.sql
psql "$DATABASE_URL" -f supabase/sql/rls_authorization_tests.sql
```

Expected: `RLS structural audit: PASSED`.

## Seed data strategy

| Environment | Demo users (`@hvacpro.com`) | `app.deployment_config` |
|-------------|----------------------------|-------------------------|
| Development | Yes | `staging` (default) |
| Staging | Yes — QA smoke tests | `staging` |
| Production | **No** — removed by `production_cutover.sql` | `production` |

Migration `20260829270000_hvac_environment_isolation.sql` blocks `app.upsert_demo_user` when environment is `production`.

## Backups and PITR

Configure in Supabase dashboard per project:

| Project | Daily backups | PITR | Target RPO |
|---------|---------------|------|------------|
| Staging | Recommended (Pro+) | Optional | ≤ 24 h |
| Production | **Required** | **Enable** | ≤ 15 min |

Full runbook: `../hvac_client/docs/backup-and-recovery.md`

### Quarterly staging restore drill

1. Restore backup to a **throwaway** Supabase project (not production).
2. Run `security_audit_checks.sql` + `rls_authorization_tests.sql`.
3. Point **admin** staging build at restored URL:
   ```bash
   flutter run -d chrome \
     --dart-define=HVAC_ENV=staging \
     --dart-define=SUPABASE_URL=https://RESTORED_REF.supabase.co \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
     --dart-define=SUPABASE_PROJECT_REF=RESTORED_REF
   ```
4. Smoke: owner login, dispatch board, settings, one signed storage URL.
5. Tear down throwaway project; log drill date in ops notes.

## Related docs

| Document | Location |
|----------|----------|
| Dart defines (quick ref) | `docs/environments.md` |
| DB environment isolation | `../hvac_client/docs/db/environments.md` |
| Backup / restore runbook | `../hvac_client/docs/backup-and-recovery.md` |
| RLS verification | `../hvac_client/tool/verify_rls.sh` |
| Production cutover SQL | `../hvac_client/supabase/sql/production_cutover.sql` |

## Code references

| File | Role |
|------|------|
| `lib/core/config/environment_guard.dart` | Project ref + cross-env validation |
| `lib/core/config/supabase_config.dart` | URL + publishable key |
| `lib/core/config/production_boot_guard.dart` | No mock repos in staging/prod |
| `lib/data/datasources/hvac_supabase.dart` | Boot-time guard |
