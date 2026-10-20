# CSA-268 — bounded PR completion

Owner: CODEX. Status: IN_REVIEW. Current project-owner authority: fix the
remaining source issues identified in the finderror review and open PRs,
2026-10-20 (Asia/Colombo).

Integration branch: `fix/csa-268-review-completion`.
Worktree: `C:/Users/ramis/.codex/worktrees/csa268-pr-completion/acendra`.
Immutable incoming source: `81eab6b` (backend `ea23540`, integrated Flutter
`81eab6b`); published base dev `d46ae1c`. Both existing implementation worktrees
and all their commits remain untouched. No duplicate implementation is created.

Scope: review the existing committed CSA268 implementation, finish required
combined verification, implement the course-retention choice only after the
owner answers the pending question, and submit a PR against dev. New follow-up
database behavior must use an additive migration. Maintain current authority,
MFA, assignment, optimistic revision, idempotency and immutable audit contracts.
CSA269 separately integrates the primary checkout's committed owner UI changes.
No hosted deployment, activation, data cleanup or production release is included.

## Recorded owner decision

The project owner chose **archive courses and preserve history** in this chat on
2026-10-20. The UI uses Archive, explains retention before confirmation, and
removes archived courses from active management lists. No physical course,
order, enrollment, progress, media or audit deletion is added. Archival follows
publication authority: current super-admin with AAL2; content-manager assignment
alone cannot unpublish a live course by archiving it. The original authoring
migration remains unchanged; a second additive migration supplies archival.

Acceptance: real authorized create/update/publication/curriculum commands,
approved course removal behavior preserving protected history, current combined
Flutter/backend/database evidence, self-review and a reviewable PR. No DONE claim
before required acceptance. Approval authority remains the project owner.

## Fresh combined verification

- Existing integrated course repository/editor suite plus archive transport:
  60 Flutter tests passed; the new archive confirmation/history/revision widget
  regression passed separately (61 distinct cases across these runs).
- Authoring/publication Node handlers: 75 passed, no skips. The new archive
  regression first failed with HTTP 400 because the operation was absent; it
  passed after the reviewed archive RPC was connected.
- Disposable PostgreSQL 17: all 42 migrations replayed; course authoring,
  publication and archival SQL suites passed. Archival first failed because its
  RPC was missing before the additive migration, then passed afterwards. Tests
  compare complete order/enrollment/progress/curriculum/media rows, role/MFA
  denials, revisions, idempotency and immutable audit. No hosted database used.
- A broader native replay attempt reached an unrelated Storage test requiring
  managed bucket grants absent from the synthetic bootstrap. It is not reported
  as a full database pass. Managed Supabase CI remains the broader database gate.
- Formatting checked 351 Dart files with zero changes; whitespace checks passed.
- Full local analyzer was stopped after stalling without diagnostics; an earlier
  analyzer attempt in the sibling integration worktree crashed creating a Windows
  Dart worker thread. Neither is a clean analyzer result. Hosted analysis, full
  Flutter/Chrome suites and release build remain required PR checks.

## Review handoff

Draft [PR #201](https://github.com/iamramishka/acendra/pull/201) is open against
dev. Both required hosted jobs executed zero steps and report an account
payment/spending-limit block; neither is a code-test failure or a passing check.
Vercel preview passed. No billing/protection/workflow setting was changed.

The dependent [PR #202](https://github.com/iamramishka/acendra/pull/202) integrates
the committed owner UI changes with this exact implementation. Its combined
verification passed 197 focused Flutter cases, 43 migrations and six affected
SQL suites, including the new archive and avatar/profile isolation boundaries.
All 366 combined Dart files pass formatting. The earlier local analyzer
limitations remain explicit. Merge/release and real managed-service acceptance
remain pending; no hosted activation or live data cleanup was performed.

Final standalone `flutter analyze --no-pub` rerun: **no issues**, exit 0 (47.5s).
The earlier stalled run is historical, not relabeled. Combined #202 source also
passes default analysis (28.8s) and the standard release web build (345.3s),
including the normal Wasm dry run. Its existing Cupertino font warning remains.
After two brace-only profile lint fixes, all 17 affected profile tests passed
again; the preceding 197-case combined run and six SQL suites remain recorded
with their exact scope. Hosted full suites/approval and managed-service acceptance
remain separate requirements.
