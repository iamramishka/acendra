# CSA-006: Enrollment, expiry and refund policy

Date: 2026-10-11
Status: APPROVED baseline - owner accepted and authorized merge on 2026-10-11
Requirements: FR-ENROLL-001..010, FR-PAY, FR-BANK, BR-001..016;
SRS:DEC-006/007, PLAN:DEC-004/005; approved CSA-003..005 policies.

## Owner-confirmed choices

The owner selected "Lifetime access; refund requests within 7 days".
Purchased access therefore has no scheduled expiry (`expires_at=null`) and starts
only when verified fulfillment commits on the backend. Checkout, receipt upload
or a success redirect never grants access. Unpublishing preserves purchases.
Lifetime describes no scheduled access end; service closure/content availability
limits must be disclosed in published terms, not hidden or represented as a
promise that a company will operate forever.

## Approved precise policy

1. A request is timely when received by the backend at or before the first
   committed fulfillment time plus 168 hours. Store UTC timestamps and display
   the deadline in Asia/Colombo time. Bank-transfer buyers get the full window
   after approval. Retry, course editing and access requests cannot restart it.
2. Timely requests receive finance review. Request, review, rejection and
   approval alone do not change paid status or access. Approved MVP ordinary
   refund outcome is a full refund of the purchased order's paid amount once
   approved; do not deduct fees or invent consumption/download thresholds.
   Partial refunds require a separate approved policy and remain outside the
   ordinary path. Eligibility grounds and published terms must be approved before
   live sales; a seven-day request window is not unconditional payout approval.
3. Accept late requests into an exception channel labelled outside the commercial
   window. Do not describe the commercial rule as overriding applicable consumer
   rights, bank/provider rules or dispute obligations. Legal terms require review.
4. Use a current authorized independent finance reviewer, production MFA and
   no own-purchase approval. Check ownership, paid order, original settlement and
   payout destination. Use the original payment method where supported. A bank
   refund needs independently verified beneficiary details and outgoing settlement
   evidence; uploaded receipts/reviewer flags alone cannot confirm a payout.
5. Approval authorizes execution, not settlement. Mark order REFUNDED only after
   a trusted full-refund confirmation. In the same transaction invalidate only
   that order-funded grant, recompute current access, record adjustment/audit and
   enqueue notice. A valid independent admin or later-purchase grant survives.
6. Record provider-confirmed disputes separately from refunds. Approved risk
   behavior: restrict the disputed transaction's grant during review; a student
   allegation alone cannot impose that restriction. On verified favorable
   resolution lift that restriction only if the grant remains valid. Confirmed
   reversal invalidates the funding grant without fabricating a refund.
7. Super-admin manual grant/revocation requires reason, scope and audit under
   CSA-003. Distinguish grant-specific reversal from course/account restrictions.
   A new purchase may restore ordinary refunded access with a fresh verified grant,
   but cannot remove an active broader safety restriction.
8. Time-limited complimentary grants may have explicit expiry. Access checks
   evaluate timestamps directly even before a worker refreshes enrollment labels.
   No time-limited paid grant is created for the selected lifetime product.

## State and source model

| Event | Financial effect | Access effect |
| --- | --- | --- |
| Verified payment/bank approval | Eligible payable order -> PAID | One source-linked lifetime grant |
| Refund request | Create requested case | None |
| Approved execution | Case approved -> processing | None absent separate restriction |
| Uncertain/failed payout | Reconciliation/failed case, no confirmed refund | None |
| Confirmed full refund | Paid order -> REFUNDED; confirmed adjustment | Invalidate associated grant, recompute |
| Trusted dispute opens | Record dispute | Approved source-specific temporary restriction |
| Verified favorable resolution | Record resolution | Lift only that valid dispute restriction |
| Confirmed reversal | Record reversal adjustment | Invalidate associated grant |
| Audited administrative restriction | No invented payment change | Deny at explicitly recorded scope |
| New verified order | New paid settlement | New grant; broader restrictions still enforced |

Enrollment retains ACTIVE/EXPIRED/REVOKED states; do not add a suspended enum
implicitly. Its current state is derived from surviving grants and restrictions.
Preserve original order/payment/grant IDs and immutable financial history.
Late success callbacks cannot revive invalidated grants or refunded orders.

## Transaction and external payout boundary

Use a consistent lock order for fulfillment, refund confirmation, disputes and
manual access changes. Recheck current actor permission and source association
within the trusted operation. Unique source grants and provider events plus
actor/operation idempotency prevent duplicates; changed-payload key reuse conflicts.

External payout cannot be rolled back by PostgreSQL. Persist a durable refund
command, execute with provider idempotency where supported, and reconcile an
ambiguous timeout before retrying. Then atomically confirm financial adjustment,
grant lifecycle, derived enrollment, audit and notification outbox. A timeout is
uncertain, not permission for blind duplicate payouts. Notifications follow commit.

## Acceptance criteria

- Lifetime purchased access has no scheduled expiry; no unverified grant exists.
- Backend time determines exact deadline, including the 168-hour boundary and
  delayed bank approval; client clocks and replay do not change it.
- Unauthorized/self-review requests and duplicate/opposing decisions fail safely.
- Refund request/rejection preserves access; confirmed full refund affects only
  its funding grant; independent grants survive.
- Refund/repurchase concurrency, late callbacks, uncertain payout and duplicate
  confirmations cannot double-pay or revive invalidated sources.
- Dispute restoration cannot remove another restriction or restore reversed funds.
- Injected transaction failure leaves no partial financial/access/audit writes.
- Student responses omit internal notes and bank evidence; history is preserved.

No implementation tests were run. The owner accepted cutoff anchoring,
finance-reviewed full-only default, dispute restrictions and the specified policy
by requesting review and merge on 2026-10-11. Eligibility grounds, contact/response targets,
provider refund capability/fees, beneficiary verification procedure and retention
are explicit operational/terms gates, not invented values.
