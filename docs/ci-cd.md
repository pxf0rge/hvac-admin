# CI/CD (Phase 34)

GitHub Actions workflows:

| File | Trigger | Purpose |
|------|---------|---------|
| `.github/workflows/ci.yml` | PR + push to `main`/`master` | Analyze, test, staging builds, auto staging deploy |
| `.github/workflows/deploy-production.yml` | Manual (`workflow_dispatch`) | Production builds with approval gate |

## Pipeline jobs (`ci.yml`)

| Job | Gate | Output |
|-----|------|--------|
| `analyze` | `flutter analyze` must pass | — |
| `test` | `flutter test` + security/config gates | — |
| `build-web` | staging web compile | Artifact `web-staging-<sha>/` |
| `build-windows` | staging Windows compile | Artifact `windows-staging-<sha>/` |
| `deploy-staging` | push to `main` only | `web-staging-latest` + optional hook deploy |

PRs and pushes to `main`/`master` run the full gate. In-progress runs are cancelled when a newer commit is pushed (`concurrency`).

## Production deploy (`deploy-production.yml`)

1. GitHub → **Actions** → **Deploy production** → **Run workflow**.
2. Enter the `pubspec.yaml` version (e.g. `1.0.0+1`) — the workflow fails if it does not match.
3. The `production` environment must be approved (configure required reviewers under **Settings → Environments**).
4. Downloads `web-production-<version>` and `windows-production-<version>` artifacts after approval.

## Secrets (GitHub repository settings)

Never commit these values. GitHub masks secret values in logs.

### Staging builds (`build-web`, `build-windows`)

| Secret | Required | Purpose |
|--------|----------|---------|
| `STAGING_SUPABASE_URL` | No | Falls back to `https://example.supabase.co` |
| `STAGING_SUPABASE_PUBLISHABLE_KEY` | No | Falls back to `public-ci-placeholder` |
| `STAGING_PROJECT_REF` | No | Cross-env guard; falls back to `example` in CI |
| `PRODUCTION_PROJECT_REF` | No | Blocks staging builds from production URL |
| `STAGING_WEB_DEPLOY_HOOK` | No | POST URL for auto-deploy on merge to `main` |

Configure staging Supabase secrets for CI builds that target your real staging project.

### Production deploy (`deploy-production.yml`)

| Secret | Required | Purpose |
|--------|----------|---------|
| `PRODUCTION_SUPABASE_URL` | Yes | Production Supabase URL |
| `PRODUCTION_SUPABASE_PUBLISHABLE_KEY` | Yes | Production publishable key |
| `PRODUCTION_PROJECT_REF` | Recommended | Must match production URL host ref |
| `STAGING_PROJECT_REF` | Recommended | Blocks production from staging URL |
| `PRODUCTION_WEB_DEPLOY_HOOK` | No | POST URL after production web build |

## Version bump strategy

`pubspec.yaml` uses `version: MAJOR.MINOR.PATCH+BUILD` (e.g. `1.0.0+1`).

| Change | Bump |
|--------|------|
| Bug fix / patch release | `+BUILD` only (`1.0.0+2`) |
| New features (backward compatible) | `MINOR` + reset build (`1.1.0+1`) |
| Breaking changes | `MAJOR` + reset (`2.0.0+1`) |

Before production deploy:

1. Bump `version` in `pubspec.yaml`.
2. Commit and merge to `main` with green CI.
3. Tag: `git tag v1.0.0+1 && git push origin v1.0.0+1`
4. Run **Deploy production** with matching `confirm_version`.

## Downloading artifacts

1. Open the workflow run on GitHub → **Artifacts**.
2. Download `web-staging-<sha>`, `windows-staging-<sha>`, or `web-staging-latest`.
3. Web: unzip and serve with `npx serve .` or upload to static hosting (Firebase, Vercel, Supabase Hosting).
4. Windows: run `hvac_admin.exe` from the Release folder (all DLLs must stay alongside the exe).

## Local CI reproduction

```bash
flutter analyze
flutter test
flutter test test/security_denial_test.dart test/storage_security_test.dart \
  test/rls_migration_contract_test.dart test/environment_project_ref_test.dart \
  test/production_boot_test.dart
flutter test test/config_guard_test.dart --dart-define=HVAC_ENV=staging
flutter test test/config_guard_test.dart --dart-define=HVAC_ENV=production

flutter build web --no-tree-shake-icons \
  --dart-define=HVAC_ENV=staging \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=public-ci-placeholder \
  --dart-define=SUPABASE_PROJECT_REF=example

flutter build windows --release \
  --dart-define=HVAC_ENV=staging \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=public-ci-placeholder \
  --dart-define=SUPABASE_PROJECT_REF=example
```

## Release checklist (production)

1. Bump `pubspec.yaml` version.
2. Merge to `main` with green CI.
3. Tag release aligned with `pubspec.yaml`.
4. Run **Deploy production** workflow; approve `production` environment.
5. Download artifacts or rely on deploy hooks.
6. Smoke-test staging URL, then production (see `docs/backups-and-migration.md`).

See `docs/environments.md` for dart-define matrix and `docs/backups-and-migration.md` for database migration workflow.
