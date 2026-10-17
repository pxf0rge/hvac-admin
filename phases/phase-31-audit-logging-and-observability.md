# Phase 31 — Audit Logging + Observability

## Goal
Track sensitive admin actions and provide operational visibility for debugging.

## Constraints
- Audit log written server-side or via RLS-protected `audit_log` table.
- PII redaction in log display.
- See `../hvac_client` audit implementation for reference.

## What to do (execution checklist)
1. Log admin actions: login, role change, invoice void, template publish, settings change, dispatch reassignment.
2. Audit log viewer in settings (owner/admin only).
3. Filter by user, action type, date range.
4. Client-side error reporting hook (optional: Sentry) for production crashes.
5. Redact sensitive fields in audit display.

## Verification
1. Reassign job → audit entry with actor, timestamp, before/after.
2. Audit log not visible to `office_staff`.
3. PII (passwords, tokens) never appears in log viewer.

## Stop condition
Audit trail exists for critical admin operations.
