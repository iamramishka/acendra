# CSA-158 / CSA-172 reporting

## Current status — 2026-10-13

Foundation reviewed and merged into dev via [PR #107](https://github.com/iamramishka/acendra/pull/107).
Hosted PR checks passed; integration and shared test/config updates are complete.
Status remains IN_REVIEW for operational acceptance; production endpoints remain disabled.
Earlier pending-PR/integration/CI statements below describe the historical worker stage.
[Current evidence and remaining gates](../tasks/CSA-158-168-MERGE-RECONCILIATION.md) include the verified pre-existing
dev formatting failure, post-merge tests and activation prerequisites.

Status: IN_REVIEW. Owner: CODEX. Coordination: GitHub issue #106.
Production entries remain hard-disabled until release activation receives review.
The owner approved recognition on 2026-10-12; see
CSA-158-172-REPORTING-APPROVAL.md. The injectable `enabled:true` seam is for verification.

`admin-dashboard-stats` accepts exactly `{period:"last_30_days"}`.
`admin-financial-report` accepts exactly `{from:"YYYY-MM-DD",to:"YYYY-MM-DD",currency_code:"LKR"}`.
Dates are inclusive Asia/Colombo calendar dates; at most 366 calendar days.
Dashboard course/student/access/queue counts are current snapshots. Receipt facts
use the preceding rolling 30 days by settlement confirmation timestamp.

Authentication derives the actor from verified Supabase Auth. Restricted
service-role RPCs recheck current account, session, AAL and unrevoked roles inside
PostgreSQL. Role mutation lock 610061 prevents concurrent revocation during the
query. Finance/super-admin requires current AAL2. Content-only staff uses current
course assignments and may receive only total/published assigned-course counts.
Finance receives only pending bank reviews and confirmed receipts. Super-admin
also receives registered-student and effective-active-enrollment counts.
Unauthorized fields are omitted, never returned as zero. Counts and minor units
are decimal strings to preserve PostgreSQL bigint/numeric precision in browsers.

Registered students means undeleted non-anonymous accounts with an explicit
student role or no elevated role; ordinary signup has no explicit student grant.
Active enrollments evaluates surviving grant sources and restrictions through
`csa117_has_access`, rather than trusting stale projection status. Deleted,
anonymous or currently banned accounts are excluded from the active count.
Pending bank reviews requires submitted/under-review evidence and a currently
pending-verification order; awaiting uploads and finalized orders are excluded.

Financial facts deliberately use `confirmed_receipts`, not the example `revenue`
contract. They count immutable verified settlements once each, excluding online
sandbox records and including independently verified bank settlements. Additional
verified receipts remain receipt facts rather than fictitious extra course sales.
They expose neither settlement references nor payer/bank/provider details.
Recognition uses settlement confirmation time. `gross_receipts_minor` is an
explicit alias for exact `confirmed_amount_minor`; neither counts course sales.
Net is approved as confirmed receipts minus confirmed refunds, excluding fees
and taxes. Refund/net numeric figures are unavailable because the baseline lacks
a confirmed adjustment ledger. Statuses explicitly name that limitation; absence
does not mean zero. Any refunded order makes financial totals fail closed until trusted
adjustment reporting is integrated; refund requests/approvals never mean payout.
Recognition is approved; implementation and future ledger integration require review.

Errors are bounded public codes; backend details are discarded. Requests/responses
are size-limited, uncached, origin-restricted and validated. No public table/view
grants or financial/access mutations are added.

Verification: Node boundary tests and executable SQL fixtures cover auth, omitted
metrics, assignments, MFA, revoked roles, actual entitlement counts, direct SQL
grant denial, dates/currency and exact integer serialization. Integration must
run ordered migrations and SQL fixtures against Supabase before acceptance.
