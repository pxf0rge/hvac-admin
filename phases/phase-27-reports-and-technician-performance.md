# Phase 27 — Reports + Technician Performance

## Goal
Revenue reports, job statistics, technician performance, and business analytics for owner/admin.

## Constraints
- Financial reports: `owner`/`admin` only.
- Non-financial reports (job counts, completion rates): may extend to `admin`; never `office_staff` for revenue.
- Query existing tables; no separate data warehouse in v1.

## What to do (execution checklist)
1. Reports page with sections: Revenue, Jobs, Technicians, Invoices.
2. Revenue: total, by period, by service type.
3. Job stats: completed, cancelled, average duration, by technician.
4. Technician performance: jobs completed, on-time rate, customer rating (if tracked).
5. Invoice tracking: outstanding, overdue, paid this month.
6. Date range picker and export to CSV (optional).

## Verification
1. Revenue figures match invoice totals in Supabase.
2. `office_staff` cannot access reports module.
3. Job stats update when jobs complete in field app.

## Stop condition
Reports module provides actionable business analytics for management.
