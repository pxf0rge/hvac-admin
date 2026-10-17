# Phase 13 — Real Dispatch + Assignments

## Goal
Dispatch board to assign, reassign, and schedule technicians against real jobs.

## Constraints
- Same underlying data as technician job lists (no second scheduling system).
- Prefer conflict warnings over silent double-booking.
- Drag-and-drop assignment UX for desktop; touch-friendly fallback for tablet.
- Example card: customer, address, service, time window, assigned technician.

## What to do (execution checklist)
1. Dispatch board: columns or rows per technician with job cards for the day.
2. Persist assignment create/update (`job_assignments`, `jobs.technician_id`).
3. Drag job card to technician column → assignment saved.
4. Reassign + unassign with history-friendly timestamps.
5. Reschedule updates `scheduled_date` / start/end times.
6. Warn when technician has overlapping active assignment.
7. Unassigned jobs pool visible for drag-to-assign.

## Verification
1. Assign job to Carlos → Carlos device shows job (after realtime/refresh).
2. Reassign → previous tech loses access (RLS); new tech gains it.
3. Conflict warning appears for overlapping schedule when detectable.
4. Drag-and-drop works on web and Windows.

## Stop condition
Dispatch mutations are database-backed and visible to field app.
