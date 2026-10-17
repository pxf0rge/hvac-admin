# Phase 33 — Staging / Prod Databases + Backups

## Goal
Separate staging and production Supabase projects with backup and recovery procedures.

## Constraints
- Migrations applied from `../hvac_client/supabase/migrations/` — single source of truth.
- Admin and client apps use same env-specific Supabase URL per environment.
- Backup strategy documented before production launch.

## What to do (execution checklist)
1. Document staging vs production Supabase project setup.
2. Migration apply workflow: dev → staging → prod with checklist.
3. Configure Supabase automated backups (PITR if on Pro plan).
4. Document restore procedure and test on staging.
5. Seed data strategy: staging has test data; prod has none.
6. Admin `HVAC_ENV` mapping per deployment target.

## Verification
1. Staging admin app connects to staging Supabase only.
2. Production admin refuses staging credentials when `HVAC_ENV=production`.
3. Backup restore tested on staging clone.

## Stop condition
Environment separation and backup recovery documented and tested.
