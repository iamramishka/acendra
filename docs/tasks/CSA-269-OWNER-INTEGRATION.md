# CSA-269 — integrate committed owner changes with current dev

Owner: CODEX. Status: IN_PROGRESS. Authority: project owner requested fixing the
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
