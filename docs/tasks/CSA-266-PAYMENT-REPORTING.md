# CSA-266 — authorized payment reporting

Owner: CODEX. Issue: [#192](https://github.com/iamramishka/acendra/issues/192).
Status: IN_REVIEW. User requested the reporting fix and a PR on 2026-10-19,
then explicitly chose unavailable refund/net figures pending a separate trusted
refund-ledger task.

Branch: `fix/csa-266-payment-reporting`.
Worktree: `C:/Users/ramis/.codex/worktrees/payment-reporting/acendra`.
Base: published `origin/dev`. Primary-checkout edits are excluded.

## Ownership and acceptance

Checked open issues, PRs and worktrees before implementation; no active reporting
owner overlapped. PR185/186 feature work and issue160 production operations remain
separate. Scope: admin payment adapter/entity/providers/payment presentation,
reporting Edge entrypoints/shared release-switch helper, Flutter/Node regressions
and this record. Shared documentation ownership covers the new CSA266 task entry
and reporting contract addenda only. No dependencies or migrations change.

Dependencies: merged list/detail RPCs, verified-settlement reporting and existing
session/role/MFA checks. Maintainer financial review is required before merge;
this task does not deploy or enable hosted reporting.

Acceptance:
- Authorized order rows replace the unavailable Flutter default.
- A shared unfiltered atomic count snapshot feeds Payments and Dashboard;
  refresh invalidates it. Filters do not change the meaning of global totals.
- Opaque cursor pagination, detail identity and prefix-only search honor the
  existing API. Buyer email/id and administrative payments are not invented.
- Live amounts display exact minor units.
- Session changes invalidate dependent data; late filter responses cannot
  replace a newer result/account.
- Explicit server opt-in and exact allowed origins replace unconditional source
  disables. Auth, SQL authority, MFA, sandbox exclusion and refunded-history
  fail-closed behavior remain binding.
- Gross receipts use the existing verified-settlement adapter. Refund/net totals
  remain unavailable by owner decision.
- Receipt review audit history remains unavailable for the live adapter: the
  order-status API does not return review decisions/reviewers. Rejected order
  outcomes must not be presented as proof of human receipt review.

## Release and rollback

The following are operator steps for a separately reviewed environment; they
were not executed by this task. Staging is not relabeled production.

1. Verify the migration ledger includes CSA158/172 reporting, CSA-PAYLIST and
   ordered dependencies. Run existing role, settlement, sandbox, refund and
   payment-list SQL fixtures against a disposable stack.
2. Deploy `admin-payment-list`, `admin-dashboard-stats` and
   `admin-financial-report`, including the shared helper. Leave flags absent;
   verify bounded 503 unavailable and no reporting RPC call.
3. Configure `ACENDRA_ADMIN_ALLOWED_ORIGINS` with exact comma-separated origins:
   no wildcard, trailing slash, path, credentials or empty member. HTTPS is
   supported; cleartext HTTP is limited to local loopback.
4. Set `ACENDRA_ADMIN_PAYMENT_LIST_ENABLED=true` for rows/counts and,
   independently, `ACENDRA_ADMIN_SETTLEMENT_REPORTING_ENABLED=true` for both
   settlement endpoints. Only lowercase `true` opts in; missing/invalid origins
   keep endpoints disabled. These are server settings, not client authorization.
5. Verify current finance/super-admin AAL2 reads and denied student, content-only,
   AAL1, revoked and anonymous sessions; allowed/foreign origins; continuation,
   filtering and shared counts. Compare gross minor units to verified production
   online/bank settlements. Sandbox-only paid and refunded history fail closed.
6. Exercise account switch, logout, refresh and backend failure. Verify exact
   gross and the refund/net-unavailable message. Retain hosted acceptance evidence
   before separately approving a production release.

Rollback: remove/set the relevant flag to `false` and restart/redeploy its Edge
Functions. Reporting returns 503 unavailable rather than fabricated zero values.
No data rollback is needed: no financial mutations, grants or schema changes.

## Verification

- Final admin suite: **107 passed**, including the explicit receipt-audit-history
  boundary, session switching and stale-response regressions.
- Reporting/permission boundaries: 210 passed, zero skips (Node concurrency 2).
- Repository Dart formatting: 298 files, zero changes. Final touched files also
  formatted; `git diff --check` passes.
- Full tooling: 848 passed, 10 environment skips, one cancelled browser playback
  test after its 30-second timeout. Isolated rerun of the unchanged
  `tool/deployment_csp.test.mjs` reproduces the same timeout (one passed, one
  cancelled). The tested CSP/browser file and server policy match the base.
- Full `flutter analyze --no-pub` stalled without diagnostics and was stopped;
  not a pass. Scoped `dart analyze lib/features/admin test/features/admin`
  exited 4: SDK perf-witness shutdown could not delete its Windows performance
  file (FileSystemException errno 1920). No clean analyzer result is claimed.
  Standard release web build remains pending.
- No local Docker/Supabase replay; existing SQL migrations and grants are
  unchanged. Required hosted Supabase CI supplies fresh database verification.

Local verification does not establish hosted activation, finance acceptance or
production readiness. Final-head CI, financial review and deployment acceptance
remain required. No production data, secrets, roles or service configuration were
changed. PR link and final checks will be added to the issue/PR handoff.
