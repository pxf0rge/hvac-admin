# HVAC Admin — Deployment (web + Windows)

Build-time configuration uses Flutter **dart-define** values. Copy `dart_defines.example.json` for local runs; never commit real secrets.

**Go-live checklist:** [production-readiness.md](production-readiness.md)  
**Environments:** [environments.md](environments.md) · **CI:** [ci-cd.md](ci-cd.md)

## Target platforms

| Platform | Command | Output |
|----------|---------|--------|
| **Web** (primary) | `flutter build web` | `build/web/` — static hosting |
| **Windows** (secondary) | `flutter build windows --release` | `build/windows/x64/runner/Release/hvac_admin.exe` |

Admin and technician apps share one Supabase project **per environment** but deploy independently.

## Dart-define reference

| Define | Required | Client-safe? | Notes |
|--------|----------|--------------|-------|
| `HVAC_ENV` | No (default `development`) | Yes | `development` \| `staging` \| `production` |
| `SUPABASE_URL` | Staging + production | Yes | `https://<ref>.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | Staging + production | Yes | Publishable / anon key only |
| `SUPABASE_PROJECT_REF` | Recommended | Yes | Must match URL host ref |
| `STAGING_PROJECT_REF` | CI (optional) | Yes | Cross-env guard |
| `PRODUCTION_PROJECT_REF` | CI (optional) | Yes | Cross-env guard |

### Never put in Flutter

- `SUPABASE_SERVICE_ROLE_KEY`
- `WEBHOOK_SHARED_SECRET`, Stripe/Twilio/Resend secrets

See [integrations.md](integrations.md) and `../hvac_client/docs/db/security-production.md`.

## Local development

```bash
cd hvac_admin
flutter pub get
flutter run -d chrome
```

No dart-defines required — embedded dev Supabase project (same as `hvac_client` local runs).

## Staging build

```bash
flutter build web --no-tree-shake-icons \
  --dart-define=HVAC_ENV=staging \
  --dart-define=SUPABASE_URL=https://YOUR_STAGING_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
  --dart-define=SUPABASE_PROJECT_REF=YOUR_STAGING_REF

flutter build windows --release \
  --dart-define=HVAC_ENV=staging \
  --dart-define=SUPABASE_URL=https://YOUR_STAGING_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
  --dart-define=SUPABASE_PROJECT_REF=YOUR_STAGING_REF
```

Serve web locally after build:

```bash
npx serve build/web
```

## Production build

```bash
flutter build web --release --no-tree-shake-icons \
  --dart-define=HVAC_ENV=production \
  --dart-define=SUPABASE_URL=https://YOUR_PROD_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
  --dart-define=SUPABASE_PROJECT_REF=YOUR_PROD_REF \
  --dart-define=STAGING_PROJECT_REF=YOUR_STAGING_REF \
  --dart-define=PRODUCTION_PROJECT_REF=YOUR_PROD_REF

flutter build windows --release \
  --dart-define=HVAC_ENV=production \
  --dart-define=SUPABASE_URL=https://YOUR_PROD_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
  --dart-define=SUPABASE_PROJECT_REF=YOUR_PROD_REF \
  --dart-define=PRODUCTION_PROJECT_REF=YOUR_PROD_REF
```

Boot throws `StateError` if URL/key missing or project ref mismatches `HVAC_ENV`.

## Web hosting

Deploy `build/web/` to static hosting (Firebase Hosting, Vercel, Supabase Storage + CDN, Azure Static Web Apps, etc.).

- Configure SPA fallback to `index.html` for `go_router` deep links.
- CSP is set in `web/index.html` — allow your Supabase host in `connect-src`.
- Optional CI hook: `STAGING_WEB_DEPLOY_HOOK` / `PRODUCTION_WEB_DEPLOY_HOOK` (see [ci-cd.md](ci-cd.md)).

## Windows distribution

1. Zip entire `build/windows/x64/runner/Release/` folder (exe + DLLs must stay together).
2. For production, sign with Authenticode (ops — not in CI by default).
3. Distribute via MDM, shared drive, or installer (Inno Setup / MSIX — optional).

## CI (GitHub Actions)

Pipeline: `.github/workflows/ci.yml`

| Job | Output |
|-----|--------|
| `build-web` | Artifact `web-staging-<sha>/` |
| `build-windows` | Artifact `windows-staging-<sha>/` |
| `deploy-production` | Manual workflow with `production` environment approval |

See [ci-cd.md](ci-cd.md) for secrets and version bump strategy.

## Release checklist

1. CI green on `main`.
2. Bump `version` in `pubspec.yaml`.
3. Run **Deploy production** workflow or build locally with production defines.
4. Run `verify_rls` + [e2e-manual-checklist.md](e2e-manual-checklist.md) on staging.
5. Deploy web; distribute Windows if needed.
6. Verify technician app (`hvac_client`) against same production Supabase URL.
7. Cross-app smoke: admin dispatch assign → technician receives job.

## Verify config guards

```bash
flutter test test/config_guard_test.dart --dart-define=HVAC_ENV=staging
flutter test test/config_guard_test.dart --dart-define=HVAC_ENV=production
```

## Secrets hygiene

- [ ] `dart_defines.json` gitignored; only `dart_defines.example.json` committed
- [ ] Staging ≠ production Supabase projects
- [ ] Production ran `production_cutover.sql`
- [ ] PITR enabled ([backups-and-migration.md](backups-and-migration.md))
- [ ] No service-role keys in `lib/` or committed JSON
