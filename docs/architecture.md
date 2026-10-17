# Arctic HVAC Solutions — Admin architecture

Flutter admin/office app for **Owner**, **Admin**, and **Office Staff**. Shares one Supabase backend with the technician field app (`../hvac_client/`).

## Target platforms

| Priority | Platform | Notes |
|----------|----------|-------|
| **Primary** | **Web** | Browser on office desktop — matches client requirement for cloud + desktop access |
| Secondary | Windows desktop | Optional native build from same codebase (`flutter build windows`) |
| Optional | Android tablet | Responsive layout; not the primary admin experience |

Technician workflows stay in `hvac_client` (mobile-first). This project does not duplicate technician UI.

## Layers

```
UI (features/) → Controllers (core/controllers/) → Repositories (data/repositories/)
    → Datasources / Supabase client (data/datasources/)
```

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Features** | `lib/features/<module>/` | Screens, widgets, module-specific UI |
| **Controllers** | `lib/core/controllers/` | `ChangeNotifier` state, pagination, UI-bound validation |
| **Repositories** | `lib/data/repositories/` | Domain interfaces; `Supabase*` for production, `Mock*` for tests |
| **Mappers** | `lib/data/mappers/` | Postgres rows ↔ Dart models |
| **Datasources** | `lib/data/datasources/` | Supabase client bootstrap, realtime, external APIs |
| **Wiring** | `lib/data/wiring/` | `RepositoryWiring.create(client)` — mock vs Supabase bundle |
| **Design system** | `lib/design_system/` | Theme, tokens, breakpoints, shared widgets |
| **Routing** | `lib/core/routing/` | `go_router` config and auth/permission guards |

**Rule:** widgets never import `supabase_flutter` directly.

## Boot sequence (Phase 02–04)

1. `HvacSupabase.initialize()` — URL/key from dart-define; `EnvironmentGuard` blocks staging/prod on dev project ref.
2. `RepositoryWiring.create(client)` — domain repos → `Supabase*` when client is live, `Mock*` for tests.
3. `ProductionBootGuard.validate` — staging/production fail fast if mock repos or missing Supabase.
4. `AppManagementAuthController` + `AuthSessionBridge` — login, restore, session expiry.
5. `GoRouter` + `AdminShell` — auth redirects and role-based sidebar.
6. `PermissionService` / `canOpen(AdminModule)` — financial modules blocked for `office_staff`.

Widget tests pass `HvacAdminApp(supabase: null)` → mock bundle + mock auth.

Environment details: `docs/environments.md`.

## Routing and permissions (Phase 05)

- Routes are root-relative: `/dashboard`, `/dispatch`, `/customers`, …
- Module enum: `lib/core/enums/admin_module.dart`
- **Financial modules** (estimates, invoices, reports): `owner` / `admin` only
- **Office staff**: operational modules only — see `docs/permissions.md`
- **Technicians**: rejected at login; they use `hvac_client`
- Enforcement: `PermissionService`, `ManagementAuthController.canOpen`, `GoRouter` redirect, `AdminShell` sidebar
- **RLS is authoritative** on the server

## Shared backend

| Asset | Owner project |
|-------|---------------|
| SQL migrations | `../hvac_client/supabase/migrations/` |
| RLS policies + tests | `../hvac_client/supabase/` + `../hvac_client/tool/verify_rls.sh` |
| DB architecture docs | `../hvac_client/docs/db/architecture.md` |
| Domain-specific DB docs | `../hvac_client/docs/db/*.md` |

Do **not** duplicate migrations in `hvac_admin`. Apply schema changes from `hvac_client` only.

## Domain model (summary)

```
Customer → Property → Equipment → Jobs → Documents / Photos / Warranties / Invoices
Employee → Truck → Device → Jobs
```

Property/address is the organizing unit for service history. See `../hvac_client/docs/db/architecture.md` for the full ER diagram and RLS matrix.

## Design system (Phase 06)

- `design_system/` — dark office theme, tokens, shared widgets (`SurfaceCard`, `StatusChip`, `AppDataTable`, `EmptyState`, `LoadingState`, `ErrorState`, …)
- `AdminShell` — sidebar (≥768px) / drawer, search action, styled nav tiles
- Nested detail routes: `/customers/:id`, `/properties/:id`, `/jobs/:id`, …
- Global search placeholder: `/search`

## Feature modules (`lib/features/`)

| Folder | Module |
|--------|--------|
| `dashboard/` | KPIs, quick actions |
| `dispatch/` | Technician dispatch board |
| `calendar/` | Schedule views |
| `customers/` | CRM — customers |
| `properties/` | Properties + history timeline |
| `jobs/` | Job list and detail |
| `technicians/` | Technician directory |
| `fleet/` | Trucks and devices |
| `equipment/` | Equipment + warranty |
| `maintenance/` | Maintenance agreements |
| `documents/` | Template library |
| `communication/` | SMS / email |
| `inventory/` | Parts and stock |
| `estimates/` | Estimates (financial) |
| `invoices/` | Invoices (financial) |
| `reports/` | Analytics (financial) |
| `settings/` | Company config |
| `shared/` | Cross-module widgets |

## Realtime (Phase 18)

Office sign-in starts `SupabaseRealtimeService` on channel `hvac-office-{userId}` with `postgres_changes` for:

`jobs`, `job_assignments`, `job_status_history`, `job_photos`, `job_documents`, `notifications`, `technicians`, `technician_locations`.

`RealtimeBridge` debounces controller refresh (~350ms), dedupes local mutation echoes, and falls back to 30s polling when the socket disconnects. Widget tests use `NoopRealtimeService` (no sockets). Details: `../hvac_client/docs/db/realtime.md`.

## Tests

| Suite | Purpose |
|-------|---------|
| `test/widget_test.dart` | Login, permissions, CRM, dispatch, module smoke (248+ cases total) |
| `test/security_denial_test.dart` | Role denial + RLS error mapping |
| `test/rls_admin_gating_test.dart` | Financial UI gate matrix |
| `test/admin_route_guard_test.dart` | Route permission guards |
| `test/supabase_repository_contract_test.dart` | Supabase repo wiring contracts |
| `test/environment_project_ref_test.dart` | Staging/production project ref guards |
| `test/rls_migration_contract_test.dart` | Shared migration + backup contracts |
| `test/production_boot_test.dart` | Wiring + boot guard contract |
| `test/integration/staging_supabase_test.dart` | Opt-in live Supabase (staging only) |

Run: `flutter test` (CI) · Live: see `docs/e2e-security-tests.md`.

Ops: `docs/backups-and-migration.md` — staging/prod DB setup, migrations, restore drill.

## Documentation

| Doc | Topic |
|-----|-------|
| [production-readiness.md](production-readiness.md) | Phase 36 verdict + go-live gates |
| [deployment.md](deployment.md) | Web + Windows builds |
| [security.md](security.md) | Trust boundaries |
| [permissions.md](permissions.md) | Role matrix |
| [integrations.md](integrations.md) | Edge functions |
| [ci-cd.md](ci-cd.md) | GitHub Actions |
| [e2e-manual-checklist.md](e2e-manual-checklist.md) | Staging smoke |

## Phase roadmap

Implementation phases: `phases/README.md` (36 phases, zero → production).
