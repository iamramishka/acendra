# CSA-267 recovery and integration

Date: 2026-10-19 (Asia/Colombo). Owner: CODEX, Check GitHub issues chat.
Status: IN_REVIEW. Authority: project owner requested fixing open issues and
merging into dev. This is source integration authorization, not live activation.

## Ownership and preservation

PR #195 was closed without merge and its fork no longer resolves. Its immutable
head `6f3a3cef29d2204ea2979d30353f6b0fe3315902` was recovered from the upstream
pull-request ref. The existing source checkout and all other worktrees are untouched.

Branch: `fix/csa-267-recover-integration`.
Worktree: `C:/Users/ramis/.codex/worktrees/csa267-recovery/acendra`.
Scope: preserve and review the 37-file CSA-267 patch, fix media-path defects with
focused regressions, update CSA-267 evidence, and submit a replacement PR into dev.
Temporary shared ownership: only the existing CSA-267 additive core thumbnail,
package test registration, function configuration and new artwork migration changes,
including additive corrective migration `20261019000300` for the trigger guard.
Do not edit existing migrations, global tokens, dependencies or another task's code.

The active chats Review and merge PRs 185–188 and Review and merge PRs 189–194
retain their PR ownership. Issues #183/#192 and PR #187 for #160 remain with those
reviewers. PR #196 and uncommitted primary-checkout edits are excluded.

Dependencies: reviewed current dev and established media-upload authorization.
Verification: handler/parser/SQL/source review, focused Node/Python/Flutter checks
when resources allow, migration replay and full hosted checks before merge.
Approval authority: project owner/authorized maintainer and required GitHub review.

## Current external gates

GitHub reports the repository private. The latest Flutter job for PR #196 never
started: account payment/spending-limit gate (annotation on check 118090288810).
Do not treat this as a source-code failure or bypass required checks. No billing
setting, spending limit, review requirement or branch protection is changed here.
Media service provisioning, real scanner/Storage acceptance and deployment remain
separate release gates. No live activation is authorized by this record.

## Reproduced defects and fixes

- Widget regression tests reproduced a pending picker using the newly selected
  course and an old upload displaying success in a new course. The upload now
  snapshots its target and ignores results after course/lesson changes.
- Full native SQL replay exposed `csa178_deferred_financial_checks.test.sql`
  failing at its unrelated synthetic audit insert with `Validated artwork required`.
  A missing reservation made SQL `<>` predicates evaluate NULL, so the trigger did
  not exit. The additive corrective migration uses `NOT FOUND` and `IS DISTINCT
  FROM`. The original published migration is unchanged; an unreserved audit
  regression also checks that no artwork association is created.
- Executing the previously unverified artwork SQL suite also exposed malformed
  dollar quoting in its rollback-injection helper. Corrected the helper delimiter;
  no assertions were removed or weakened.

## Fresh verification and handoff

Replacement PR: https://github.com/iamramishka/acendra/pull/197 into `dev`.
Current integrated base: `03cf6f023642064fb3e4726e431aa692c63ac6db` (PR #194).
The retained PR #195 commits remain ancestors; recovery did not discard them.

- RED: both new widget regressions failed on the recovered source.
- GREEN: 33 focused Flutter tests passed; full `flutter test --no-pub
  --concurrency=1 --reporter=compact` passed all **835 tests**.
- `flutter analyze --no-pub`: no issues (278.4 seconds).
- `dart format --output=none --set-exit-if-changed lib test`: 304 files unchanged.
- Focused Node media/reporting checks: 45 passed, zero skips/failures.
- Python parser/HTTP/scanner-seam checks: seven passed, one Linux-only skip.
- Disposable native PostgreSQL 17: all **38 migrations** replayed and **40 SQL
  suites** passed (1,124 assertions), including 24 artwork assertions. Two suites
  (`000_foundation`, `csa179_bank_reads`) require absent pgTAP and were skipped.
  The harness uses synthetic Auth/Storage schemas with bucket RLS/client grants;
  this does not certify actual Supabase services, tokens or managed recovery.
- Native verification first exposed the trigger defect, then the malformed SQL
  helper; a later disposable initialization hit a 90-second timeout. The final
  bounded initialization/replay completed and the task-owned cluster stopped.
- `git diff --check`: passed. `flutter build web --release --no-pub`: passed
  (354.4 seconds), including the Wasm dry run. Existing Cupertino font warning
  remains; no font/dependency change was included in this recovery.

Local verification logs and disposable harness are outside the Git checkout in
`C:/Users/ramis/.codex/worktrees/csa267-recovery/`. No real accounts/data were used.

Hosted runs 39278196312 and 39278196417 failed **without starting** due to GitHub
account payment/spending-limit settings (check 118147478011 annotation). Vercel
preview passed; Supabase Preview skipped. Neither replaces required full CI.
Required approving review is absent. Keep the PR/issue in review until checks,
review and merge satisfy repository gates. #193's live scanner/Storage acceptance
remains separate; do not close it based on source preparation alone.
