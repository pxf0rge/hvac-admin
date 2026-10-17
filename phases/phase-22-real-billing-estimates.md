# Phase 22 — Real Billing — Estimates

## Goal
Create, send, and track estimates linked to jobs and customers.

## Constraints
- Financial module: `owner`/`admin` only (enforced by Phase 05 guards + RLS).
- Estimates linked to job and customer; line items in `estimate_line_items`.
- Status flow: draft → sent → approved → declined → converted.

## What to do (execution checklist)
1. Estimate list with status filters.
2. Create estimate from job or customer: line items, labor, parts, tax, total.
3. Estimate detail: preview, send to customer (email link via Phase 20).
4. Convert approved estimate to invoice (Phase 23).
5. PDF generation or printable view.

## Verification
1. Create estimate → persists in Supabase.
2. `office_staff` cannot access estimates module.
3. Estimate appears on property history timeline.

## Stop condition
Estimates module is production-backed; ready for invoices in Phase 23.
