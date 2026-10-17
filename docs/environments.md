# HVAC Admin — environments and secrets

Admin app (`hvac_admin`) and technician app (`hvac_client`) share **one Supabase backend per environment**. Schema and migrations live in `../hvac_client/supabase/`.

## Dart defines

| Define | Required | Description |
|--------|----------|-------------|
| `HVAC_ENV` | No (default `development`) | `development` \| `staging` \| `production` |
| `SUPABASE_URL` | Staging + production | `https://<project-ref>.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | Staging + production | Supabase **anon / publishable** key only |
| `SUPABASE_PROJECT_REF` | Staging + production (recommended) | Must match host in `SUPABASE_URL` |
| `STAGING_PROJECT_REF` | CI (optional) | Blocks production builds from staging URL |
| `PRODUCTION_PROJECT_REF` | CI (optional) | Blocks staging builds from production URL |

**Never** put the service-role key, Stripe secret, Twilio auth token, or Resend API key in Flutter.

## Environment matrix

| Environment | `HVAC_ENV` | Supabase project | Demo login hints |
|-------------|------------|------------------|------------------|
| Development | `development` | Shared dev project (embedded defaults) | Shown in UI |
| Staging | `staging` | Dedicated staging project | Allowed for QA |
| Production | `production` | Dedicated production project | **Hidden** |

See also: `docs/backups-and-migration.md` (migration workflow, backups, restore drill) and `../hvac_client/docs/db/environments.md`.

## Local development (no dart-defines)

```bash
cd hvac_admin
flutter run -d chrome
```

Uses embedded dev Supabase URL + publishable key (same project as `hvac_client` local runs).

## Staging

```bash
flutter run -d chrome \
  --dart-define=HVAC_ENV=staging \
  --dart-define=SUPABASE_URL=https://YOUR_STAGING_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

## Production build

```bash
flutter build web --release \
  --dart-define=HVAC_ENV=production \
  --dart-define=SUPABASE_URL=https://YOUR_PROD_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

Boot **fails fast** if staging/production is missing URL or key, URL points at the dev project ref (`zzmhomajzyqoibgqiymg`), or project refs disagree with `HVAC_ENV` (see `EnvironmentGuard`).

## `dart_defines.json` (local only)

Copy `dart_defines.example.json` → `dart_defines.json` (gitignored). Example VS Code launch:

```json
"toolArgs": [
  "--dart-define-from-file=dart_defines.json"
]
```

## Shared backend checklist

- [ ] Admin and client use the **same** `SUPABASE_URL` for each environment
- [ ] Staging URL ≠ production URL ≠ dev URL
- [ ] Migrations applied from `hvac_client/supabase/migrations/`
- [ ] RLS verified with `../hvac_client/tool/verify_rls.sh`

## Files

| File | Role |
|------|------|
| `lib/core/config/app_environment.dart` | `HVAC_ENV` parser |
| `lib/core/config/supabase_config.dart` | URL + publishable key |
| `lib/core/config/environment_guard.dart` | Blocks wrong project per `HVAC_ENV` |
| `lib/core/config/production_boot_guard.dart` | Fail-fast boot validation |
| `lib/core/config/demo_credentials.dart` | Dev-only login hints |
| `lib/data/datasources/hvac_supabase.dart` | Supabase.initialize |
| `docs/payments.md` | Stripe edge functions + webhook setup (no secrets in Flutter) |
