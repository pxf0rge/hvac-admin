# Phase 14 — Management Calendar

## Goal
Calendar view of all jobs and assignments with create/reschedule/assign actions.

## Constraints
- Same data source as Dispatch (no parallel scheduling system).
- Support day/week views and technician filter at minimum.
- Status colors consistent with dispatch board chips.

## What to do (execution checklist)
1. Calendar screen using real jobs from Supabase.
2. Day view and week view toggle.
3. Technician filter (show all or one technician).
4. Click job → detail or quick-edit panel.
5. Create/reschedule/assign actions call same APIs as dispatch.
6. Empty/loading/error states.

## Verification
1. Job created on calendar appears on dispatch board and technician schedule.
2. Reschedule updates DB and other views.
3. Technician filter works.

## Stop condition
Calendar is production-backed and consistent with dispatch.
