# CSA-004: Payment gateway and currency

Date: 2026-10-11 (Asia/Colombo)
Status: Selection confirmed by project owner; technical/merchant readiness unverified
Owner: CODEX (documentation); project owner (commercial decision)

## Recorded decision

The owner replied: "Sri Lanka, LKR , Payhere payment gateway".

- Business country: Sri Lanka.
- Primary billing currency: LKR.
- Online payment provider: PayHere.
- Manual bank transfer remains the second payment method required by the SRS.
- Customer countries beyond Sri Lanka and cross-border acceptance remain open.
- No claim is made that a merchant account is active, a pricing plan purchased,
  a business registration verified, or live payments tested.

This resolves SRS.md DEC-001 / PLAN.md DEC-001 (provider) and SRS.md
DEC-002 / PLAN.md DEC-002 (currency). Country information does not approve
every territory covered by either document's DEC-003.

## Provider evidence

Official sources checked on 2026-10-11:

- [PayHere Checkout API](https://support.payhere.lk/api-&-mobile-sdk/checkout-api):
  hosted form checkout, server callback, server-generated checkout hash and
  notification checksum verification are documented. Return redirects carry no
  payment status; callbacks are form-encoded. Only verified success status `2`
  can support a payment grant.
- [PayHere application process](https://support.payhere.lk/application-process):
  merchant onboarding and supporting business/bank information must be completed.
  Eligibility and activation must be confirmed for this business.
- [PayHere fees](https://www.payhere.lk/fees/): Lite currently lists no monthly
  fee, 3.30% processing, LKR 50,000 per payment and LKR 200,000 per month;
  Plus lists LKR 3,990/month, 2.99%, LKR 250,000/payment and LKR 3,000,000/month.
  An education plan is also listed. Rates, extra fees and eligibility require
  confirmation before selecting a plan. No plan is selected by this document.

## Proposed implementation requirements

These supplement FR-CHECKOUT-001..010, FR-PAY-001..014, BR-001..016 and
NFR-SEC-001..012. Existing backend authority requirements remain mandatory.

1. Store the server-priced order and immutable LKR amount before issuing
   checkout data. Represent money exactly; render provider amounts with two
   decimal places. Reject unsupported currency and client price overrides.
2. Generate the PayHere checkout hash exclusively on the trusted backend.
   Domain-specific merchant secrets never enter Flutter builds or client logs.
3. Verify callback checksum according to the provider protocol, then compare
   merchant, environment, order, amount and currency to the stored payment
   attempt. Do not trust unsigned metadata for student/course identity.
4. Verify the provider reference and its association with the payment attempt.
   The documented checksum does not cover every callback field, including
   payment_id. Do not treat that field alone as authenticated proof or as the
   only replay defense. Finalize the provider retrieval/reconciliation contract
   and test its availability before financial implementation is accepted.
5. Enforce deduplication and legal transitions in one database transaction:
   persist verified payment, move the eligible order to paid, grant entitlement
   at most once, and append audit evidence. Serialize against bank approval on
   the same order. A second real payment becomes a reconciliation case.
6. Unknown, pending, failed, cancelled, mismatched or invalid callbacks never
   grant access. Delayed success, chargebacks and refunds require explicit
   transition rules aligned with CSA-006; they must not silently reactivate
   revoked entitlements or rewrite historical evidence.
7. The return page reads the authenticated user's backend order status. It may
   display pending while the callback is delayed; a redirect cannot mark paid.
8. Separate sandbox and production credentials/events. Store only required,
   redacted evidence; never retain card credentials or secrets.

## Acceptance and handoff

| Gate | Required evidence | Current result |
| --- | --- | --- |
| Provider and currency selection | Owner confirmation | Confirmed in this chat on 2026-10-11 |
| Merchant readiness | Activation, approved domain, matching merchant bank account, chosen plan limits | Not verified |
| Valid sandbox payment | Verified callback -> one payment and entitlement; return page agrees | Not run |
| Forgery/mismatch | Bad checksum, merchant, environment, amount, currency and order denied | Not run |
| Retry/concurrency | Replays, changed unsigned fields, simultaneous callbacks and bank approval do not duplicate grants | Not run |
| Failure/recovery | Pending/cancel/failure/timeout and delayed callback handled without false success | Not run |
| Reversal | Agreed CSA-006 refund/chargeback behavior and reconciliation tested | Policy pending |

The selection portion of CSA-004 is complete. Its repository task stays
IN_REVIEW until documentation acceptance is recorded. Implementation and
production readiness are separate downstream tasks, not implied by selection.
