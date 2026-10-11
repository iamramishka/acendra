# CSA-112/113 — Independent bank review contract

Status: IN_REVIEW; disabled proposal extension of docs/API_CONTRACTS.MD.
Owner CODEX / verified_webhook. Issue #80. Date 2026-10-11.

Endpoint `POST /functions/v1/admin-review-bank-transfer`. Requires Auth-verified
user, authenticated session, AAL2 and current finance_admin or super_admin role
checked again inside transactional SQL. Current roles are never taken from JWT
app_metadata/user_metadata. No reviewer may approve or reject their own purchase.
Both actor and session are passed only after the exact bearer token is verified
by Supabase Auth; SQL rechecks current account/session/role and locks authorization.

## Proposal request shape

The approved generic API uses `verification`, `bank_account_id`,
`bank_transaction_reference`, numeric `amount_minor` and `rejection_reason`.
This disabled proposal uses a complete `verified_credit` object, canonical
exact integer strings and explicit source/date/reference required by approved
CSA-005. The shared baseline API document is unchanged; root coordinates review.
No frontend compatibility or production acceptance is claimed.

Required headers: Authorization Bearer, Content-Type application/json optionally
charset=utf-8, Idempotency-Key [A-Za-z0-9._:-] 1..128 characters.
Request size at most 8192 streamed bytes with strict UTF-8. Duplicate/conflicting
financial meaning is determined from parsed semantic JSON by database canonical
request hash; caller-supplied hashes and identity/role fields are not accepted.

Approval body:

```json
{
  "submission_id": "33333333-3333-4333-8333-333333333333",
  "decision": "approve",
  "verified_credit": {
    "bank_credit_confirmed": true,
    "destination_account_id": "55555555-5555-4555-8555-555555555555",
    "bank_transaction_id": "INDEPENDENT-STABLE-BANK-ID",
    "amount_minor": "250000",
    "currency": "LKR",
    "settled_at": "2026-10-10T12:00:00Z",
    "source": "bank_portal",
    "order_reference": "ACD-STORED-ORDER-NUMBER"
  },
  "private_notes": "Optional internal reviewer context"
}
```

Source enum: bank_portal, bank_statement, authenticated_bank_feed. A receipt,
student-entered reference or bank_credit_confirmed flag alone is not automated
proof. This records the authorized independent reviewer's assertion after they
check actual settled funds in the business-controlled bank source. Stable bank
transaction identity is scoped to the matched destination account. Unsupported
identity schemes and exceptional matches remain outside this standard path.
SQL independently matches authoritative destination, exact amount/currency,
reference and settled date; no FX, tolerance, split or overpayment approval.

Rejection body contains submission_id, decision reject, rejection_reason
(student-safe required text <=1000 characters), optional private_notes <=2000.
Rejection accepts no verified_credit; approval accepts no rejection_reason.
Unknown fields and unconfirmed/noncanonical/malformed evidence fail closed.
All text rejects control characters. Calendar timestamps must be valid, finite
and nonfuture; SQL repeats finite/nonfuture timestamp checks.

## Atomic handoff

`csa112_review_bank_transfer(p_actor uuid, p_session_id uuid, p_aal text,
p_key text, p_submission uuid, p_decision text, p_verified_credit jsonb,
p_public_reason text, p_private_notes text)` is service-only.

SQL owner financial_finalization exclusively owns migrations, actual account/
role/MFA checks, self-review deny, exact evidence matching, stable settlement
reuse, transitions/locks, principal-operation idempotency hashes, immutable review
records/audit and transactional grants/notification outbox. Submitted may legally
advance to under_review then final in one audited transaction. Rejection restores
still-payable pending_payment and preserves original evidence for a new linked
submission. Opposing or stale final decisions conflict. Retry of identical
finalized request returns original safe result after current authorization.

RPC safe result `{replayed,submission_id,order_id,status,order_status}` is
validated against requested decision and reduced to response fields
`data.{submission_id,submission_status,order_status}` plus
`meta.{contract_version:bank-review-v1-proposal,request_id,replayed}`.
No settlement IDs, bank evidence, receipt paths, private notes or credentials
leave the handler. Enrollment active is never fabricated from order status.

HTTP 403 ADMIN_PERMISSION_REQUIRED covers revoked role/session/self review;
409 BANK_REVIEW_CONFLICT covers changed idempotency/evidence/dedup;
409 BANK_SUBMISSION_ALREADY_FINALIZED covers stale opposing decisions;
404 BANK_SUBMISSION_NOT_FOUND; 503 SERVICE_UNAVAILABLE retries operational
failures. Input errors 400; oversized 413; unsupported media 415; method 405.
All Auth/RPC redirects are denied, response bodies bounded and timeouts enforced.
Trusted service/origin configuration is copied before async operations.

## Release and verification

Deployed index is hard disabled and returns 503 BANK_REVIEW_UNAVAILABLE.
No environment flag can enable it. Tests use explicit `bankReviewEnabled:true`.
Receipt inspection/resource limits, official destinations/reviewers, retention
and operational acceptance remain pending. No bank/provider/live call, deployment
or production secret/configuration is performed. Release needs separate review.

RED missing handler module; GREEN 44 synthetic handler tests passed. Covers
recorded evidence, exact money, nonfuture calendar dates, forged role metadata,
MFA/provenance, safe current-role/self/state/dedup error mappings, request/response
bounds, redirect policy, replay, opposing result, private note isolation,
configuration stability and hard disablement. Mocked SQL errors do not establish
actual role/race/atomic enforcement; database agent supplies separate actual SQL
and concurrent-session verification. CI and authorized financial review required.
On idempotent replay, submission_status acknowledges the immutable original decision and order_status is omitted. Retrieve current order state separately; a later linked submission may have changed it.
