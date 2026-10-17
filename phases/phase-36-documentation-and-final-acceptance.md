# Phase 36 — Documentation + Final Acceptance

## Goal
Ship complete docs and an honest production-readiness verdict for the admin app.

## Constraints
- Do not claim PRODUCTION READY if secrets, RLS, or real repos are unfinished.
- Prefer updating existing `../hvac_client/docs/db/*` for backend docs; add admin-specific docs in `hvac_admin/docs/`.
- Admin and client apps must be deployable independently but share one backend.

## What to do (execution checklist)
1. Create/update in `hvac_admin/docs/`:
   - `production-readiness.md`
   - `architecture.md`
   - `deployment.md` (web + Windows)
   - `security.md`
   - `permissions.md`
   - `integrations.md`
2. Final checklist: auth, permissions, CRM, jobs, dispatch, calendar, GPS map, realtime, documents, communication, billing, payments, inventory, maintenance, reports, settings, search, backups, CI.
3. Run `flutter analyze`, `flutter test`, `flutter build web`, `flutter build windows`.
4. Cross-app verification: admin dispatch assign → technician app receives job.
5. Write final report: Completed / Remaining / Mocks / Security / Deployment / Verdict.

## Verification
1. Docs match actual wiring in `main.dart`.
2. Analyze + tests + builds pass.
3. Verdict is either `PRODUCTION READY` or `NOT PRODUCTION READY` with exact blockers.
4. Owner can operate business from admin app with technician app in field.

## Stop condition
Documentation and acceptance report are complete and truthful.
