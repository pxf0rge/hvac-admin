# Phase 02 — Environments + Secrets Hygiene

## Goal
Configure dev / staging / production Supabase endpoints without leaking secrets into source control.

## Constraints
- Only **anon** (publishable) Supabase key in the client; never service-role key.
- Same Supabase project(s) as `hvac_client` — admin and technician apps share one backend.
- Demo credentials disabled when `HVAC_ENV=production`.

## What to do (execution checklist)
1. Add `lib/core/config/` with environment loader (`HVAC_ENV`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` via `--dart-define` or `.env` excluded from git).
2. Create `docs/environments.md` listing required defines per environment.
3. Add production boot guard: refuse to start if required keys missing in production mode.
4. Document how admin and client apps point to the same Supabase project.
5. Add example `dart_defines.example.json` (no real secrets).

## Verification
1. App boots in dev with staging credentials.
2. Production mode fails fast without valid defines.
3. No secrets committed to git.

## Stop condition
Environment strategy is documented and boot guard is in place.
