# Admin payment-list reporting — contract PROPOSAL

Status: **PROPOSED / IN_REVIEW. Owner approval pending. Not approved, not implemented.**
Prepared by: CLAUDE (docs only). Backend owner if approved: CODEX (payment/reporting backend).
Task ID: not assigned (placeholder `CSA-PAYLIST-TBD`); no GitHub Issue exists yet. Resolves finderror finding 004
(and enables 013/014/015/016 to be satisfied with live data). Modeled on
[CSA-158-172-REPORTING.md](CSA-158-172-REPORTING.md).

This document changes no shared contract. It adds no migration, Edge Function or Flutter code, and does not edit
`docs/API_CONTRACTS.MD`, `TASKS.md`, router, theme or `pubspec.yaml`. If approved, the owner/Codex must
record the contract in `docs/API_CONTRACTS.MD` through the normal shared-file process.

## 1. Problem

`AdminPaymentRepository` defaults to `UnavailableAdminPaymentRepository`
([admin_payment_repository.dart](../../lib/features/admin/data/repositories/admin_payment_repository.dart)) because no
trusted endpoint lists payments. The admin dashboard payment queue and the Payments page therefore show
"unavailable" (correct fail-closed behaviour, not a bug in the UI). `StubAdminPaymentRepository` is test-only and
must stay so. Existing reporting functions return only aggregates (`admin-dashboard-stats`,
`admin-financial-report`); `bank-transfer-read` returns a bounded 100-row pending bank queue only and is not a
general payment list.

## 2. Function

- Edge Function: `admin-payment-list` (POST `/functions/v1/admin-payment-list`).
- Restricted RPC (service_role only): `public.<csa-id>_admin_payment_list(p_actor, p_session_id, p_aal, ...)`, final
  name decided by the migration owner.
- Read-only. No table/view grants to `anon`/`authenticated`; no financial or access mutation; no new statuses.
- Hard-disabled on first deploy (`enabled !== true` returns 503 `REPORTING_UNAVAILABLE`), like the reporting
  handlers. Activation is a separate reviewed release step.

## 3. Authentication and authorization

Same boundary as `admin-dashboard-stats` / `admin-financial-report`:

1. Verified Supabase Auth user from the bearer token (`/auth/v1/user`); anonymous users rejected; JWT `sub`,
   `role=authenticated`, `session_id`, `aal` claims validated.
2. Origin allowlist (explicit comma-separated env var; unset denies all browsers); strict CORS preflight;
   `Cache-Control: no-store`; JSON content type; request body size-limited (8 KiB); response size-limited.
3. SQL RPC rechecks inside PostgreSQL: live account, session (`csa108_require_session`), AAL and **unrevoked**
   roles, under role mutation lock `610061`.
4. Allowed roles: `finance_admin`, `super_admin`, both requiring current **AAL2**.
   `content_manager`, students and anonymous callers get the whole call denied (403 `ADMIN_PERMISSION_REQUIRED`).
   Payment data has no content-only subset, so there is nothing to "omit"; the call fails closed instead.
5. The Flutter route guard and hidden navigation are not authorization.

## 4. Request

Exactly one of two shapes; unknown or missing keys return 400 `INVALID_REQUEST`.

List mode:

```json
{
  "mode": "list",
  "page_size": 20,
  "cursor": null,
  "status": null,
  "method": null,
  "from": null,
  "to": null,
  "order_number_prefix": null
}
```

| Field | Type | Rules |
| --- | --- | --- |
| `mode` | string | `"list"` |
| `page_size` | int | 1..50, default 20 (50 matches `admin-directory`) |
| `cursor` | string or null | Opaque, server-issued, ≤ 512 chars, bound to the filter set and `as_of` (see §8). Tampered, replayed-with-different-filters, or expired cursors return 400 `INVALID_REQUEST`. |
| `status` | `pending` \| `processing` \| `approved` \| `rejected` or null | The mapped payment status in §6. |
| `method` | `online` \| `bank_transfer` or null | Canonical API values from `API_CONTRACTS.MD` §13.7. |
| `from`, `to` | `YYYY-MM-DD` or null | Inclusive Asia/Colombo calendar dates on order `created_at`; both or neither; `to ≥ from`; span ≤ 366 days, as in `admin-financial-report`. |
| `order_number_prefix` | string or null | 1..40 chars, `[A-Za-z0-9-]` only, case-insensitive prefix match on `orders.order_number`. No substring or email search in v1 (see Q4). |

