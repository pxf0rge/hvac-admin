# Phase 03 — Architecture Wiring (Controller → Repository → Datasource)

## Goal
Set up dependency injection, repository interfaces, and Supabase client bootstrap before any feature UI.

## Constraints
- Widgets never import `supabase_flutter` directly.
- Repository interfaces are stable contracts; Supabase implementations live in `data/repositories/`.
- Tests inject mocks via constructor/`Provider` overrides.

## What to do (execution checklist)
1. Add dependencies: `provider`, `go_router`, `supabase_flutter`, `intl`.
2. Create `HvacSupabase.initialize()` datasource wrapper (mirror `hvac_client` pattern).
3. Create `RepositoryWiring` factory: Supabase repos when client present, mocks for tests.
4. Define base `HvacFailure` error type and result handling conventions.
5. Wire `main.dart` with `MultiProvider` skeleton (no feature controllers yet).
6. Add `test/` harness with `supabase == null` mock mode.

## Verification
1. App launches to a placeholder shell with Supabase connected (or mock in tests).
2. `flutter test` passes with mock wiring.
3. No direct Supabase calls outside `data/` layer.

## Stop condition
Layer boundaries enforced; ready for auth in Phase 04.
