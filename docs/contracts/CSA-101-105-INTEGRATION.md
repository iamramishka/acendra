# CSA-101–105 integration contract

Status: implementation interface agreed by CODEX root and task owners on
2026-10-11 under the owner's parallel task authorization. Not provider acceptance.
Existing approved CSA004/006/008 business/security policy remains authoritative.

## Service-only database boundary

- csa101_initialize_checkout(p_actor uuid,p_session_id uuid,p_aal text,p_key text,
  p_order uuid,p_merchant text,p_environment text): current authenticated owner,
  stored online pending order, scoped idempotent attempt initialization. Returns
  replayed plus adapter-compatible stored attempt. The PayHere orderId is the
  attempt UUID; internal order_id is separately retained. Same active attempt
  is reused for matching merchant/environment even with another request key.
- csa102_lookup_payment_attempt(p_provider_order_id text): minimal stored attempt
  shape; service-only, no public/client table grants or untrusted price/scope.
- csa104_finalize_payment(p_attempt_id uuid,p_merchant text,p_environment text,
  p_event_id text,p_payload_hash text,p_external_settlement_id text,
  p_amount_minor bigint,p_currency text,p_confirmed_at timestamptz,
  p_evidence_reference text): trusted retrieved evidence only, never raw callback.
  Returns outcome processed/duplicate/reconciliation_required, order_id,event_id.

SQL owner publishes exact output shapes/errors in task contract. Shared contract
changes require acknowledgement by affected workers before integration.

## Evidence and HTTP boundaries

Checkout derives email from verified Auth; bounded contact fields are billing
metadata, never actor/role/amount/provider identifiers and are not persisted here.
Webhook validates bounded form/checksum using CSA100 then independently retrieves
exact matching settlement before any event reservation/finalization. Canonical
retrieval-evidence SHA256 excludes observation time so replay remains stable.
Event identity: payhere:received:<independently retrieved payment identity>.
Raw notification/provider/card data and credentials are never stored or logged.

Finalization commits settlement/event/attempt/order/enrollment source/projection,
minimal audit and durable notification outbox together; delivery is downstream.
Extra/late verified settlements are preserved for reconciliation without repeated
or revived access. Service credentials never reach clients. Provider calls occur
outside SQL transactions. Application roles cannot invoke these mutations.

Both deployed entry points remain hard disabled with no environment enable flag.
Test-only injected enablement verifies underlying behavior. Real sandbox checkout,
callback/retrieval and merchant readiness are release/acceptance gates; CSA100
remains blocked. No production enablement is authorized by these task assignments.
