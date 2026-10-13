# CSA-158 / CSA-172 reporting definition approval

## Current status — 2026-10-13

Foundation reviewed and merged into dev via [PR #107](https://github.com/iamramishka/acendra/pull/107).
Hosted PR checks passed; integration and shared test/config updates are complete.
Status remains IN_REVIEW for operational acceptance; production endpoints remain disabled.
Earlier pending-PR/integration/CI statements below describe the historical worker stage.
[Current evidence and remaining gates](../tasks/CSA-158-168-MERGE-RECONCILIATION.md) include the verified pre-existing
dev formatting failure, post-merge tests and activation prerequisites.

Date: 2026-10-12 (Asia/Colombo).
Authority: project owner, explicit reply to the reporting definition question
in the implementation chat, relayed to the reporting worker by the coordinating
CODEX agent.

Approved definition: confirmed settlements at settlement confirmation time;
Asia/Colombo calendar dates; net equals confirmed receipts minus confirmed
refunds, excluding fees and taxes.

This approves recognition and date semantics. It does not approve production
activation, a new refund state machine, inferred refund evidence, fee/tax
calculations or merge. Existing approved full-refund policy remains applicable.

Implementation returns exact confirmed gross receipt totals from immutable
verified settlements. Online sandbox records are excluded. The schema has no
confirmed refund/reversal adjustment ledger, so refunded/net numeric totals
remain explicitly unavailable with `confirmed_adjustment_ledger_unavailable`.
Their absence never means zero. Imported refunded order history fails closed
for financial facts until adjustment reporting is integrated and reviewed.
No order status, refund request or approval substitutes for settled payout
evidence. Future ledger integration must retain immutable source identity,
idempotency and trusted confirmation, under a separately owned reviewed task.

Status: recognition definition APPROVED; implementation IN_REVIEW; release
activation and actual Supabase CI remain outstanding.
