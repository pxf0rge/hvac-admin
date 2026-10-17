# Phase 11 — Real Equipment + Warranty

## Goal
HVAC equipment records and warranty tracking per property.

## Constraints
- Each unit: manufacturer, model, serial, type, capacity, install date, installer, photos, manuals.
- Warranty archive searchable by customer or property address.
- Equipment linked to property; service history via `equipment_jobs`.

## What to do (execution checklist)
1. Equipment list (filterable by property, type, warranty status).
2. Equipment detail: specs, install info, warranty dates, linked jobs.
3. Create/edit equipment on a property.
4. Warranty section: active/expired, registration docs.
5. Photo and manual upload to Storage (metadata in `equipment_media`).
6. Warranty search page (by address or customer name).

## Verification
1. Add equipment to property → appears on property detail and warranty search.
2. Serial number searchable.
3. Expired vs active warranty badges correct.

## Stop condition
Equipment and warranty modules are production-backed; ready for jobs in Phase 12.
