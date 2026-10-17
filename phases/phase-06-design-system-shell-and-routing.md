# Phase 06 — Design System + Responsive Shell + Routing

## Goal
Build the admin app chrome: sidebar navigation, app bar, responsive layout, and full route map.

## Constraints
- Desktop-first (sidebar always visible ≥ breakpoint); drawer on narrow screens.
- Do not implement feature data yet — placeholder pages are OK.
- Reuse visual language from `hvac_client` management shell where sensible.

## What to do (execution checklist)
1. Create `design_system/`: colors, typography, spacing, breakpoints, shared widgets (cards, chips, data tables).
2. Build `AdminShell` with sidebar, app bar, sign-out, global search entry point.
3. Configure `GoRouter` with all module routes and nested detail routes (e.g. `/customers/:id`).
4. Add loading / empty / error state widgets for reuse.
5. Ensure web and Windows window resizing behaves correctly.

## Verification
1. All module routes navigable from sidebar.
2. Layout switches sidebar ↔ drawer at breakpoint.
3. `flutter run -d chrome` and `flutter run -d windows` both render shell.

## Stop condition
Navigation shell complete; ready for repository wiring in Phase 07.