Detail mode (backs `getPayment`):

```json
{ "mode": "detail", "payment_id": "<uuid>" }
```

Currency is always `LKR` (the schema enforces it); it is returned, not requested. Free-text search beyond the
order-number prefix is not part of v1.

## 5. Response

Standard envelope `{"data": {...}}` / `{"error": {"code": "..."}}`, `Cache-Control: no-store`.

List:

```json
{
  "data": {
    "items": [
      {
        "payment_id": "uuid",
        "order_id": "uuid",
        "order_number": "string",
        "course_id": "uuid",
        "course_title": "string",
        "amount_minor": "499900",
        "currency_code": "LKR",
        "method": "bank_transfer",
        "status": "processing",
        "created_at": "2026-10-15T07:45:00Z",
        "updated_at": "2026-10-15T08:10:00Z",
        "settled_at": null
      }
    ],
    "next_cursor": null,
    "counts": { "pending": "3", "processing": "2", "approved": "40", "rejected": "5", "total": "50" },
    "as_of": "2026-10-18T05:00:00Z",
    "count_as_of": "2026-10-18T05:00:00Z",
    "count_basis": "current_snapshot"
  }
}
```

Field rules:

- `payment_id`: the identifier the Payments page and the dashboard queue both use. **Proposed value is the order id
  (`orders.id`)**: one payment row per order. `payment_attempts` rows are retries of one order and are not
  separate payments; bank submissions are evidence for one order. `order_id` and `payment_id` are therefore equal
  in v1 but both are returned so a future split does not break the wire format (Q1).
- `amount_minor`: exact decimal string of `orders.amount_minor` (bigint), never a JSON number, never `double`.
  Zero allowed. `currency_code` is `"LKR"`.
- `course_title`: `orders.course_title_snapshot`, not the live course title, so history stays stable.
- `status`: see §6. Always one of the four values; unknown backend states fail the request closed (§9), they are
  not defaulted to `pending`.
- Timestamps are UTC ISO-8601. `settled_at` is `verified_settlements.confirmed_at` when a verified settlement
  exists, else null. `updated_at` is `orders.updated_at`.
- `counts`: decimal strings, one per status plus `total`, computed in the **same statement/snapshot** as the page
  (§8) over the `method`/date filters and the fixed `created_at <= as_of` membership cutoff, but **not** the
  `status` filter. Each list response supplies the page and its tab badges from one current snapshot (findings
  013/014). A caller using the dashboard with no filters and no cursor gets global counts from the same field;
  the dashboard and Payments page share that response when they need identical counts.
- `as_of`: fixed order-creation cutoff established on the first list request and bound into subsequent cursors.
  It limits membership, not the age of the status facts. `count_as_of` is the current request's
  `statement_timestamp()` for both its live items and counts. They are equal on page 1; later pages retain
  `as_of` and advance `count_as_of`. `count_basis: "current_snapshot"` refers to `count_as_of`.
- Omitted unconditionally, never returned as null/empty (see §10): receipt/storage paths or signed URLs,
  `bank_transfer_submissions` ids and reviewer ids, `public_rejection_reason`, processor notes, payer or bank
  details, `provider`, `provider_session_id`, `provider_transaction_id`, settlement or evidence references,
  `external_settlement_id`, buyer id, buyer email, IP/device data.

Detail returns `{"data": {"item": {...same fields...}, "as_of": "..."}}`; its `as_of` is the current detail
request's statement timestamp, with no cursor or counts. A payment that does not exist returns 404
`RESOURCE_NOT_FOUND`.

## 6. Status mapping to Flutter `PaymentStatus`

