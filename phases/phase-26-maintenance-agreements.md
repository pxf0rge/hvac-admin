# Phase 26 — Maintenance Agreements

## Goal
Track maintenance agreements per property with renewal reminders.

## Constraints
- Agreements linked to property and optionally equipment.
- Reminder scheduling (server-side cron or Edge Function).
- See `../hvac_client/docs/db/maintenance-agreements.md`.

## What to do (execution checklist)
1. Agreement list: customer, property, plan type, start/end, status.
2. Create/edit agreement: coverage, visit frequency, price, equipment covered.
3. Agreement detail: visit history, upcoming scheduled visits.
4. Renewal and expiration alerts.
5. Link agreement to recurring job creation (manual or automated).

## Verification
1. Create agreement → visible on property detail.
2. Expiring agreement shows alert on dashboard.
3. Agreement history accessible from property timeline.

## Stop condition
Maintenance agreements module is production-backed.
