# Phase 28 — Management Settings + Company Config

## Goal
Company-wide settings: business info, branding, working hours, notification preferences, integrations.

## Constraints
- Settings stored in company settings table(s); single-tenant for now.
- Changes affect document templates, invoices, and customer communications.
- Sensitive integration keys configured server-side, not in Flutter.

## What to do (execution checklist)
1. Settings page sections: Company Info, Branding, Working Hours, Notifications, Integrations.
2. Company info: name, address, phone, email, license numbers (used in documents/invoices).
3. Working hours policy (feeds GPS tracking rules).
4. Logo upload for documents and invoices.
5. Integration status indicators (Stripe, Twilio, Resend) — configure via server/env.
6. User management: invite office staff, assign roles (owner/admin only).

## Verification
1. Update company name → appears on new invoice PDF.
2. Working hours change reflected in GPS policy docs.
3. Role assignment persists in `profiles.role`.

## Stop condition
Settings module is functional; company config drives documents and policies.
