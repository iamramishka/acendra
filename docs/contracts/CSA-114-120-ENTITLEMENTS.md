# CSA-114/116–120 backend contract

Owner CODEX. Original date 2026-10-12 (Asia/Colombo). Issue #85. Status reconciled 2026-10-16: CSA-114/116/117/118/120 development scope accepted via merged PR #86; CSA-119 operational delivery IN_REVIEW.
Originally stacked on PR #84; both PR #84 and PR #86 are now merged into dev. Production payment/receipt and live email gates remain intact. This status update changes no RPC or worker contract.

## Access verification

Authenticated RPC `csa117_verify_entitlement(p_course uuid)` returns a boolean
for the verified caller only. It resolves `auth.uid()` and the JWT's verified
session/AAL, then rechecks current Auth account and session state. Arbitrary
actor/session parameters are absent. Service-only
`csa117_check_entitlement(p_actor,p_session_id,p_aal,p_course)` provides the same
check to trusted protected-delivery callers after they verify the exact token.

Valid access requires a surviving matching grant, current validity timestamps,
paid funding and matching settlement for purchases, and no unreleased course or
account restriction. Publication status does not remove purchased access.
An enrollment projection alone never authorizes delivery. Every protected
delivery operation must call this boundary before releasing resources; this
batch supplies the boundary, not the subsequent learning/PDF implementation.
Already delivered bytes cannot be recalled by revocation.

## Manual administration

`POST /functions/v1/admin-entitlements` requires a verified nonanonymous Auth
token, current AAL2 session, current super-admin role, exact approved origin
when supplied, and `Idempotency-Key` matching `[A-Za-z0-9._:-]{1,128}`.
It is hard disabled in the deployed entry point pending reviewed activation.
No environment variable enables it. JSON bodies are limited to 8192 bytes.

Accepted exact request shapes:

```json
{"action":"grant","user_id":"uuid","course_id":"uuid","reason":"bounded reason","expires_at":null}
{"action":"revoke","user_id":"uuid","course_id":"uuid","grant_id":"uuid","scope":"grant","reason":"bounded reason"}
{"action":"revoke","user_id":"uuid","course_id":"uuid","grant_id":null,"scope":"course","reason":"bounded reason"}
{"action":"revoke","user_id":"uuid","course_id":null,"grant_id":null,"scope":"account","reason":"bounded reason"}
{"action":"release","restriction_id":"uuid","reason":"bounded reason"}
```

Grant expiry may be an explicit future ISO timestamp for complimentary access.
Purchased access remains lifetime. Manual grants are complimentary sources;
they cannot fabricate payment or refund evidence. Self-beneficiary operations
are denied. Finance/content roles cannot override access manually.

The handler verifies `/auth/v1/user` before decoding claims and forwards only
that verified actor/session to the service-only grant/revoke/release RPCs.
SQL rechecks authority inside the role mutation lock. Actor/operation/key scope
and payload hashes govern replay; changed payloads conflict. Each mutation,
audit, idempotency result and safe notice commits together. Revocation reasons
remain in restricted audit/source history rather than outgoing email payloads.

Source-specific invalidation preserves independent grants and cannot be undone.
Broader restrictions are append-only records; releases are separate immutable
records and do not restore invalidated grants. Existing legacy revoked enrollment
projections migrate conservatively to course restrictions with a system/null
actor, retaining their reason. New verified purchases cannot bypass restrictions.

Common errors: `AUTH_REQUIRED`, `MFA_REQUIRED`, `ADMIN_PERMISSION_REQUIRED`,
`INVALID_REQUEST`, `ENTITLEMENT_CONFLICT`, `ENTITLEMENT_NOT_FOUND`,
`SERVICE_UNAVAILABLE`, `ENTITLEMENT_ADMIN_UNAVAILABLE`. Responses are no-store;
private database/provider diagnostics are omitted.

## Grant projection and lock ordering

Existing online and bank fulfillment RPCs retain settlement/order/source/audit
atomicity. New grant triggers refresh the projection from the shared validity
predicate. Surviving sources reactivate ordinary revoked access; restrictions
remain authoritative. Pure complimentary expiry projects `expired`, not revoked.
No worker refresh is necessary to deny expired access. Checkout's duplicate-access
check uses the same predicate through an additive replacement migration.

Financial operations keep settlement identity → order → attempt/submission →
beneficiary/course ordering. Manual changes hold the existing role authority lock,
then actor/session/idempotency and beneficiary/course locks; they do not acquire
funding-order locks. Course lists for account restrictions are sorted. Concurrent
purchases may finish financially but cannot authorize access through a restriction.

## Postcommit transactional notifications

Service-only `csa119_claim_notifications(p_limit)` selects due rows with
`FOR UPDATE SKIP LOCKED`, issues a unique token, and leases for five minutes.
Expired leases are reclaimed, at most five attempts. Completion requires the
current unexpired token; stale/foreign acknowledgements do nothing. Retry delay
is `2^attempt_count` minutes. Exhausted failures are recorded as `failed` with
the fixed safe `DELIVERY_FAILED` code. Delivery never changes financial records.

`payment-notifications/service.mjs` connects these RPCs to the worker and resolves
the current confirmed recipient from trusted Auth admin lookup. The worker claims
one event per invocation, uses fixed plain-text templates, filters public rejection
reason, and supplies a 30-second abort signal. Its trusted provider adapter must
respect cancellation, confirm acceptance, and deduplicate the stable SHA256 event
key across new leases. Acceptance followed by a lost acknowledgement can replay;
exactly-once email is not claimed without provider deduplication.

The HTTP entry point remains hard disabled. A reviewed email provider adapter,
verified sender, deduplication retention, trusted authenticated scheduler and
operational monitoring are release dependencies; none is guessed or configured.
Synthetic delivery tests prove the worker seam, not actual production email.
Bank rejection/approval remains visible through existing own-order RLS/status.

Refund/dispute settlement execution is outside this batch. No client-provided
refund flag can invalidate funding or alter financial state.
