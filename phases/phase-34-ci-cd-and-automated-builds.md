# Phase 34 — CI/CD + Automated Builds

## Goal
Automated analyze, test, and build pipeline for web and Windows releases.

## Constraints
- CI secrets (Supabase staging keys) in CI vault, not in repo.
- Build artifacts: web (static hosting) and Windows installer/exe.
- Same quality gates as `hvac_client`.

## What to do (execution checklist)
1. GitHub Actions (or equivalent) workflow: `flutter analyze`, `flutter test`, `flutter build web`, `flutter build windows`.
2. PR checks must pass before merge.
3. Staging deploy on merge to `main` (web hosting TBD: Firebase, Vercel, Supabase Hosting).
4. Production deploy manual approval gate.
5. Version bump strategy (`pubspec.yaml` version + build number).

## Verification
1. CI passes on clean checkout.
2. Web build artifact deploys to staging URL.
3. Windows build produces runnable exe.

## Stop condition
CI/CD pipeline builds and deploys admin app automatically.
