# Phase 32 — Security + File Hardening

## Goal
Harden admin app against common web/desktop threats and secure file access.

## Constraints
- RLS is the primary authorization layer; UI guards are secondary.
- Signed URLs for Storage downloads; no public buckets for customer docs.
- See `../hvac_client/supabase/migrations/` for file hardening migrations.

## What to do (execution checklist)
1. Verify all Storage access uses signed URLs with expiry.
2. Content-Security-Policy headers for web deployment.
3. Confirm admin routes reject unauthenticated and wrong-role access.
4. Rate-limit sensitive actions server-side where possible.
5. Review `profiles.role` never settable from client metadata.
6. Run `../hvac_client/tool/verify_rls.sh` against shared Supabase project.

## Verification
1. Direct Storage URL without signed token returns 403.
2. Technician JWT cannot query financial tables via admin app's Supabase client.
3. RLS verification script passes.

## Stop condition
Security review complete; file access hardened.
