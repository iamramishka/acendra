# CSA-003: Roles and permissions

Date: 2026-10-11
Status: APPROVED baseline - project owner accepted on 2026-10-11; implementation unverified
Requirements: SRS section 4; FR-ADMIN, FR-STUDENT, FR-APAY, FR-ENROLL;
SECURITY sections on authorization; DATABASE_DESIGN role grants/course staff.

## Approved permission matrix

Own means authenticated ownership. Scoped means a current course assignment
and allowed operation. Explicit means a trusted backend permission check,
never unrestricted database access. Staff purchases follow student rules.

| Operation | Guest | Student | Content manager | Finance admin | Super admin |
| --- | --- | --- | --- | --- | --- |
| Published catalog/approved public metadata | Yes | Yes | Yes | Yes | Yes |
| Profile, orders, status, progress | No | Own | Own | Own | Own |
| Checkout/receipt submission | No | Own | Own | Own | Own |
| Paid learning content | No | Own entitlement | Own entitlement | Own entitlement | Own entitlement |
| Draft creation | No | No | Backend assigns creator | No | Explicit |
| Authoring preview, curriculum, uploads | No | No | Scoped | No | Explicit |
| Price changes, publish, archive | No | No | No | No | Explicit |
| Receipt evidence | No | Own safe view | Own safe view | Relevant review cases | Explicit finance access |
| Bank approval/rejection | No | No | No | Independent verification | Explicit finance operation |
| Financial reports/metrics | No | No | No | Minimum necessary | Explicit |
| Other student search/management | No | No | No | Related payer lookup only | Minimum necessary |
| Manual enrollment grant/revocation | No | No | No | No override | Explicit, reason and audit |
| Roles/course staff assignments | No | No | No | No | Explicit, reason and audit |
| Bank destination/system configuration | No | No | No | No | Explicit, audit and bank-change review |
| Audit review | No | No | No | Relevant finance history | Explicit |
| Rewrite/delete audit history | No | No | No | No | No |

## Approved policy choices

The project owner approved the following policy choices on 2026-10-11:

1. Content managers author assigned courses; only super admins publish, archive
   or change prices in MVP. Authoring previews do not create student access.
2. One independent finance reviewer may approve an ordinary bank payment.
   No reviewer, including a super admin, may approve their own purchase.
   Name an alternate reviewer before launch. No invented dual-review amount
   threshold applies. Bank beneficiary changes need a second authorized human
   review before activation.
3. Manual grants/revocations require super-admin authority, a reason, idempotency
   and an immutable audit entry. Complimentary access uses an admin grant source;
   it never fabricates payment evidence. Expiry/refunds follow CSA-006.
4. Deny self-role changes, self-issued complimentary grants and removal of the
   last active super admin. Bootstrap the first admin through a controlled
   operator procedure outside public signup.
5. Require MFA for finance and super-admin production operations.
6. Resolve current unrevoked roles and course assignments on every sensitive
   request, including requests carrying an older still-valid session token.
7. A student may see their own validated receipt through authorized private
   delivery, but never internal bank evidence, reviewer notes or storage paths.

Multiple roles add explicit capabilities; they do not remove self-approval or
verification restrictions. Super-admin authority never bypasses bank credit
verification, enrollment checks or audit controls.

## Enforcement and acceptance

Derive actor identity from verified authentication. Check account eligibility,
current roles, operation, resource and allowed fields. Enforce RLS and grants
alongside API checks. Keep privileged credentials and RPC access server-side.
Filter dashboard aggregates on the backend as well as individual rows.

| Case | Required result |
| --- | --- |
| Anonymous or student A requests B's records/media | No foreign rows, metadata or bytes through API/database/storage |
| Student supplies role/admin fields | No privilege gained |
| Content manager A edits/previews course B | Denied; no writes |
| Content manager submits price/publish/staff fields | Denied; no hidden field escalation |
| Finance edits curriculum, roles or bank destination | Denied |
| Content-only role requests receipt/revenue aggregates | Denied; no sensitive counts |
| Reviewer approves own purchase | Denied; no payment/grant mutation |
| Role/course assignment revoked after token issue | Next sensitive request denied |
| Self-role change or last-admin removal | Denied |
| Entitlement expired/revoked/wrong course | Protected access denied |
| Concurrent approval/rejection or repeated grant | One legal final result; no duplicate grant |
| Injected privileged transaction failure | No partial payment, grant or audit write |

Required downstream contract alignment: clarify authorized student
search, manual grants, role self-modification and review separation in
docs/API_CONTRACTS.MD. That file is not changed by this review batch.
No permission implementation or negative test execution is claimed here.