Flutter today: `PaymentStatus { pending, approved, rejected, processing }`
([payment_record.dart](../../lib/features/admin/domain/entities/payment_record.dart)). The mapping is computed in SQL
from trusted `orders.status`, the latest `bank_transfer_submissions.status` and `payment_attempts.status`; the
client never derives it. Latest supporting rows are selected per order by `(created_at desc, id desc)`.
Resolve terminal order states (`paid`, `failed`, `cancelled`, `refunded`) before considering pending-state
supporting rows; an older rejected submission must not override a paid order or a newer upload/review.

| Order status | Supporting state | Wire `status` |
| --- | --- | --- |
| `created`, `pending_payment` | online: no attempt yet, or latest attempt `initialized` / `pending` | `pending` |
| `created`, `pending_payment` | bank: no submission yet, or latest submission `awaiting_receipt` | `pending` |
| `pending_payment` | bank: latest submission `rejected`, before a new submission is prepared | `rejected` |
| `pending_verification` | bank: latest submission `submitted` / `under_review`; online: latest attempt `initialized` / `pending` awaiting provider result | `processing` |
| `paid` | verified settlement exists | `approved` |
| `failed` | online attempt failed | `rejected` |
| `cancelled` | order cancelled | `rejected` (Q5) |
| `paid` but no verified settlement | inconsistent | request fails 503 `REPORTING_UNAVAILABLE`; never shown as approved |
| `refunded` | — | request fails closed 503 `REPORTING_UNAVAILABLE` (Q6) |

The no-child-row cases are ordinary checkout states: `csa098_create_checkout_order` inserts a
`pending_payment` order before online initialization or bank receipt preparation. Bank review rejection
(`csa112_review_bank_transfer`) leaves its submission `rejected` and resets the order to `pending_payment`;
this is a supported rejection, not an inconsistent financial state. Preparing a new submission makes the
latest row `awaiting_receipt` (`pending`); submitting it moves the order to `pending_verification`
(`processing`). These mappings describe the latest review outcome for one order and do not grant access.
Other order/supporting-state combinations remain unsupported and fail closed under §9.

Refunds: CSA-172 already fails closed when any order is `refunded` because no confirmed adjustment ledger exists.
This proposal keeps the same behaviour rather than inventing a refund presentation. If the owner wants refunded
rows listed, the `PaymentStatus` enum needs a new value, which is a shared-contract change.

Never shown as approved: receipt submitted, bank submission `approved` without `paid` + verified settlement,
client redirect or sandbox-only settlements. `approved` = trusted `paid` order with a verified settlement, which is
the same basis CSA-172 uses. Sandbox online settlements: excluded from `approved` counts for consistency with
CSA-172 or labelled; decision Q7.

Method mapping: wire `online` / `bank_transfer`. The Flutter enum today is
`PaymentMethod { stripe, bankTransfer, adminGrant }`; the project's provider is PayHere (not Stripe), and admin grants
are enrollments, not orders. The adapter maps `online` to the existing online value and `bank_transfer` to
`bankTransfer`. The enum rename and `adminGrant` handling are Q8.

## 7. Error codes

Bounded public codes only; backend messages and SQLSTATE detail are discarded, as in the reporting handlers.
Names match existing handlers so `AdminDirectoryClient.invoke` needs no new status handling.

| HTTP | Code | When |
| --- | --- | --- |
| 400 | `INVALID_REQUEST` | Unknown/missing key, bad type/range, bad cursor, bad date, `page_size` out of range, SQLSTATE `22023` |
| 401 | `AUTH_REQUIRED` | Missing/invalid/expired token, anonymous user, bad claims |
| 403 | `ADMIN_PERMISSION_REQUIRED` | Not finance/super-admin, role revoked, AAL1, SQLSTATE `42501` |
| 403 | `ORIGIN_FORBIDDEN`, `PREFLIGHT_FORBIDDEN` | Origin not allowlisted |
| 404 | `RESOURCE_NOT_FOUND` | Detail mode only; unknown `payment_id` |
| 405 | `METHOD_NOT_ALLOWED` | Not POST/OPTIONS |
| 415 | `UNSUPPORTED_MEDIA_TYPE` | Not JSON |
| 503 | `REPORTING_UNAVAILABLE` | Hard-disabled, inconsistent/unsupported state, DB failure |
| 503 | `SERVICE_UNAVAILABLE` | Missing config, timeout, upstream failure |

