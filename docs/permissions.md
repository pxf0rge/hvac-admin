# Admin permissions

UI module guards mirror Supabase RLS intent documented in `../hvac_client/docs/db/architecture.md`.

**Server RLS is authoritative.** UI guards prevent confusion; they are not a security boundary.

## Roles

| Role (`profiles.role`) | Admin app access |
|---|---|
| `owner` | Full access including financial modules |
| `admin` | Full access including financial modules |
| `office_staff` | CRM, dispatch, jobs, communication, inventory, settings — **no financials** |
| `technician` | **Rejected at login** — use `hvac_client` field app |

## Module matrix

| Module | Path | Owner | Admin | Office staff |
|---|---|:---:|:---:|:---:|
| Dashboard | `/dashboard` | ✓ | ✓ | ✓ |
| Dispatch | `/dispatch` | ✓ | ✓ | ✓ |
| Calendar | `/calendar` | ✓ | ✓ | ✓ |
| Customers | `/customers` | ✓ | ✓ | ✓ |
| Properties | `/properties` | ✓ | ✓ | ✓ |
| Jobs | `/jobs` | ✓ | ✓ | ✓ |
| Technicians | `/technicians` | ✓ | ✓ | ✓ |
| Office Personnel | `/office-personnel` | ✓ | ✓ | ✓ (read) |
| Fleet | `/fleet` | ✓ | ✓ | ✓ |
| Equipment | `/equipment` | ✓ | ✓ | ✓ |
| Maintenance | `/maintenance` | ✓ | ✓ | ✓ |
| Documents | `/documents` | ✓ | ✓ | ✓ |
| Communication | `/communication` | ✓ | ✓ | ✓ |
| Inventory | `/inventory` | ✓ | ✓ | ✓ |
| Settings | `/settings` | ✓ | ✓ | ✓ |
| **Estimates** | `/estimates` | ✓ | ✓ | **✗** |
| **Invoices** | `/invoices` | ✓ | ✓ | **✗** |
| **Reports** | `/reports` | ✓ | ✓ | **✗** |
| **Audit log** | `/settings/audit` | ✓ | ✓ | **✗** |

Financial modules: `estimates`, `invoices`, `reports`. Audit log is owner/admin only (same financial visibility gate).

## Office Personnel management

| Action | Owner | Admin | Office staff |
|---|:---:|:---:|:---:|
| Browse directory | ✓ | ✓ | ✓ |
| Invite user | ✓ | ✓ | ✗ |
| Change role | ✓ | ✓ (not to `owner`) | ✗ |
| Deactivate / reactivate | ✓ | ✓ | ✗ |

Mutations go through Edge Function `manage-office-user` (service role). Only an **owner** may invite or assign the `owner` role. Deactivated users (`profiles.is_active = false`) are rejected at admin login.

## Global search

`/search` is available to all management roles. Financial hits (invoices, estimates) are **filtered out** for `office_staff` in `GlobalSearchService` — even if RLS would already deny direct reads.

## GPS map

Technician live locations: available to all management roles. Data comes from `technician_locations` (written by field app). No separate permission gate beyond management login.

## Enforcement

| Layer | Location |
|---|---|
| Permission logic | `lib/core/auth/permission_service.dart` |
| Controller API | `ManagementAuthController.canOpen(AdminModule)` |
| Route guard | `lib/core/routing/admin_route_guard.dart` → `GoRouter.redirect` |
| Navigation | `AdminShell` sidebar lists only `PermissionService.visibleModules(role)` |

Direct navigation to a forbidden path (e.g. `/invoices` or `/settings/audit` as office staff) redirects to `/dashboard`.

## Code references

```dart
// Check before showing a financial action
if (auth.canOpen(AdminModule.invoices)) { ... }

// List sidebar modules
PermissionService.visibleModules(auth.role);
```

## Related backend rules

From `../hvac_client/docs/db/architecture.md`:

- `office_staff` — broad office access, **no** estimates/invoices/line items
- `owner` / `admin` — all rows including financials
- Technicians — job-scoped access only; no admin app
