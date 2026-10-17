# Phase 17 — GPS Map View (Technician Locations)

## Goal
Management map showing technician locations during working hours — not 24/7 tracking.

## Constraints
- Location data from technician app (`hvac_client`) via Supabase.
- Show: name, status, current/next job address.
- Example: Carlos — On Job — 123 Main St; Luis — Driving — Next Job.
- Respect company working-hours policy; no tracking when off duty.
- Activity history: On the way → Arrived → Completed timestamps.

## What to do (execution checklist)
1. Map screen (web: Google Maps / Mapbox / flutter_map; evaluate license).
2. Plot technician markers from `technician_locations` or latest fix per tech.
3. Marker popup: name, status, job address.
4. List view alternative for environments without map API key.
5. Link to technician detail and active job.
6. Show last-updated timestamp; stale indicator when no recent fix.

## Verification
1. Carlos updates status on phone → map marker and status update in admin.
2. Off-duty technicians not shown (or greyed out per policy).
3. Activity history matches `job_status_history` for active job.

## Stop condition
GPS map view is functional for management during work hours.
