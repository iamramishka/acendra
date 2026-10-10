# CSA-005: Bank transfer verification policy

Date: 2026-10-11
Status: APPROVED baseline - project owner accepted on 2026-10-11; operational gates remain
Requirements: FR-BANK-001..018, FR-APAY-001..008, FR-ENROLL;
SECURITY bank/upload rules; DATABASE_DESIGN review/state rules;
docs/API_CONTRACTS.MD upload, review and idempotency contracts.
Confirmed currency: LKR. Official beneficiary bank details remain unspecified.

## Order and private receipt submission

The backend creates an owned payable order with immutable course, exact amount,
currency, reference and versioned official bank destination. Production cannot
use placeholder bank details. Upload completion never grants paid access.

Approved upload policy: JPEG, PNG or PDF, at most 5,242,880 bytes (5 MiB), matching
the existing API proposal. Server-side validation checks actual size, extension,
MIME, file signature and parseability. Reject unsupported, malformed, encrypted
or unsafe files that cannot be inspected. Approve scanner/safe renderer and
image/PDF resource limits before production; failed inspection is not reviewable.

Use server-generated paths in private bank-receipts storage. Capabilities are
scoped to the order/submission and never logged. Check the provider's actual
expiry behavior. Deny public listing, arbitrary paths and finalized evidence
overwrites. Finalization verifies the stored object and association, then
atomically marks the submission SUBMITTED and order PENDING_VERIFICATION.
Only one active submission may exist per order.

## Independent credit verification

A currently authorized finance reviewer checks the business-controlled bank
portal, bank statement or approved authenticated bank feed for settled credit.
A receipt or `bank_credit_confirmed=true` is not independent technical proof;
the latter is the authorized reviewer's recorded assertion.

Record destination account identifier, independently confirmed bank transaction
identity, amount, currency, settlement date/source, reviewer and notes. Match
the actual credit to the order's destination, exact LKR amount and reference.

Approved standard path: no FX conversion, underpayment tolerance, fee deduction,
split-transfer aggregation or automatic overpayment approval. Missing/truncated
references, unsettled funds and other mismatches remain UNDER_REVIEW for
documented exception handling. A sender-name mismatch alone is not fraud.
Third-party payments/exceptional matches require an approved evidence policy.

## Approval and state transitions

Use the approved CSA-003 permission policy, including MFA and no own-purchase approval.
All financial writes occur through one trusted transactional operation with a
consistent lock order. Recheck permissions, state, identity and settlement reuse
inside that operation. Notifications occur after commit and are retryable work.

| Trigger | Submission transition | Order transition | Required effect |
| --- | --- | --- | --- |
| Valid finalized upload | AWAITING_RECEIPT -> SUBMITTED | PENDING_PAYMENT -> PENDING_VERIFICATION | No entitlement |
| Authorized review begins | SUBMITTED -> UNDER_REVIEW | Remains PENDING_VERIFICATION | Audit reviewer/action |
| Verified standard approval | UNDER_REVIEW -> APPROVED | PENDING_VERIFICATION -> PAID | Atomically consume settlement, record payment/review/audit, create authorized grant, enqueue notice |
| Reasoned rejection | UNDER_REVIEW -> REJECTED | PENDING_VERIFICATION -> PENDING_PAYMENT if still payable | No grant; preserve evidence |
| Resubmission | New AWAITING_RECEIPT record; prior REJECTED retained | Remains PENDING_PAYMENT until valid upload | New linked evidence, never rewrite rejection |
| Identical finalized retry | No transition | No transition | Return original safe result |
| Opposing/stale finalization | No transition | No transition | Conflict; no partial writes |

These uppercase SRS states map to the lowercase database/API states; this
document does not rename enum values. Approval from SUBMITTED must first take
the legal review transition in the same trusted operation if supported.

A reliable bank transaction identity scoped to account/provider can fund only
one order. Student-entered references and receipt hashes are not reliable unique
settlement identities. If a bank lacks stable IDs, approve a reconciliation
identity scheme before using it. Similar receipt/reference flags remain optional
heuristics and do not replace mandatory settlement deduplication.

Use actor/operation-scoped idempotency keys and request hashes. Identical retries
return the original result; changed payload reuse returns IDEMPOTENCY_CONFLICT.
Opposing decisions return the existing bank conflict/finalized error. Concurrent
approve/approve, approve/reject and online-payment/bank-approval requests must
produce at most one order fulfillment. A second actual payment is a finance
reconciliation case, not a second grant. Transaction failure rolls back all
payment, grant and audit changes; notification failure preserves committed state.

## Rejection, disputes and privacy

Approved resubmission policy: permit a new receipt on the same still-payable
order, preserving the rejected record. Do not revive cancelled, paid or refunded
orders. Keep student-safe rejection reasons separate from internal notes.

Students request review privately using order/submission IDs and new evidence.
A different authorized reviewer handles disputes/exceptional adjustments.
Reconsideration creates linked new evidence; it does not rewrite history.
Corrections after approval, refunds and revocations use the separately approved
CSA-006 workflow. Never silently turn a paid order into a rejected order.

Only authorized finance and the submitting owner under the approved CSA-003 safe-view
policy may access receipt bytes. Status responses omit private paths/internal
notes. No receipt attachments in email or capability URLs in logs. Define
separate retention/deletion rules for receipts, settlement evidence, audits and
abandoned uploads before production acceptance. No legal period is invented here.

## Acceptance scenarios

- Valid upload remains pending and protected content stays denied.
- Cross-user access, arbitrary paths and finalized evidence overwrite fail.
- Oversize, MIME spoofing, malformed/unsafe files and missing objects fail.
- Stale/forged roles and own-purchase approval fail without state changes.
- Unconfirmed credit and amount/currency/destination mismatch cannot be approved.
- One bank credit cannot fund two orders, including concurrent requests.
- Identical retries succeed once; changed payload and opposing decisions conflict.
- Concurrent bank and online verification produce one fulfillment.
- Injected payment/grant/audit failure rolls back every financial write.
- Notification failure preserves approved payment and allows later delivery.
- Resubmission preserves rejected evidence and keeps internal notes private.
- Stale receipts cannot revive paid/cancelled/refunded orders or revoked access.

## Outstanding operational gates

The owner approved upload types/size, strict matching, independent review/MFA,
no self-approval and same-order resubmission. Still required before production:
receipt inspection technology/resource limits, any exceptional matching policy,
named finance/alternate reviewers, review/dispute targets and contacts, official
bank destination, retention and CSA-006 refund/entitlement rules.
No live bank access, receipt processing or implementation tests were performed.