No error reveals whether a payment exists to a caller who lacks the role (permission is checked before lookup).

## 8. Consistency, pagination and idempotency

- Read-only and naturally idempotent; no idempotency key. Responses are `no-store`.
- Keyset pagination ordered by `(created_at desc, id desc)`; the opaque cursor encodes the last `(created_at, id)`,
  the `as_of` boundary and a hash of the filters. No offset pagination (cost grows, rows shift under writes).
  Required index (migration owner to confirm): `orders(created_at desc, id desc)`, plus partial/composite indexes
  as measured by the owner; no unbounded scans.
- `as_of` is `statement_timestamp()` of the first page; later pages keep `created_at <= as_of` for both items
  and counts. Orders created after the cutoff are excluded until the caller starts a fresh traversal.
- Status and counts are live for each request, using one SQL statement snapshot and its current
  `count_as_of = statement_timestamp()`. They are not preserved from page 1. For example, if a bank order in
  scope is approved between page 1 and page 2, page 2's counts move one from `processing` to `approved` and
  any matching page-2 item uses that same current state. `as_of` stays fixed while `count_as_of` advances.
- A fixed creation cutoff is not a historical status snapshot. With a status filter, an order may enter or leave
  the matching set between requests; a newly matching order above the current keyset position is seen only on
  refresh. Do not promise an immutable set, historical counts or gap-free traversal across status changes.
- Dashboard and Payments page use this one `counts` source (no second query path). Identical counts are
  guaranteed when they consume the same response; separate requests can differ after intervening writes.
- No N+1: one query joins `orders`, a lateral latest submission/attempt, and `verified_settlements`.

## 9. Fail-closed rules

Any unmapped status, `paid` order without a verified settlement, or `refunded` order in scope returns
503 `REPORTING_UNAVAILABLE`. Missing reporting is never represented as zero payments or an empty queue
(AGENTS.md §36; CSA-171 finding 004 behaviour is preserved on the client).

## 10. Privacy

| Data | Exposed? | Rationale |
| --- | --- | --- |
| Receipt paths, signed URLs, receipt asset ids | No | Private bank receipts; obtained only via `bank-transfer-read`/review flow |
| Payer name, bank, account, transfer reference | No | Sensitive financial data; not needed for listing |
| Provider ids / session / transaction / evidence refs | No | Payment-verification secrets by policy |
| Rejection reason, reviewer ids, notes | No | Review data; belongs to the review flow |
| Student id | No (v1) | Not needed; avoids a cross-system join key |
| **Student email** | **No in v1 (recommended)** | See Q3. `bank-transfer-read` already excludes it. If the owner requires it, return only to `finance_admin`/`super_admin` at AAL2 (already the only callers), as a separate field, never in logs, never in error bodies, never cached. |
| Course title snapshot, order number, amount | Yes | Needed for the list; finance/super-admin only |

The response is never logged beyond allowlisted fields (status code, error code, caller role, page size, result
count); no amounts, ids or emails in logs (SECURITY.md THREAT-012). Student-facing and content-staff callers cannot
reach the function at all.

Consequence for the Flutter entity: `PaymentRecord.studentId`, `studentEmail`, `processorNote` and
`receiptStoragePath` have no live source. The UI must show them as unavailable or remove them in a separate
approved UI task; it must not fabricate them (Q9).

## 11. Mock-response policy

- Synthetic fixtures (`StubAdminPaymentRepository`, Node handler test fixtures) are for tests only, behind explicit
  provider overrides. A fixture must never be reachable from a release build or labelled as a verified payment.
- Frontend work may begin against this contract using clearly synthetic payloads only after the owner approves the
  contract; mock payloads must match the field list in §5 exactly (string minor units, no extra fields).
- Contract changes after approval go through the AGENTS.md §17 coordination process.

## 12. Test matrix

Backend (Codex; Node handler tests and executable SQL fixtures, as for CSA-158/172):

