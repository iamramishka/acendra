# CSA-269 — integrate committed owner changes with current dev

Owner: CODEX. Status: IN_REVIEW. Authority: project owner requested fixing the
finderror review's remaining source/integration issues and opening PRs on
2026-10-20 (Asia/Colombo).

Branch: `fix/csa-269-owner-changes-integration`.
Worktree: `C:/Users/ramis/.codex/worktrees/csa269-integration/acendra`.
Base: published dev `d46ae1c`; incoming immutable primary snapshot `31aaddc`.
The primary checkout and `.claude/` worktrees are excluded from writes.

Scope: deliberately integrate the three committed owner changes after the
incoming branch's merge base, fix resulting compatibility/regression failures,
and reconcile finderror status. Preserve current-dev payment reporting, artwork,
course progress, six-character password policy and existing security contracts.
Temporary shared ownership is restricted to actual integration conflicts and
the finderror report/evidence. No overlapping open PR exists at claim time.
CSA-268 owns course authoring; this PR does not duplicate its implementation.

Dependencies: merged PRs #194/#197 and owner commits `26a8e1b`, `6d08ed1`,
`31aaddc`. Approval authority: project owner. No deployment, hosted activation,
account/data cleanup, live payment or production approval is included.

Acceptance: preserve committed owner work; resolve conflicts deliberately;
retain trusted reporting/artwork; pass focused regressions, formatting, analysis,
affected integration checks and release build; submit a reviewable PR with
honest remaining limitations. Existing live acceptance remains under #193/#160.

Integration fixes include the incoming avatar's previously unused image URL,
pending-picker/account-switch and disposed-form behavior, plus the catalog
grant matrix's narrow approved avatar-column addition. New negative SQL checks
cover own/foreign avatar storage and profile paths; no protected role/financial
column becomes writable. The unmerged incoming avatar migration is renumbered
after the current source chain to keep release ordering append-only. Its SQL
contents are preserved. Verify the hosted ledger before any later deployment;
this task does not apply it or change existing hosted migration history.

Deliberate conflict decisions: retain dev's six-character reset/recovery and
change-password flow; retain responsive hero layout with incoming gradient;
combine shared filter chips with current Online/Bank methods and omit fictitious
administrative payments; combine incoming course-card presentation with current
artwork identity, progress and resume paths; keep incoming sign-out presentation
with dev's error handling and login navigation. Incoming profile, language
preference, PDF contents sheet, logo and local seed changes are preserved.

## Integration evidence and PR dependency

The first integration run executed 219 focused Flutter cases: 217 passed and
two curriculum tests exposed duplicate Add Section controls from the incoming
empty-state CTA. The trusted CSA268 builder was then deliberately integrated
from exact PR201 head `00859fd`, retaining its original revision/session/parent
contracts and a single Add Section action. Its default medium buttons retain
the incoming touch-size improvements. No blanket conflict resolution was used.

This PR is stacked on [PR #201](https://github.com/iamramishka/acendra/pull/201),
whose immutable source history is included. Review this PR against its course
completion branch; merge #201 first and retarget this PR to dev before final
integration and required CI. The original owner and CSA268 worktrees are not
modified. Combined source verification follows below.

Before the course merge, 41 migrations and three affected PostgreSQL suites
passed: avatar isolation, existing symmetric profile isolation and the catalog
permission matrix. The matrix first failed on the new avatar_path grant; its
allowlist now names that one intended column and asserts a validated own-folder
constraint plus a private bounded bucket. Other protected columns remain denied.
Native Auth/Storage are synthetic and do not establish hosted acceptance.

## Final combined checks

- Functional combined source: `7f8ae80`; two later profile guards received
  braces only to satisfy the default analyzer. Their behavior is unchanged.
- `flutter test --no-pub --concurrency=1 test/features/admin
  test/features/profile/avatar_session_test.dart
  test/features/profile/presentation/screens/profile_screen_test.dart
  test/features/my_courses test/features/settings --reporter expanded`: exit 0,
  **197 passed**. Both original duplicate-action failures now pass. The added
  profile account-switch/disposal regressions pass. Earlier navigation, recovery,
  artwork, reporting and PDF cases are retained as incremental evidence above;
  this is not a claim that the earlier failed invocation was green.
- All **43 migrations** replayed together in a new disposable PostgreSQL 17
  cluster; **six SQL suites passed**: course authoring, publication, archival,
  avatar isolation, profile isolation and the catalog permission matrix. Native
  Auth/Storage shims do not certify a managed-service deployment.
- `dart format --output=none --set-exit-if-changed lib test`: exit 0, **366 files**,
  zero changes. `git diff --check` passes.
- PRs: [#201](https://github.com/iamramishka/acendra/pull/201) and the dependent
  [#202](https://github.com/iamramishka/acendra/pull/202), both draft. Both required
  #201 jobs executed zero steps: their annotations report failed account payments
  or a spending-limit block. Vercel previews passed. No billing or protection
  setting was changed. #202's stacked base is outside the existing dev/main CI
  event filter; retarget to dev after #201 merges and require checks there.
- Local full analysis crashed creating a Windows Dart worker thread in this
  worktree; the separate course-worktree analyzer stalled and was stopped. No
  clean analyzer/full Flutter/Chrome CI result or production acceptance is
  inferred. Release-build outcome is recorded separately below when available.

Final combined Node handlers: **75 passed**, zero skips/failures, exit 0.
Standard `flutter build web --release --no-pub`: **passed**, exit 0 (345.3s),
including the normal Wasm dry run. The existing missing Cupertino icon-font
warning remains; it is not hidden by adding a dependency. The combined source
compiles for release; this is not a deployed-environment acceptance claim.

After host memory became available, default `flutter analyze --no-pub` completed
and identified two missing-block lints in the new profile guards. Adding braces
fixed those without suppression; the fresh default rerun passed with **no issues**
(28.8s, exit 0). The earlier Windows failures remain historical evidence and are
not relabeled as passes. Affected profile tests were rerun after this lint-only
change; no observable behavior or API changed. Hosted full Flutter/Chrome and
managed Supabase CI remain required and are not replaced by these local checks.

Final post-lint profile rerun: **17 tests passed**, exit 0, covering dirty-field
discard, pending picker account/logout/disposal, same-account refresh, rendering,
save success/failure, language preference and photo upload/cancellation/errors.

The primary checkout advanced independently after snapshot `31aaddc`; those later
local changes are not silently copied into this PR. Original worktrees and the
primary checkout remain untouched by this task. No source merge, deployment,
hosted activation, sandbox cleanup or production acceptance was performed.
