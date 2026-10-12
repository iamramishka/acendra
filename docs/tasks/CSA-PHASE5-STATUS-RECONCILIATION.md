# Phase 5 status reconciliation — 2026-10-12

Owner: CODEX. User-authorized documentation reconciliation only.
Status: IN_REVIEW (documentation prepared; no commit, push or merge).
Scope / temporary ownership: TASKS.md Phase 5 Codex entries and this record.
Branch: codex/docs/csa-phase5-status-reconciliation.
Isolated worktree: C:/Users/ramis/.codex/worktrees/csa-phase5-status-reconciliation/acendra.
Review authority: project owner/designated maintainer.
Dependencies: merged PRs #61, #68–71, #79, #84, #86 and #88.
Overlap checked: all worktrees, local Git status, open GitHub Issues and PRs.
Existing PR #75 covers foundation status reconciliation; this local assignment
extends its evidence to later merged batches, without changing that branch or PR.
No new GitHub claim or financial implementation is made.
Verification: live GitHub PR states, exact-head check results, acceptance comments,
remote dev task records and local diff checks. No runtime tests are rerun for this
documentation change; CI results below are historical evidence freshly inspected.
Application: copy only the reviewed documentation to the requested checkout;
its source checkout remains behind remote dev. Preserve unrelated untracked work.

## Evidence and status decisions

- CSA-092/093/094/095/096/098: DONE for accepted foundation scopes, PRs #61 and
  #68–71. Existing reconciliation PR #75 records accepted scope. PR #71 final
  Flutter and Supabase checks both SUCCESS.
- CSA-100: BLOCKED. Real sandbox checkout/callback/authenticated retrieval and
  merchant readiness remain unverified. Adapter merged; online entry points disabled.
- CSA-101–105: IN_REVIEW. PR #79 merged and final Flutter/Supabase checks SUCCESS;
  real provider acceptance and financial acceptance were explicitly retained in
  the handoff. Do not equate development merge with completed provider acceptance.
- CSA-108/109/112/113: DONE for development implementation. PR #84 comment
  records owner authorization to fix then merge, resolved historical replay bug,
  passing real pinned Storage lifecycle checks and exact-head Flutter/Supabase CI.
  Operational inspection/banking/retention setup and disabled endpoints remain gates.
- CSA-114/116/117/118/120: DONE for accepted development implementation. PR #86
  records authorized review and merge, no actionable findings, 304 Node tests,
  clean SQL/race checks, exact candidate Supabase and Flutter SUCCESS, and matching
  merged dev tree. Protected content integration is subsequent scope.
- CSA-119: IN_REVIEW. Durable outbox/leased worker accepted in PR #86, but live
  notification delivery still requires reviewed provider, sender, deduplication and
  authenticated scheduler. Do not claim actual email delivery complete.
- CSA-121–126: DONE for bounded financial regression test scopes. PR #88 merged into dev at 7f5f131; authorized parallel review found no actionable findings. Final-head Flutter/Supabase checks passed; fresh local tests: 304 passed, 0 failed, 4 database suites gated locally. See the dated follow-up below.

Current Codex counts: 21 DONE, 6 IN_REVIEW, 1 BLOCKED (28 total).
Claude tasks and Phase 5 integration/release checkboxes remain unchanged.

## Primary evidence

- https://github.com/iamramishka/acendra/pull/71
- https://github.com/iamramishka/acendra/pull/75
- https://github.com/iamramishka/acendra/pull/79
- https://github.com/iamramishka/acendra/pull/84
- https://github.com/iamramishka/acendra/pull/86
- https://github.com/iamramishka/acendra/pull/88
- PR #86 exact-head Supabase: https://github.com/iamramishka/acendra/actions/runs/38174503371
- PR #86 exact-head Flutter: https://github.com/iamramishka/acendra/actions/runs/38174506131

Next action: owner reviews documentation; reconcile existing PR #75 through the
approved integration workflow. No production approval or enablement is inferred.

Historical follow-up before this review: PR states #79 MERGED, #86 MERGED and #88 OPEN were rechecked;
TASKS.md now distinguishes task acceptance from PR state beside all 12 IN_REVIEW
entries. That historical PR #88 state and count are superseded by the follow-up below.