| Area | Cases |
| --- | --- |
| Disabled | `enabled` false returns 503 `REPORTING_UNAVAILABLE` for every method and body |
| Auth | no/invalid/expired/anonymous token → 401; forged `sub`/`session_id` claim → 401 |
| Cross-role | student, content_manager, no-role user → 403; finance_admin and super_admin → 200 |
| MFA | finance/super at AAL1 → 403; AAL2 → 200; AAL downgrade mid-session denied by SQL recheck |
| Revocation | role revoked between auth and query → 403 (lock 610061); revoked session → denied |
| Direct SQL | `anon`, `authenticated` cannot execute RPC or select base tables; only `service_role` executes |
| Request validation | unknown keys, missing keys, wrong types, `page_size` 0/51, bad dates, `to < from`, span 367 days, bad prefix chars, oversized body, wrong content type |
| Filters | each of status/method/date/prefix alone and combined; Asia/Colombo midnight boundaries; inclusive end date |
| Pagination | first/middle/last/empty page; unchanged statuses have no duplicates or gaps across pages when concurrent inserts are after the creation cutoff; stable order with equal `created_at`; tampered cursor; cursor reused with different filters; exact `page_size` bound |
| Mapping | every row in the §6 table; checkout with no online attempt or bank submission is `pending`; bank rejection resets the order to `pending_payment` and reports `rejected`; new receipt preparation reports `pending`, then submission reports `processing`; older rejection never overrides newer pending/review or paid state; `paid` without settlement and `refunded` fail closed |
| Counts | `counts` equal the sum of statuses; page and counts use one current statement snapshot; dashboard and Payments page consuming that response agree; honor method/date and `created_at <= as_of` but not status filter; page 1 has `as_of = count_as_of`, subsequent responses retain the cutoff and report their current `count_as_of` |
| Large amounts | `amount_minor` at `9007199254740993` and bigint max serialize as exact strings; `0`; sum of counts as strings |
| Privacy | response keys exactly equal the allowlist; fixtures seeded with receipt paths, emails, provider refs, rejection reasons never appear in body, logs or errors |
| Errors | backend/SQL error text never reaches the body; stable codes only; permission checked before existence (404 vs 403 oracle) |
| Performance | query plan uses the keyset index; no seq scan on a large synthetic orders table; response under size limit at `page_size` 50 |
| Concurrency | approval between pages changes live counts and matching rows together at the new `count_as_of`; cursor `as_of` remains fixed; new orders after that cutoff are excluded from both items and counts; status-filter membership can change and requires refresh for newly matching rows above the cursor; separate requests need not have identical counts |

Frontend (Claude, after approval, widget/unit tests): adapter parses exact strings; large amounts do not lose
precision; each error code maps to a safe message; 401/403/503 states render unavailable/permission states, never
empty lists or zero counts; dashboard and Payments page use one count provider and one response for identical
badges; retain the fixed cursor cutoff but replace counts and their `count_as_of` together on each response;
refresh starts a new traversal; Processing included in totals; filters send the exact request shape; no
fabricated email/receipt fields.

## 13. Flutter adapter plan (Claude, after owner approval and after the endpoint contract is deployed to staging)

1. Add `SupabaseAdminPaymentRepository implements AdminPaymentRepository` in
   `lib/features/admin/data/repositories/`, using `AdminDirectoryClient.invoke('admin-payment-list', body)` (same
   pattern as `admin_course_repository.dart` / `admin_student_repository.dart`). `invoke` already maps 401/403/other
   to safe `AdminDataException` messages; no raw backend text reaches the UI.
2. `listPayments`: `page` (offset) in the current interface does not map to cursor pagination. Preferred: extend
   the interface with a cursor-based method or have the repository keep an in-memory cursor chain keyed by filter.
   This changes a shared interface and tests, so it is an explicit part of the frontend task, not a silent change.
   `searchQuery` maps only to `order_number_prefix`; email search is dropped (Q4).
3. `countAllStatuses` / `countPayments`: served from the `counts` field of a `page_size` 1 request (or the first
   list page) through one shared Riverpod provider. Share the response when dashboard and Payments page need
   identical counts; independent requests can observe later writes. Keep each response's counts and
   `count_as_of` together, update them on every fetched page, and treat `as_of` only as the fixed creation cutoff.
   Refresh discards the cursor chain and starts a new cutoff; do not present cursor pages as historical snapshots.
