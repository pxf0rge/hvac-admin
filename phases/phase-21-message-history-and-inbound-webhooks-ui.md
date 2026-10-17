# Phase 21 — Message History + Inbound Webhooks UI

## Goal
View full communication history per customer and job, including inbound customer replies.

## Constraints
- History stored in messages table(s); inbound via webhooks processed server-side.
- Chronological thread view grouped by customer or job.
- Read-only for historical messages; replies use outbound flow from Phase 20.

## What to do (execution checklist)
1. Message history on customer detail and job detail pages.
2. Thread view: sent/received, timestamp, channel, status, body preview.
3. Filter by channel (SMS/email) and date range.
4. Link inbound messages to correct customer/job (webhook matching logic is server-side).
5. Search messages by customer name or phone.

## Verification
1. Outbound message from Phase 20 appears in history.
2. Simulated inbound webhook → message visible on correct customer thread.
3. Communication page shows recent threads across all customers.

## Stop condition
Complete communication history visible in admin.