## CSA-101–105 review follow-up — 2026-10-12

Local assignment: CODEX; user authorized review, conditional merge to dev, then
this documentation update. Scope: this record and TASKS.md review evidence only.
Branch/worktree: codex/docs/csa-phase5-status-reconciliation in the isolated
worktree recorded above. Approval authority: project owner/designated maintainer.
Existing local edits were inspected and preserved. Live overlap checks could not
be repeated because GitHub access failed; no implementation ownership is claimed.

Target reviewed: commit 7f5f131e0520b42a5a24477ae12cc86f36415d66 in
C:/Users/ramis/.codex/worktrees/csa-121-126-financial-tests/acendra.
Reviewed checkout and webhook handlers, PayHere adapter, and migration016.
No actionable defect identified in that bounded source review. This is a partial
verification result, not full financial acceptance or a database-runtime pass.

Fresh command (Node v24.15.0):

```text
node --test --test-reporter=tap supabase/functions/_shared/payments/payhere.test.mjs supabase/functions/initialize-checkout/handler.test.mjs supabase/functions/payment-provider-webhook/handler.test.mjs tool/payhere_sandbox_verify.test.mjs
```

Result: 79 tests, 79 passed, 0 failed, 0 skipped. Synthetic checks cover exact
LKR minor-unit formatting, callback amount/currency/checksum rejection, OAuth
retrieval reference/order/gross amount binding, and handler boundaries.
Database atomicity and concurrency were inspected in source but not rerun:
Docker is unavailable on PATH. Historical CI is not fresh runtime evidence.

Cached origin/dev points to 7f5f131; `git merge-base --is-ancestor 34e6624
origin/dev` returned 0, establishing that the integration commit is already
included in cached dev history. No new merge or push was performed.
`gh pr view 79` and `git ls-remote origin refs/heads/dev` failed with repository
access/not-found errors. Current remote PR/branch state therefore remains
unverified; earlier live-state statements above are historical records.

Real probe: `node tool/payhere_sandbox_verify.mjs` exited 1 with
SANDBOX_CONFIGURATION_REQUIRED. All eight required PAYHERE_SANDBOX_* inputs
were absent from process, user and machine environments. Standard environment
files and saved probe evidence paths across registered worktrees were checked;
no usable PayHere configuration/callback evidence was found. The main .env had
no PayHere variables. No secret values were printed. Earlier OAuth success is
historical; the existing probe also does not exercise checkout or fulfillment.

Status retained: CSA-100 BLOCKED; CSA-101–105 IN_REVIEW. Remaining acceptance:
approved sandbox setup, real checkout/callback/authenticated retrieval with exact
amount/currency, current database/concurrency verification, and authorized
financial acceptance. Deployed online entry points remain disabled.
Next action: owner supplies the protected sandbox setup location/access;
CODEX reruns actual provider verification and records redacted evidence.

## CSA-121–126 parallel review follow-up — 2026-10-12

Owner: CODEX. Project owner authorized parallel review, conditional merge into
dev, and this documentation update. Scope: CSA-121–126 status and evidence in
TASKS.md and this record; reuse the isolated documentation worktree above.
Existing local edits were compared and preserved before this update.

Three read-only reviewers covered CSA-121/122, CSA-123/125 and CSA-124/126
against PR #88 and its supporting SQL, handler and independent-session tests.
Result: no actionable findings. Exact fault identity, per-boundary rollback,
recovery/replay, real lock contention, current finance authorization and
pending/rejected denial were inspected. No implementation changes were needed.

Live GitHub verification confirmed PR #88 already MERGED into dev at
7f5f131e0520b42a5a24477ae12cc86f36415d66; issue #87 is CLOSED.
A fresh fetch and ancestry check confirmed that merge is included in origin/dev.
Remote TASKS.md already marks all six DONE. No additional merge was performed.