4. `getPayment`: `mode: "detail"`.
5. Money: parse `amount_minor` with `BigInt.parse` / keep as string; Flutter Web `int` and `double` are JS numbers
   and lose precision above 2^53. `PaymentRecord.amount` is a `double` today. Moving to an exact minor-unit type
   changes a shared domain model and must be approved (Q9). Interim display may format from the string only.
6. Wire the provider override only behind the activation flag/config; the default stays
   `UnavailableAdminPaymentRepository` until backend activation is approved. `StubAdminPaymentRepository` remains
   test-only.
7. Out of scope here: approve/reject actions (owned by `admin-review-bank-transfer`), receipt viewing
   (`bank-transfer-read`).

## 14. Ownership, sequencing and gates

- Backend (Edge Function, RPC, migration, SQL fixtures): CODEX, after owner approval and a GitHub Issue recording
  ownership, file scope and the migration owner (one migration owner; serialize with other reporting/payment
  migrations). Payment-related: **maker-checker required** (AGENTS/CLAUDE.md §18); the maker cannot approve
  its own work and a Claude subagent is not an independent checker.
- Frontend adapter: CLAUDE, after the contract is approved and ideally staged; shared-file coordination needed for
  the provider wiring and (if approved) the `PaymentRecord`/enum changes.
- Activation: hard-disabled until reviewed activation; no production access or data change is authorized by this
  proposal.
- The proposal must not be read as approval; status stays PROPOSED until the owner records a decision.

## 15. Open questions for the owner

1. **Payment identity.** Is `payment_id = orders.id` (one row per order) acceptable, or must each payment attempt /
   settlement be its own row (then ids and counting rules change)?
2. **Roles.** Confirm finance_admin and super_admin (AAL2) only, with content_manager denied entirely.
3. **Student email.** Omit in v1 (recommended), return full to finance/super-admin, or return masked? Is a
   separate purpose-limited lookup preferred?
4. **Search.** Is order-number prefix search enough? Email/name search needs Q3 and an indexed, privacy-reviewed design.
5. **Cancelled orders.** Map to `rejected`, or add a distinct status (shared-contract change)?
6. **Refunds.** Keep fail-closed until a confirmed adjustment ledger exists (recommended), or add a `refunded` status now?
7. **Sandbox online settlements.** Exclude from `approved`/counts (consistent with CSA-172), or show labelled?
8. **Method enum.** Rename `stripe` to a provider-neutral `online` and drop `adminGrant` from payments (admin grants are
   enrollments)? Or keep an admin-grant listing from a separate source?
9. **Entity changes.** Approve moving `PaymentRecord.amount` to an exact minor-unit type and removing/deprecating
   `studentId`, `studentEmail`, `processorNote`, `receiptStoragePath`?
10. **Page size and retention.** Is a 50 maximum and 366-day filter window acceptable? Any history retention or
    archival limits to respect?
11. **Task ownership.** Which task ID and issue number; which agent owns the migration; who is the independent checker?
12. **Activation.** What are the release gates (hosted staging acceptance, finance sign-off) before enabling?

## 16. Verification status of this document

Documentation only. No application was built, deployed or runtime-tested for this proposal. Schema statements
were read from
`supabase/migrations/20261011001000_csa092_orders_payment_attempts.sql`,
`20261011001200_csa094_bank_transfer_submissions.sql`, `20261011001400_csa096_financial_constraints.sql` and
`20261012003000_csa158_172_reporting.sql`. Review corrections also checked
`20261012002000_csa117_checkout_alignment.sql`, `20261011001600_csa101_105_online_payment.sql` and
`20261011001700_csa108_113_bank_workflow.sql` for no-child checkout and bank rejection/resubmission states.
The request/response, mapping and indexes are proposals that the backend owner must validate against the live
schema before implementation. Review evidence and limits: [PR179-CONTRACT-FIX-BOARD.md](../reviews/PR179-CONTRACT-FIX-BOARD.md).

## 17. Implementation decisions (backend, owner-authorized takeover from Codex)

