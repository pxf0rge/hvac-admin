# Phase 10 — Property Detail + Service History Timeline

## Goal
When searching an address, show the complete service history for that property.

## Constraints
- Property is the organizing unit: equipment, jobs, documents, photos, warranties, invoices all hang off it.
- Timeline must aggregate: jobs, status changes, documents signed, photos uploaded, equipment installed.
- Read-heavy screen; writes go through respective modules.

## What to do (execution checklist)
1. Property detail page with tabs or sections: Overview, Equipment, Jobs, Documents, Photos, Timeline.
2. Timeline view from `property_timeline_events` + related tables.
3. Show previous technicians, job outcomes, and linked estimates/invoices (financial roles only).
4. Address search that lands on property detail.
5. Equipment count and active warranty summary on overview.

## Verification
1. Search "123 Main St" → full history visible.
2. Timeline shows chronological events with correct types.
3. Financial sections hidden for `office_staff`.

## Stop condition
Property-centric history view is complete; ready for equipment in Phase 11.
