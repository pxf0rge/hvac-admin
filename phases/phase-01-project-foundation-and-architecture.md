# Phase 01 — Project Foundation + Architecture

## Goal
Establish folder structure, naming conventions, and architectural boundaries before feature work begins.

## Constraints
- Do not add feature screens yet.
- Do not duplicate Supabase migrations — reference `../hvac_client/supabase/`.
- Match patterns proven in `hvac_client` where applicable.

## What to do (execution checklist)
1. Create `lib/` structure:
   - `core/` (config, auth, controllers, enums, errors, routing)
   - `data/` (datasources, mappers, repositories, wiring)
   - `design_system/` (theme, colors, typography, breakpoints)
   - `features/` (one folder per module: dashboard, dispatch, crm, …)
   - `l10n/` (if needed later; admin UI English-first)
2. Add `analysis_options.yaml` aligned with `hvac_client` (flutter_lints).
3. Document target platforms: web (primary), Windows desktop, Android tablet optional.
4. Create `docs/architecture.md` describing layer boundaries and shared-backend strategy.
5. Add `.gitignore` entries for env files (`*.env`, `dart_defines.json`).

## Verification
1. `flutter analyze` passes on scaffold.
2. Folder structure documented and committed.
3. No business logic in `main.dart` beyond bootstrap.

## Stop condition
Project skeleton and architecture doc exist; ready for environments in Phase 02.