Final-head checks on d25abe9e1f514aeca980fe67e232092b65447806:
- [Flutter: SUCCESS](https://github.com/iamramishka/acendra/actions/runs/38199667843).
- [Supabase: SUCCESS](https://github.com/iamramishka/acendra/actions/runs/38199667846).

Fresh `npm run tool:test` in the clean merged financial-tests worktree:
304 passed, 0 failed, 4 database suites gated locally (308 total).
Database suites were not rerun locally during this review; the hosted Supabase
result is separately verified historical execution evidence. Production/provider,
protected delivery, banking and live email release gates remain separate.

This follow-up supersedes earlier OPEN/IN_REVIEW statements for PR #88 and
CSA-121–126. Earlier GitHub access failures remain historical; this review
restored access using the repository owner's configured GitHub account.
Documentation remains locally prepared; no new commit, push or merge is claimed.

## CSA-101–105 and CSA-119 parallel review — 2026-10-12

Local assignment: CODEX; project owner authorized parallel review, merge into
dev only if no findings, and this documentation update. Writable scope is this
record and the six task entries/review summary in TASKS.md. Reuse the isolated
documentation branch/worktree recorded above; approval authority remains the
project owner. Existing local documentation was compared and preserved.
GitHub PR/task records and registered worktrees were inspected during review;
no implementation ownership was reassigned. No production activation is authorized.

Review target: dev commit 7f5f131e0520b42a5a24477ae12cc86f36415d66.
Three read-only reviewers used separate detached worktrees and covered
CSA-101/102, CSA-103/104, and CSA-105/119 simultaneously. Central review checked
integration ancestry, the outstanding webhook PR's files, and the full Node suite.

| Task | Review result |
|------|---------------|
| CSA-101 | P2 finding: accepted uppercase order UUID falsely returns 503 after initialization commits. |
| CSA-102 | No actionable findings identified. |
| CSA-103 | No actionable findings identified. |
| CSA-104 | No actionable findings identified; database runtime not rerun locally. |
| CSA-105 | No actionable findings identified; database runtime not rerun locally. |
| CSA-119 | No actionable findings within the gated outbox/worker scope; live delivery remains unverified. |

Finding location: `supabase/functions/initialize-checkout/handler.mjs:145`.
UUID input validation accepts uppercase characters, while PostgreSQL returns
canonical lowercase UUID text. Comparing `stored.order_id !== body.order_id`
therefore rejects a valid uppercase order UUID after the initialization RPC has
committed. A read-only synthetic reproduction returned 503 SERVICE_UNAVAILABLE
after both Auth and RPC calls. Required follow-up: normalize UUIDs before the
RPC/comparison, or reject noncanonical UUIDs before mutation, and add a meaningful
regression test. No fix or regression test was added during this review.

Fresh verification: `npm run tool:test` returned 308 total, 304 passed, zero
failed, four skipped database suites. Focused reviewer suites passed 90, 61 and
64 tests respectively; these overlap and must not be added to the full-suite count.
SQL, transaction/rollback and independent-session concurrency test source were
reviewed. PostgreSQL/Docker were unavailable on PATH, so database runtime checks
were not rerun. Hosted CI results are separate historical evidence, not local passes.

Live GitHub reads initially confirmed PR #79 and PR #86 MERGED into dev.
Local ancestry checks confirmed their merge commits 34e6624 and 1729117 are
included in origin/dev at the reviewed target. Open PR #78's original handler,
tests, index and task/contract files exactly match dev; its webhook work is already
integrated through PR #79. Later GitHub/fetch operations failed with repository
not-found/access errors, preventing further remote verification or mutation.
No new merge, push, PR closure or implementation change was performed. The
conditional no-findings merge criterion was not met because of the CSA-101 finding.

All six tasks remain IN_REVIEW. CSA-101 additionally requires the UUID fix and
regression verification. CSA-101–105 retain real PayHere sandbox checkout,
callback/authenticated retrieval and financial acceptance gates. CSA-119 retains
approved email provider/sender, stable-key deduplication, authenticated scheduler
and live delivery verification. Deployed payment/email entry points remain disabled.
This result supersedes the earlier no-actionable-defects summary for CSA-101;
that earlier bounded review is retained as historical evidence.
