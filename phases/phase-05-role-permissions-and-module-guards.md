# Phase 05 — Role Permissions + Module Guards

## Goal
Enforce role-based module visibility in routing and navigation — not just hidden buttons.

## Constraints
- Mirror backend RLS intent: `office_staff` cannot access financial modules.
- `owner` and `admin` have full access.
- Guards must run on route navigation, not only sidebar filtering.
- Permission matrix must match `../hvac_client/docs/db/architecture.md`.

## What to do (execution checklist)
1. Define `AdminModule` enum (dashboard, dispatch, calendar, customers, properties, jobs, technicians, fleet, equipment, maintenance, documents, communication, inventory, estimates, invoices, reports, settings).
2. Mark financial modules: estimates, invoices, reports.
3. Create `PermissionService` / `AuthController.canOpen(module)` based on `profiles.role`.
4. Add `GoRouter` redirect guards: unauthorized route → access-denied or dashboard.
5. Document permission matrix in `docs/permissions.md`.

## Verification
1. `office_staff` cannot navigate to `/invoices` even via direct URL.
2. `owner`/`admin` can access all modules.
3. Sidebar only shows permitted modules.

## Stop condition
Permission model enforced in router and navigation; ready for UI shell in Phase 06.
