# CSA-168 enrollment administration

Owner: CODEX. Issue: #106. Date: 2026-10-12 Asia/Colombo. Status: IN_REVIEW.

## Enrollment viewing

Canonical endpoint `POST /functions/v1/admin-enrollments` accepts exactly
`{"user_id":"uuid","after_id":null,"limit":20}`. Limit is an integer 1–50;
`after_id` is null or the last enrollment UUID returned in `next_after_id`.
The query always targets one student, never a public student directory.

Verified nonanonymous Auth identity, current AAL2 session and current super-admin
role are required. Actor/session/AAL are derived only after Auth token verification.
The service-only `csa168_list_enrollments` RPC rechecks authority while holding the
existing role mutation lock. Finance and content-manager authority alone deny access.
Responses are no-store and contain bounded `items` plus `next_after_id` (null at end).
Each item contains enrollment_id, course_id, projection_status, granted_at,
expires_at and has_access. Stored projection_status may lag time-based expiry;
has_access evaluates the current accepted grant/restriction predicate and beneficiary
account eligibility. It is administrative information, never a content-delivery token.
No names, email addresses, reasons, bank evidence, original storage paths or financial
records are returned. An unknown student produces an empty list.

UUID keyset pagination is deterministic for existing rows. Concurrent newly inserted
UUIDs before the cursor can be missed until a fresh traversal; no snapshot guarantee
is claimed. This read operation does not create an audit/outbox mutation or require
an idempotency key.

## Audited changes

`admin-entitlements` remains the canonical accepted mutation contract in
[CSA-114-120-ENTITLEMENTS.md](CSA-114-120-ENTITLEMENTS.md). Grant creates complimentary
sources only. Explicit grant/course/account revoke scopes and separate restriction
release preserve independent grants and payment history. Current super-admin AAL2,
independent beneficiary, reason, idempotency and immutable audit remain enforced by
existing RPCs. Legacy API_CONTRACTS endpoint examples are superseded for this task
by that implemented canonical boundary; no ambiguous enrollment-ID revoke adapter
is added. Consumers must choose the intended explicit scope.

Both deployed indexes remain hard disabled pending reviewed production activation.
Local enabled handler seams support tests; dev integration is not deployment approval.
Refund execution, source mutation redesign, email provider activation and student
management UI are outside this task.
