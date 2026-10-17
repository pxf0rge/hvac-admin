# Phase 29 — Global Search + Pagination

## Goal
Fast search across customers, properties, jobs, equipment, and invoices with paginated list screens.

## Constraints
- Server-side or Supabase full-text search where available; client-side filter only for small dev datasets.
- Search respects RLS — results limited to what role can see.
- All major list screens must paginate (not load entire table).

## What to do (execution checklist)
1. Global search bar (app bar): query customers, properties, jobs, equipment by name/address/serial/job number.
2. Search results page grouped by entity type.
3. Add cursor/offset pagination to: customers, properties, jobs, invoices, inventory, messages.
4. Debounced search input; loading indicator.
5. Empty state for no results.

## Verification
1. Search "123 Main" finds property and related jobs.
2. Lists with 100+ rows paginate without UI freeze.
3. Financial search results hidden for `office_staff`.

## Stop condition
Search and pagination work across all major list screens.
