# HVAC Admin — Production Phases

Standalone Flutter admin/office app for Owner, Admin, and Office Staff.

**Starting point:** Empty Flutter project (`hvac_admin`). Backend schema, RLS, and migrations live in `../hvac_client/supabase/`. Technician field app lives in `../hvac_client/`.

**Goal:** Production-ready management interface (web + Windows desktop primary) with full business visibility, dispatch, CRM, billing, and analytics — wired to the same Supabase project as the technician app.

| Phase | Title |
|---|---|
| 01 | Project foundation + architecture |
| 02 | Environments + secrets hygiene |
| 03 | Architecture wiring (Controller → Repository → Datasource) |
| 04 | Auth (owner / admin / office staff) |
| 05 | Role permissions + module guards |
| 06 | Design system + responsive shell + routing |
| 07 | Domain mappers + repository wiring |
| 08 | Dashboard + business overview |
| 09 | Real CRM (customers + properties) |
| 10 | Property detail + service history timeline |
| 11 | Real equipment + warranty |
| 12 | Real jobs core |
| 13 | Real dispatch + assignments |
| 14 | Management calendar |
| 15 | Technician directory + management |
| 16 | Fleet (trucks + devices) |
| 17 | GPS map view (technician locations) |
| 18 | Realtime end-to-end |
| 19 | Document template library |
| 20 | Communication outbound (SMS / email) |
| 21 | Message history + inbound webhooks UI |
| 22 | Real billing — estimates |
| 23 | Real billing — invoices |
| 24 | Payments + Stripe architecture |
| 25 | Real inventory |
| 26 | Maintenance agreements |
| 27 | Reports + technician performance |
| 28 | Management settings + company config |
| 29 | Global search + pagination |
| 30 | Validation + domain error handling |
| 31 | Audit logging + observability |
| 32 | Security + file hardening |
| 33 | Staging / prod databases + backups |
| 34 | CI/CD + automated builds |
| 35 | E2E + security tests |
| 36 | Documentation + final acceptance |

## Relationship to `hvac_client`

| Concern | Owner |
|---|---|
| Supabase schema + migrations | `hvac_client/supabase/` |
| RLS policies + security tests | `hvac_client/supabase/` + `hvac_client/tool/` |
| Technician mobile UI | `hvac_client/` |
| Admin / office UI | `hvac_admin/` (this project) |

## Execution rules

- One phase at a time unless asked otherwise.
- Follow Controller → Repository → Datasource; never call Supabase from widgets.
- Permissions enforced by RLS **and** UI module guards (`owner` / `admin` / `office_staff`).
- `office_staff` must not see financial modules (estimates, invoices, reports) unless role policy changes.
- Never put service-role / Stripe / Twilio / Resend secrets in Flutter.
- Primary targets: **web** and **Windows desktop**; tablet-friendly layouts required.
- Keep mock repos for tests/dev only; production wiring must use Supabase.
- Do not claim production-ready until Phase 36 acceptance criteria pass.
- Reuse domain knowledge from `hvac_client` (models, mappers, docs) — do not duplicate backend migrations here.

## Reference

See `../hvac_client/phases/` for the technician/client production phases and `../hvac_client/docs/db/` for database architecture.