Implemented read-only and hard-disabled: migration `20261018000100_csapaylist_admin_payment_list.sql`
(`csapaylist_admin_payment_list`, `csapaylist_admin_payment_detail`, service_role only), Edge Function
`supabase/functions/admin-payment-list/` (`index.ts` passes `enabled: false`), Node tests and SQL fixtures.
Open questions were resolved conservatively (least privilege, omit rather than guess). The owner may still override;
nothing below is an owner approval of the contract itself.

| Q | Choice | Reason |
| --- | --- | --- |
| 1 | `payment_id = order_id = orders.id`; both returned | One row per order; attempts/submissions are not payments. |
| 2 | `finance_admin` and `super_admin`, AAL2 only; `content_manager`, students, AAL1 denied entirely (403) | Reuses `csa158_reporting_roles` then narrows. Handler also denies AAL1 before the RPC. |
| 3 | Student email, student id, buyer data omitted | Minimization; no purpose-limited lookup exists. |
| 4 | Search = case-insensitive order-number prefix only (`[A-Za-z0-9-]`, 1..40) | No indexed, privacy-reviewed email/name search. |
| 5 | `cancelled` and `failed` map to `rejected` | Existing four-value `PaymentStatus`; no shared enum change. |
| 6 | `refunded` order in scope fails the whole list closed (55000 -> 503); detail of a refunded order also 503 | Same as CSA-172; no adjustment ledger. |
| 7 | Sandbox online settlements never count as approved. A `paid` order whose only settlements are sandbox fails the request closed (it is neither approved nor hidden) | Consistent with CSA-172; a silent omission would understate counts. |
| 8 | Wire methods `online` / `bank_transfer` only; admin grants are not listed | Enrollments, not orders. Flutter enum rename is the frontend task. |
| 9 | No entity changes made here (Flutter untouched) | Frontend task. |
| 10 | `page_size` 1..50, date window <= 366 inclusive days, Asia/Colombo day boundaries, cursor TTL 15 min | As proposed. No retention limit invented. |

Other choices:

- Status is mapped from `orders.status` only (`created`/`pending_payment` pending, `pending_verification` processing,
  `paid` + qualifying settlement approved, `failed`/`cancelled` rejected). `payment_attempts` and
  `bank_transfer_submissions` are not read, so receipt state can never influence the status. A "qualifying"
  settlement is `bank_transfer`, or online with `provider_environment='production'`.
- `settled_at` = earliest qualifying `confirmed_at`.
- `counts` cover `method` and date filters, the `as_of` boundary, and **not** `status` or `order_number_prefix`
  (literal reading of section 5). They come from the same single SQL statement as the page rows.
- Cursor is built in the Edge Function, not in SQL: base64url payload `{c: created_at, i: id, a: as_of, u: actor,
  f: filter-hash}` plus an HMAC-SHA256 keyed with the service key. Bound to actor, filters (not page_size), and
  expiry. SQL receives only `(created_at, id, as_of)` and re-validates shape. Rotating the service key invalidates
  outstanding cursors. Timestamps keep microsecond text (`...SSSSSSZ`) end to end; they are never parsed to a JS Date
  for the keyset position.
- Response is re-validated by an allowlist in the handler (exact keys, uuid/decimal/enum/timestamp shapes, counts sum
  to total, `settled_at` non-null only for `approved`). Any deviation fails closed with 503 `REPORTING_UNAVAILABLE`.
  `amount_minor` is a decimal string <= bigint max.
- Error mapping: SQLSTATE `42501` 403, `22023` 400, `P0002` 404 (detail only, after authority), everything else 503.
- Added index `orders(created_at desc, id desc)`. The page query reads through `app_private.csapaylist_scope`, a
  security-definer SQL function; counts require scanning the filtered scope, so very large order tables are not
  index-only. Measure before activation.
- Shared files touched (owner-authorized "do all"): `supabase/config.toml` (function entry; the code-level
  `enabled:false` gate still applies) and `csa173_admin_permissions.test.sql` (grant matrix 13 -> 15 signatures).
  `TASKS.md` and `docs/API_CONTRACTS.MD` were not edited; recording the contract there is an owner step.

