# Phase 35 — E2E + Security Tests

## Goal
End-to-end and security test coverage for critical admin flows.

## Constraints
- E2E against staging Supabase with test accounts per role.
- Security tests verify RLS denial for wrong roles.
- Reuse patterns from `../hvac_client/test/security_denial_test.dart`.

## What to do (execution checklist)
1. Widget tests for login, permission guards, dispatch assign, CRM create.
2. Integration tests: login as owner → create customer → create job → assign on dispatch.
3. Security tests: `office_staff` cannot fetch invoices; technician JWT rejected at login.
4. Repository unit tests for all Supabase repos.
5. Optional: Playwright/patrol E2E for web flows.

## Verification
1. `flutter test` passes all unit/widget/security tests.
2. Integration test completes full dispatch flow on staging.
3. No test uses production credentials.

## Stop condition
Test suite covers auth, permissions, CRM, jobs, dispatch, and security denials.
