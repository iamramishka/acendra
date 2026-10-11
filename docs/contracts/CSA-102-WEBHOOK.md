# CSA-102/103 — Verified provider notification contract

Status: IN_REVIEW. Owner: CODEX / verified_webhook. Issue: #77.

`payment-provider-webhook` accepts POST `application/x-www-form-urlencoded`
(optionally charset=utf-8). It requires no student JWT: provider authenticity
comes from PayHere checksum validation followed by authenticated retrieval.
The integration owner must register `verify_jwt = false` for this callback.
No Origin, browser return URL, client role or client-provided price grants access.

## Release gate

The deployed index passes no enablement or provider configuration and always
returns 503 ONLINE_PAYMENTS_UNAVAILABLE. No environment flag overrides it.
CSA-100 successful real sandbox checkout/callback/retrieval remains unavailable
as confirmed by the owner. A separately reviewed release change must establish
readiness and securely inject matching adapter configuration. Synthetic tests
inject `onlinePaymentsEnabled: true` and `providerConfig`; they prove local
behavior only. No deployment or live provider call is performed here.

## Processing

1. Bound streamed request bytes to 16 KiB, validate UTF-8 and percent escapes,
   reject all duplicate keys (including ignored card/customer metadata), control
   characters and missing required fields. Provider order ID is attempt UUID.
2. Service-only `csa102_lookup_payment_attempt(p_provider_order_id)` supplies
   stored trusted attempt terms, including canonical decimal-string minor units,
   merchant and environment. Never derive these from callback metadata.
3. Existing CSA-100 adapter validates checksum and exact order/scope/LKR amount.
   Pending/cancel/failure/refund/chargeback notifications receive HTTP 200 without
   mutation; they never revoke/reactivate access. Reversal policy remains separate.
4. Successful checksum evidence requires authenticated retrieval through the
   same adapter instance, binding unsigned payment ID, order, status RECEIVED,
   amount, gross and non-converted LKR currency to stored attempt terms.
5. Only independently retrieved success invokes atomic service RPC below.
   No invalid notification reserves an event or external settlement identifier.

## Atomic handoff

`csa104_finalize_payment` arguments:

- `p_attempt_id`: stored attempt UUID; `p_merchant`, `p_environment`: stored scope.
- `p_event_id`: `payhere:received:<retrieved payment ID>`.
- `p_payload_hash`: lowercase SHA256 of canonical JSON array
  `[provider, merchantId, environment, attemptId, orderId, paymentId,
  amountMinor, currency, "RECEIVED"]`.
- `p_external_settlement_id`: independently retrieved payment ID string.
- `p_amount_minor`: exact decimal integer string, serialized for PostgreSQL bigint.
- `p_currency`: LKR.
- `p_confirmed_at`: retrieval observation timestamp (not claimed provider payment time).
- `p_evidence_reference`: `payhere:authenticated_retrieval:<payment ID>`.

Database owner CSA-104/105 owns all financial transitions, event identity,
reconciliation, concurrent serialization and atomic entitlement grants. Handler
acknowledges outcomes `processed`, `duplicate`, `reconciliation_required` with
HTTP 200. A second successful payment must be recorded for reconciliation by
that RPC, never silently grant another entitlement.

HTTP 400 means invalid notification/settlement; 413 oversized notification;
415 media type; 405 method; 503 configuration/provider/database failure is
retryable. Responses contain stable generic codes only, never provider payloads,
secrets or internal database messages. No raw form/card/customer metadata is
logged or persisted. Retries reverify and retrieve settlement again; canonical
hash excludes raw form metadata and observation timestamps so replay is stable.

## Verification and remaining gates

RED: handler test initially failed with missing handler module. GREEN: 35 handler
security/workflow tests plus 14 existing adapter tests passed using synthetic
protocol signatures and mocked network responses. Tests cover forged checksum,
exact-money/currency/scope mismatches, changed unsigned payment reference,
duplicate metadata, malformed/oversized bodies, pending/reversal no-write,
retrieval mismatches, deterministic replay, concurrent handler calls, database
failure sanitization, reconciliation acknowledgement and default disablement.
Database atomicity/races are verified separately by CSA-104/105, not these mocks.
Real sandbox provider acceptance, authorized financial review, CI and release
approval remain required. No production readiness or completed acceptance claimed.
