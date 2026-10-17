# Phase 07 — Domain Mappers + Repository Wiring

## Goal
Create shared row↔model mapping and wire `main.dart` to swap Mock → Supabase without UI rewrites.

## Constraints
- Keep repository interfaces stable; extend only when required.
- Mappers must use UUID primary keys; human numbers (`JOB-10482`) are display fields.
- Align Flutter enums with SQL enums (`job_status`, `invoice_status`, `app_role`, …).
- Reference `../hvac_client/lib/data/mappers/` as the canonical mapping guide.

## What to do (execution checklist)
1. Add mapper helpers for: customers, properties, equipment, jobs, technicians, billing, inventory, messages.
2. Define repository interfaces for each domain area.
3. Implement `Supabase*` repositories and `Mock*` counterparts for tests.
4. Wire `RepositoryWiring.create(client)` in `main.dart`.
5. Add mapper unit tests with sample JSON rows from migrations/seeds.

## Verification
1. Mapper unit tests round-trip sample rows.
2. App runs with mock when `supabase == null` (tests).
3. Enum values match Postgres enums documented in `../hvac_client/docs/db/`.

## Stop condition
Mapper layer + wiring hooks ready for feature implementation in Phases 08+.
