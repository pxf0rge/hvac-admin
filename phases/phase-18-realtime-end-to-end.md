# Phase 18 — Realtime End-to-End

## Goal
Live updates in admin UI when technicians change job status, dispatch assigns jobs, or new messages arrive.

## Constraints
- Use Supabase Realtime channels; same patterns as `../hvac_client/docs/db/realtime.md`.
- Subscribe only to tables/events the current role may see (RLS applies to realtime).
- Unsubscribe on dispose to avoid leaks.

## What to do (execution checklist)
1. Create `RealtimeService` / bridge for admin subscriptions.
2. Dispatch board auto-refreshes on `jobs` / `job_assignments` changes.
3. Technician status list updates on `technicians` / `job_status_history` changes.
4. GPS map markers update on `technician_locations` inserts.
5. Notification badge for new messages (optional in this phase).
6. Fallback polling when realtime disconnects.

## Verification
1. Assign job on dispatch → board updates without manual refresh.
2. Technician marks "On the way" → status visible in admin within seconds.
3. No memory leaks from orphaned subscriptions.

## Stop condition
Key admin screens receive live updates from Supabase Realtime.
