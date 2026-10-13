# CSA-158 / CSA-172 handoff

Owner: CODEX reporting worker; issue #106; status IN_REVIEW.
Branch: codex/feat/csa-158-172-reporting.
Worktree: C:/Users/ramis/.codex/worktrees/csa-158-172-reporting/acendra.
Approval authority: project owner; no production activation or merge inferred.

Implemented additive read-only reporting RPCs and bounded authenticated HTTP
handlers for `admin-dashboard-stats` and `admin-financial-report`. Current
permission resolution omits unauthorized metrics; assignment scope restricts
content managers. Effective source-based entitlement count avoids stale labels.
Production online/verified-bank settlement facts preserve exact integer strings
and calendar boundaries. No unapproved revenue recognition, zero-refund or net
income claims are returned. Refunded history fails closed. See the task contract.

Files: new endpoint directories, migration 20261012003000, SQL fixture,
docs/contracts/CSA-158-172-REPORTING.md, this handoff. Existing schemas and shared
configuration/task/API files were not modified. Shared contract changes require
explicit root integration: decimal count/minor-unit strings, additional
`total_courses`, `confirmed_receipts` instead of legacy illustrative `revenue`,
fact report fields instead of unsupported gross/refund/net accounting fields.
Financial handler imports the dashboard handler; deploy packaging must include
that sibling module. Both production entry points are hard-disabled.

Verification 2026-10-12:
- RED: new dashboard tests failed with missing implementation module.
- GREEN: 21 Node HTTP boundary tests passed using bundled Node 24.
- Migration applied successfully and SQL fixture passed on dedicated native
  PostgreSQL 17 at 127.0.0.1:58465, database csa_admin_test. The root bootstrap
  models Supabase auth/storage schema; actual baseline migrations 001–025 and
  task032 were applied. This proves database behavior in that model, not live
  Supabase Auth, Storage, gateway, deploy packaging or production concurrency.
- SQL fixture rolls back synthetic records, checks current role/session/MFA,
  assignment revocation, omissions, effective entitlement grants/restrictions,
  exact large sums, sandbox exclusion, Colombo date boundaries, refunded-history
  fail closure and public RPC execution denial.
- Diff whitespace check passed.

Owner approved settlement-confirmation recognition, Colombo dates and net as
confirmed receipts minus confirmed refunds excluding fees/taxes on 2026-10-12.
New approval record documents this. Gross facts use the approved definition;
refund/net numeric totals remain unavailable until a confirmed adjustment ledger
exists. Explicit reporting statuses and limitations describe that missing ledger.

Remaining: root shared config/test-runner/API alignment; hosted Supabase CI;
security and financial review; reviewed activation and future adjustment ledger
integration. Definition changes should be reviewed as a contract, not implied from
this facts-only implementation. No refund/financial state writes or external
messages occur. No production credentials/configuration or data were used.
