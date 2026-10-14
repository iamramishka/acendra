# CSA-211: production payment notification verification

Date: 2026-10-15 (Asia/Colombo). Owner: CODEX payment agent.
Preparation status: IN_REVIEW. Operational acceptance: NOT VERIFIED.
Assignment: [CSA-211–216 preparation board](../tasks/CSA-211-216-PREPARATION.md).

The user authorized preparation with dummy targets on 2026-10-15. This protocol prepares verification without configuring production, contacting
providers or creating charges. CSA-211 remains unchecked until actual target
evidence and required financial/release acceptance are recorded. The active
PR #153 application flow is outside this document's scope.

## Two distinct notification boundaries

The PayHere server callback authenticates a settlement before fulfillment.
Student email delivers a notice after financial state has committed. An email,
browser return redirect or receipt upload must never grant course access.

[Webhook entry point](../../supabase/functions/payment-provider-webhook/index.ts)
injects only environment access; its handler defaults to disabled and returns
503 `ONLINE_PAYMENTS_UNAVAILABLE`. No environment enable flag overrides this.
[Email entry point](../../supabase/functions/payment-notifications/index.ts)
always returns 503 `NOTIFICATIONS_UNAVAILABLE`. Configuring secrets alone cannot
activate either boundary. Retain both gates during preparation.

Sources: [webhook contract](../contracts/CSA-102-WEBHOOK.md),
[outbox contract](../contracts/CSA-114-120-ENTITLEMENTS.md),
[payment readiness worksheet](CSA-207-210-SECRETS-PAYMENTS.md).

## Target and prerequisites

Reuse the [hosting target worksheet](CSA-205-206-HOSTING.md):
`DUMMY_PRODUCTION_PROJECT_REF`, `DUMMY_RELEASE_COMMIT`,
`DUMMY_RELEASE_OPERATOR`, `https://courses.example.invalid` and
`https://supabase.example.invalid`. These are unusable placeholders. Never send
requests or deploy using them. Actual identities belong in restricted operator
evidence, with configuration names/version references rather than secret values.

Before execution, record:

1. Reviewed immutable release revision, successful required CI, selected isolated
   production target, named release operator, financial reviewer and concrete
   authorization for the approved validation method. A controlled live charge
   requires its own approved amount, beneficiary, reconciliation and disposition.
2. [CSA-100 sandbox acceptance](../contracts/CSA-100-PAYMENT-ADAPTER.md): full
   checkout, original callback, authenticated Retrieval API association and exact
   LKR amount/reference binding. Historical OAuth/payment-link success is
   insufficient. `npm run payment:sandbox:verify` checks an existing sandbox
   payment's retrieval binding; it does not prove checkout or fulfillment.
3. CSA-210 merchant activation, domain, Retrieval API permissions, production IP
   allowlisting and matching environment credentials, plus reviewed runtime
   configuration/enablement changes. Adapter properties are not implemented
   environment variable bindings. Verify deployed callback configuration retains
   `verify_jwt = false`; provider authentication must still occur in the handler.
4. Reviewed email adapter and verified sender, authenticated scheduler with
   restricted invocation, confirmed authorized validation recipient, provider
   acceptance semantics and deduplication retention covering the retry horizon.
   No provider, SMTP variable or scheduler endpoint is selected by this protocol.
5. Approved monitoring, reconciliation operator and recovery procedure. Live
   failure injection, callback replay and data-changing tests must first pass in
   isolated staging; execute in production only when explicitly included in the
   validation authorization. Never edit financial rows to fabricate evidence.

## Webhook verification protocol

Capture before/after evidence through authorized read-only inspection of the
approved validation order and related attempt, settlement, event, source grant,
audit and outbox. Store identifiers and raw private evidence outside this public
document. Record deployed revision and evidence time in every case.

| Case | Required observation |
| --- | --- |
| Valid success | Checksum plus authenticated retrieval bind stored merchant/environment, attempt/order, unsigned payment reference, RECEIVED status and exact server-priced LKR amount; top-level amount and gross agree without conversion. Financial records, grant, audit and outbox commit together. Current entitlement check determines access. |
| Browser return only | Redirect/success screen produces no settlement or paid grant. |
| Forgery or mismatch | Changed checksum, merchant, order, amount, currency or retrieved payment reference produces no financial mutation and reserves no valid event/settlement identity. |
| Pending/cancel/failure/reversal | Callback receives the documented acknowledgement without payment success fulfillment. Refund/dispute transitions require their separate trusted workflow. |
| Duplicate/concurrent/delayed success | Reverified callback retrieves again; identical settlement produces one financial fulfillment and one source grant. Compare event identity/hash and resulting row counts. Delayed events do not override restrictions or invalidated funding. |
| Second distinct settlement | Outcome is recorded for reconciliation; it does not silently grant another entitlement. Reconciliation owner resolves actual funds under approved policy. |
| Provider/database uncertainty | Sanitized retryable 503; no partial committed financial state. Approved retry either completes atomically or acknowledges prior completion. |
| Invalid transport | Wrong method/type, malformed/duplicate form keys and body over 16 KiB reject according to contract; no grants. |

