# Phase 20 — Communication Outbound (SMS / Email)

## Goal
Send SMS and email to customers from admin with templated messages.

## Constraints
- Twilio/Resend (or equivalent) secrets stay server-side (Edge Functions); Flutter never holds them.
- Architecture per `../hvac_client/docs/db/messaging.md`.
- Templates: appointment reminder, technician on the way, job completed, estimate/document links.

## What to do (execution checklist)
1. Communication page: select customer/job, choose channel (SMS/email), pick template.
2. Compose with auto-filled customer name, address, appointment time.
3. Send via Edge Function; show pending/sent/failed status.
4. Quick-send actions from job detail and dispatch board.
5. `CommunicationController` + repository wired to outbound API.

## Verification
1. Send appointment reminder → customer receives SMS/email (staging).
2. Failed send shows error with retry option.
3. No provider API keys in Flutter binary.

## Stop condition
Outbound messaging works from admin via server-side dispatch.
