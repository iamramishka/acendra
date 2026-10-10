# ADR-007: Trusted Payment Verification and Finalization

- Status: Accepted - implementation and operational gates retained
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-004, CSA-005, CSA-006, CSA-016

## Context

Online payments and bank transfers affect financial records and paid
course access. Client success screens, redirects, uploaded receipts, and
unverified callbacks are not trusted evidence of settlement.

## Decision

require all payment state changes that can grant access to pass through
trusted backend verification and transactional database finalization.
For provider events, verify authenticity and match the trusted order,
amount, currency, provider reference, and outcome. Enforce idempotency and
valid state transitions. For bank transfers, a receipt is evidence only;
an authorized reviewer must independently confirm settlement before an
audited transaction can approve payment and grant the corresponding
entitlement.

PayHere/LKR are selected under CSA-004; bank review follows CSA-005 and
lifetime access/refund/reversal behavior follows CSA-006. Provider protocol
implementation, reconciliation and production verification remain gated.

## Alternatives considered

- Trusting a client redirect or client-supplied paid flag: simpler, but
  forgeable and insufficient to authorize paid access.
- Granting access when a receipt is uploaded: reduces review delay, but
  treats unverified evidence as settlement and enables fraud.
- Updating payment and enrollment in separate non-transactional steps:
  simpler to compose, but can leave financial and access state inconsistent.

## Consequences and tradeoffs

- Trusted functions and database transactions are required for finalization.
- Provider-specific signature validation, retries, refunds, and dispute
  handling remain open until the payment provider and business rules are
  selected.
- Auditable transitions and concurrency tests add implementation work but
  protect financial integrity.

## Security and privacy impact

Reject forged, duplicated, delayed, mismatched, and concurrent events
safely. Restrict access to receipts and financial records. Never log
payment secrets or unnecessary receipt contents.

## Approval

Accepted by the project owner on 2026-10-11 through the approved CSA-007
architecture baseline (PR #4). Reconciled at the owner's request under CSA-016.
This accepts the decision, not evidence of implementation or production readiness.
See [approved architecture](../../ARCHITECTURE.md) and
[reconciliation record](../requirements/CSA-009-016-RECONCILIATION.md).
