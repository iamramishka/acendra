# CSA-158/164/165/168 merge documentation reconciliation

Date: 2026-10-13 (Asia/Colombo). Owner: CODEX. Authority: project owner's
request to update documents after reviewing and merging PR #107 into dev.
Coordination: Issue #106. Documentation-only assignment; no implementation changes.

Branch: docs/csa-158-168-merge-reconciliation.
Worktree: C:/Users/ramis/.codex/worktrees/csa107-merged-verification/acendra.
Base: 4e1639bb8546b7d181ab8e3d9f48dea19482a28c (merged dev).
Scope: TASKS.md and the task-specific integration, handoff, contract and approval
records for CSA-158/164/165/168/172. Other active tasks and worktrees are excluded.
Shared TASKS.md ownership is limited to these five status notes. Existing Issue
#106 integration ownership belongs to CODEX; this is a documentation follow-up.

PR #113 review assignment: project owner authorized review and merge on
2026-10-13. CODEX owns the existing documentation scope for this integration
follow-up in `C:/Users/ramis/.codex/worktrees/pr113-review/acendra`.
Open PRs #125/#126 concern separate CSA-184–188/200 documentation and task
entries; their scopes are preserved. No implementation file ownership is taken.

Verification: compare status statements with PR #107, its exact tested head,
merge SHA and hosted workflow results; inspect documentation diff and whitespace.
Keep incomplete release criteria visible and task checkboxes unchecked.

## Verified integration outcome

[PR #107](https://github.com/iamramishka/acendra/pull/107) was reviewed with no
actionable findings and merged into dev at
`4e1639bb8546b7d181ab8e3d9f48dea19482a28c` on 2026-10-13, 07:51 Asia/Colombo.
Owner authorized merge conditionally on a clean review. No production activation
or deployment was requested or performed. AI review does not claim independent
human security approval.

Exact PR head: `51f3596263d71d50cbaca78549833d0d2c85ecb2`.
- Fresh pre-merge tooling: 504 passed, 6 environment-dependent suites skipped,
  zero failures; `git diff --check` passed.
- Hosted PR [Supabase CI](https://github.com/iamramishka/acendra/actions/runs/38284043387)
  and [Flutter CI](https://github.com/iamramishka/acendra/actions/runs/38284043395)
  succeeded for that head.
- Fresh merged-dev tooling: 561 passed, 7 environment-dependent suites skipped,
  zero failures; `git diff --check` passed. Counts include newer dev tests.
- [Post-merge Flutter CI](https://github.com/iamramishka/acendra/actions/runs/38336532257)
  failed at formatting on eight existing router/marketplace files. The same
  files failed in the [previous dev run](https://github.com/iamramishka/acendra/actions/runs/38285749378)
  at parent `3d9dfbe6ecfa3aeb5ea11a07212c0fbe70dac39f`; PR #107 changes no Dart files.
  This is a verified pre-existing failure, not a fully green merged-dev build.
  No fresh post-merge database replay is claimed.

## Remaining acceptance and release gates

The backend foundation is merged. Tasks remain IN_REVIEW with checkboxes
unchecked because operational acceptance is incomplete:
- CSA-158/172: endpoints remain disabled; confirmed refund/reversal adjustment
  reporting is unavailable, and net/refund totals must not be fabricated.
- CSA-164: trusted inspector implementation and resource policy, operational
  lesson-image limits and actual signed upload/byte behavior remain outstanding.
  PDF 50 MiB and JPEG/PNG thumbnail 5 MiB limits remain approved; Mux uploads
  remain separate work.
- CSA-165: private text readiness and remaining provider/content readiness
  acceptance are outstanding; the publication endpoint remains disabled.
- CSA-168: current-authority enrollment views and canonical audited entitlement
  mutations are integrated; reviewed activation remains outstanding.

Next actions: resolve dev formatting under its owning task; complete operational
acceptance and any required authorized security/financial review; approve and
verify activation separately. Previous integration shared-file reservations end
at the merged stage; this follow-up reserves only the documentation scope above.

## PR #113 refreshed integration baseline — 2026-10-13

The preceding post-merge formatting failure describes the historical
`4e1639b` baseline. PR #113 initially reproduced that failure in
[CI run 38337206348](https://github.com/iamramishka/acendra/actions/runs/38337206348).
For the owner-authorized review, remote `dev` at
`a063a3990813b2c049118452ded557e301882e20` was merged into the PR branch
without conflicts. Existing dev implementation changes are retained; the
effective PR diff remains documentation only, with the five task checkboxes
unchecked. Fresh CI must pass before integration; the earlier failure is
retained as historical evidence rather than waived.

This newer baseline includes the private-image publication hardening described
in [the CSA-165 fix record](CSA-165-PRIVATE-IMAGE-FIX.md), plus newer admin
security tests. It does not establish operational content readiness, trusted
inspection, confirmed adjustment reporting or approved production activation.
The remaining acceptance gates above still apply.
