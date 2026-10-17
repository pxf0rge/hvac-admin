# Phase 08 — Dashboard + Business Overview

## Goal
Owner/admin landing page with key business KPIs and quick actions.

## Constraints
- Financial KPIs visible only to `owner`/`admin` (not `office_staff`).
- Dashboard reads real Supabase aggregates where available; show honest empty states otherwise.
- Do not build a separate analytics database — query existing tables.

## What to do (execution checklist)
1. Create `DashboardController` + `ReportsRepository` (or dedicated dashboard queries).
2. Show cards: today's jobs, unassigned jobs, overdue invoices (financial roles), active technicians, open estimates.
3. Quick-action links: create job, open dispatch, view calendar.
4. Recent activity feed from `property_timeline_events` or `audit_log` if available.
5. Loading / error / empty states.

## Verification
1. Dashboard loads real data from staging Supabase.
2. `office_staff` does not see revenue/profit cards.
3. Quick actions navigate to correct modules.

## Stop condition
Dashboard is functional and role-aware; ready for CRM in Phase 09.
