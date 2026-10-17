# Phase 04 — Auth (Owner / Admin / Office Staff)

## Goal
Secure login for management roles only — technicians must not access this app.

## Constraints
- Role source of truth is `profiles.role` (never client-supplied metadata alone).
- Allowed roles: `owner`, `admin`, `office_staff`.
- Reject `technician` role at login with clear message.
- Session restore on app restart.

## What to do (execution checklist)
1. Create `AuthRepository` + `SupabaseAuthRepository` using Supabase Auth.
2. Create `AuthController` with sign-in, sign-out, session restore.
3. Build login screen (email + password).
4. On successful login, fetch `profiles` row and validate role.
5. Redirect unauthenticated users to `/login`; authenticated to `/dashboard`.
6. Handle expired/invalid session gracefully.

## Verification
1. Owner/admin/office_staff login works against staging.
2. Technician credentials are rejected.
3. Restart restores session when refresh token valid.
4. Sign-out clears session and returns to login.

## Stop condition
Auth flow complete for all management roles; ready for permission guards in Phase 05.
