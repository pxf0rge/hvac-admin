# Phase 12 — Real Jobs Core

## Goal
Create, view, edit, and manage jobs linked to properties and customers.

## Constraints
- Jobs are the operational unit: scheduled work at a property with a service description.
- Job status enum must match `job_status` in Postgres and technician app.
- Job detail shows assignment, schedule, status history, linked equipment, photos, documents.

## What to do (execution checklist)
1. Job list with filters: status, date range, technician, customer.
2. Create job: select customer/property, service type, description, scheduled date/time.
3. Job detail page: status chip, assignment, timeline, linked equipment.
4. Status transitions from admin side (cancel, reschedule) where policy allows.
5. `JobController` + `JobRepository` wired to Supabase.

## Verification
1. Create job → appears in job list and (when assigned) on technician device.
2. Job detail shows correct property and customer.
3. Status history recorded in `job_status_history`.

## Stop condition
Jobs CRUD is production-backed; ready for dispatch in Phase 13.
