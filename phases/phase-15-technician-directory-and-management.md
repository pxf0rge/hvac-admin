# Phase 15 — Technician Directory + Management

## Goal
Manage technician profiles, availability status, and account linkage.

## Constraints
- Technician is a separate entity from employee user account (`profiles` + `technicians` table).
- Admin can view technician status: Available, Assigned, On the way, Arrived, Job started, Completed, Off duty.
- Do not expose financial data on technician screens.

## What to do (execution checklist)
1. Technician list: name, phone, current status, active job count.
2. Technician detail: profile, assigned truck/device, recent jobs, performance summary (later phase).
3. Create/edit technician profile linked to auth user.
4. Enable/disable technician account.
5. Show live status from `technicians.status` or latest `job_status_history`.

## Verification
1. Technician list reflects real Supabase data.
2. Status updates from field app appear in admin (with realtime in Phase 18).
3. Disabled technician cannot log into `hvac_client`.

## Stop condition
Technician management is functional; ready for fleet in Phase 16.