The Node handler tests use mocks and cannot prove PostgreSQL atomicity, deployed
reachability or actual provider acceptance. Retain separate database transaction
and concurrency evidence from required financial integration checks.

## Student email verification protocol

[Worker](../../supabase/functions/payment-notifications/worker.mjs) claims one
notice per invocation, resolves a current confirmed recipient through trusted
Auth lookup, sends fixed plain text and accepts only `accepted: true`.
Provider acceptance is distinct from inbox delivery: capture provider acceptance
and approved recipient receipt separately; record bounce/nonreceipt as unresolved.

| Case | Required observation |
| --- | --- |
| Committed payment/bank outcome | Correct fixed payment_verified, bank_transfer_approved or bank_transfer_rejected template reaches the confirmed validation recipient; order status agrees with committed state. |
| Privacy | No receipt attachments, bank details, private reviewer notes, storage references or arbitrary HTML. Rejection reason is only the bounded safe public reason. Recipient comes from trusted Auth, not callback or request input. |
| Invalid recipient/unknown type | No mail is sent to unconfirmed, deleted, mismatched or malformed recipient; arbitrary notification types fail safely. |
| Provider outage/timeout | Delivery failure changes outbox state only; payment, order and entitlement remain committed. Adapter respects abort signal; worker timeout is at most 30 seconds. |
| Lost acceptance/acknowledgement | Retry uses identical SHA256 key derived from `acendra-notice:<event_key>` across new leases. Observe provider deduplication and retained acceptance evidence; do not claim exactly-once delivery without it. |
| Lease contention/stale acknowledgement | Five-minute lease and current token govern completion; stale/foreign acknowledgement does not mark sent. Concurrent schedulers do not share a current claim. |
| Exhaustion | At most five attempts; failed delivery retries after `2^attempt_count` minutes, then records fixed `DELIVERY_FAILED`. Alert and reconcile exhausted rows without replaying financial mutations. |

Lease/retry behavior is defined in
[migration 019](../../supabase/migrations/20261012001900_csa116_119_entitlements.sql).
Email and scheduler production wiring are absent, so the observations above are
acceptance requirements, not results already achieved.

## Evidence record template

Copy this record into the restricted release evidence location for each case.
Leave public documentation with redacted references only.

| Field | Value to record |
| --- | --- |
| Case and boundary | Webhook/email case from the matrices above |
| Environment and target | Verified project/domain; production or isolated staging |
| Revision and configuration | Immutable deployed commit, artifact/configuration version references |
| Authorization | Release/validation approval reference; operator; approved scope |
| Time | Start/end timestamps with timezone |
| Preconditions | Approved account/order, initial state and relevant row counts |
| Method | Actual request/workflow used, replay/fault scope and provider evidence reference |
| Expected/observed | Status code, minimal outcome, after-state counts, current entitlement and discrepancy |
| Delivery | Outbox status, attempt/lease outcome, provider acceptance/dedup reference and recipient receipt |
| Privacy | Redaction confirmation; no secret/raw callback/customer payload in public artifacts |
| Reconciliation | Outstanding funds/notices, responsible operator and resolution reference |
| Result/review | PASS/FAIL/NOT RUN; evidence location; financial/release reviewer and acceptance timestamp |

Any failure remains unresolved until reviewed remediation and rerun evidence.
Stop activation on authenticity, amount, authorization or partial-commit failure;
preserve restricted evidence and reconcile in-flight settlements. Never restore
access or repeat a charge merely to make notification tests pass. Mark CSA-211
complete only after required production observations, review and formal acceptance.

## Fresh local preparation verification

On 2026-10-15 the isolated `work/csa211` checkout at base `7916c6e` ran:

```powershell
node --test supabase/functions/_shared/payments/*.test.mjs supabase/functions/payment-provider-webhook/*.test.mjs supabase/functions/payment-notifications/*.test.mjs tool/csa201_notification_recovery.test.mjs
```

Result: exit 0; 78 tests passed, 0 failed, 0 skipped. Synthetic signatures,
injected provider/database responses and delivery collaborators verify callback
binding/forgery, disabled defaults, deterministic retries, safe templates,
recipient validation, timeout and lost acknowledgement handling. Source and
local link inspection plus `git diff --check` validate this document.
No real provider, production database, deployed Deno endpoint, scheduler or inbox
was exercised. No live verification or CSA-211 completion is claimed.
