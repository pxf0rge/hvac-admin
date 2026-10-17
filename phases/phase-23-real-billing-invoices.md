# Phase 23 — Real Billing — Invoices

## Goal
Create, send, and track invoices with payment status.

## Constraints
- Financial module: `owner`/`admin` only.
- Invoices linked to job, customer, property; line items in `invoice_line_items`.
- Status: draft → sent → paid → overdue → void.
- Design for future online payment integration (Phase 24).

## What to do (execution checklist)
1. Invoice list with status and amount filters.
2. Create invoice manually or from estimate/job.
3. Invoice detail: line items, totals, payment status, send action.
4. Mark paid manually (until Stripe in Phase 24).
5. Overdue detection based on due date.
6. Invoice PDF / printable view.

## Verification
1. Create invoice → persists; appears on property history.
2. Send invoice triggers customer email (Phase 20).
3. `office_staff` denied at router and API level.

## Stop condition
Invoices module is production-backed; ready for payments in Phase 24.
