# Phase 30 — Validation + Domain Error Handling

## Goal
Consistent input validation and user-friendly error messages across all admin forms.

## Constraints
- Validate on client before submit; server errors mapped to field-level messages.
- Use shared validators (phone, email, currency, required fields).
- Never expose raw Supabase/Postgres errors to users.

## What to do (execution checklist)
1. Create `lib/core/validation/` with shared validators (billing, CRM, scheduling).
2. Standardize `HvacFailure` → UI snackbar/dialog mapping.
3. Form-level validation on: customer create, job create, estimate/invoice line items, inventory adjustment.
4. Network error retry patterns on critical actions.
5. Inline field errors on forms; summary banner for server errors.

## Verification
1. Submit invalid phone number → inline error, no API call.
2. RLS denial → "You don't have permission" not raw 403 JSON.
3. Network timeout → retry option shown.

## Stop condition
Validation and error handling consistent across admin modules.
