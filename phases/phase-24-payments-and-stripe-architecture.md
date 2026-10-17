# Phase 24 — Payments + Stripe Architecture

## Goal
Online payment support for invoices — architecture ready even if not fully enabled in v1.

## Constraints
- Stripe secret keys server-side only (Edge Functions).
- Flutter uses publishable key + checkout session URL pattern.
- Payment status reflected on invoice row.
- See `../hvac_client` payment implementation for reference.

## What to do (execution checklist)
1. "Pay now" link generation for sent invoices (server-side Stripe Checkout or Payment Link).
2. Payment status webhook updates `invoices` and `payments` tables.
3. Invoice detail shows payment history.
4. Admin can record manual payment (cash/check) as fallback.
5. Document Stripe env vars and webhook setup.

## Verification
1. Test payment in Stripe test mode updates invoice to paid.
2. No Stripe secret in Flutter.
3. Payment record linked to correct invoice and customer.

## Stop condition
Payment flow architecture is in place; test-mode payments work end-to-end.
