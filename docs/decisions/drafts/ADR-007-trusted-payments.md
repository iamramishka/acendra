# ADR-007: Trusted Payment Verification and Finalization

- Status: Proposed security invariant; implementation details pending
- Decision owner: Project Lead
- Date: 2026-10-11
- Related tasks: CSA-004, CSA-005, CSA-006, CSA-016

## Context

Online payments and bank transfers affect financial records and paid
course access. Client success screens, redirects, uploaded receipts, and
unverified callbacks are not trusted evidence of settlement.

## Decision

Proposed: require all payment state changes that can grant access to pass through
trusted backend verification and transactional database finalization.
For provider events, verify authenticity and match the trusted order,
amount, currency, provider reference, and outcome. Enforce idempotency and
valid state transitions. For bank transfers, a receipt is evidence only;
an authorized reviewer must independently confirm settlement before an
audited transaction can approve payment and grant the corresponding
entitlement.

This is a security and correctness requirement, not a selection of a
payment gateway, currency, bank-review policy, refund rule, or settlement
provider protocol.

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

The security invariant is required by the project guidance. The Project
Lead must approve the architecture and decide provider and business rules
under CSA-004 through CSA-006 before production use.
