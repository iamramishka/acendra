# COM-001-005 prototype alignment merge review

Date: 2026-10-18. Owner: CODEX for bounded review/integration only.
Status: IN_PROGRESS.

Authorization: the project owner requested checking and merging the current
`feat/com-001-005-prototype-alignment` branch into `dev`, and explicitly selected
that branch when asked to distinguish it from open PRs 181/182.

- Source snapshot: `77ab5487cced19346c583eebff2acd88aab25f34`.
- Integration branch: `test/csa-265-com001005-review`.
- Worktree: `C:/Users/ramis/.codex/worktrees/prototype-alignment-review/acendra`.
- Target: `dev`, starting at `0b027523ad38a756e6b6a40e0d8d30133a97fc19`.
- Scope: inspect and verify the existing auth/navigation commit; integrate the
  current base; this review record and independently scoped verification only.
  No source-owner reassignment or production policy/configuration is implied.
- Dependencies: existing Supabase Auth repository and trusted backend remain
  authoritative; existing app router, theme, design and auth contracts.
- Ownership checks: open PRs 181/182 are outside scope. Issue 183 / CSA-265 is
  separately owned by CODEX in another worktree for COM-005-010, based on this
  snapshot. Its active source files, task registry and branch are not edited by
  this review. COM identifiers are audit references, not a new GitHub task claim.
- Shared files: navigation shells are read/reviewed as part of the source
  snapshot, without claiming a new shared-file implementation lock. No theme,
  router, manifest, migration or workflow edits are authorized by this record.
- Verification: review the full diff and auth lifecycle, navigation, validation,
  cooldown and responsive behavior; formatting, analyzer, Flutter tests, browser
  route checks, release build and applicable tooling tests. Record actual
  outcomes and limits; do not claim pixel matching or hosted Auth verification.
- Approval: project owner/designated maintainer controls final integration;
  GitHub CI/current-base and review requirements remain in force. Prior admin
  override authorization was specifically for PRs 177/179/180.

## Evidence and outcome

### Coordinated correction authorization

After seeing the reproduced overflows and the active Issue 183 overlap, the
project owner explicitly selected "Fix here, then merge". This authorizes a
bounded correction in this isolated review branch. Temporary writable scope is
extended to `lib/core/widgets/navigation/auth_shell.dart`,
`lib/core/widgets/buttons/app_button.dart`,
`lib/features/authentication/presentation/widgets/auth_form_widgets.dart` and
`test/reviews/com001005_merge_review_test.dart`, plus this record. Ownership is
limited to responsive header/hero/button rendering and its tests; Issue 183's
remaining implementation, branch and worktree are not modified. Its owner must
incorporate this reviewed correction during subsequent base integration.

Integrated current `dev` cleanly using normal merge `9a01752`.
Baseline source formatting passed: 297 files, zero changes.

The bounded review probes reproduce a merge-blocking responsive regression at
320 logical pixels with 200% text scaling. Registration throws three render
overflows: the header row at `auth_shell.dart:36` overflows 64 pixels, the fixed
height hero's column at `auth_form_widgets.dart:34` overflows 262 pixels, and the
icon-bearing submit button row overflows 203 pixels. The first two belong to
changed header/hero code; the new registration button also exposes the shared
button's unbounded label row. Existing tests miss this combination.
Reproducer: `test/reviews/com001005_merge_review_test.dart`;
log: `C:/Users/ramis/AppData/Local/Temp/acendra-com001005-review-probes.log`.

The other two review probes passed: signup navigates to verification with the
pending email preserved and masked; opening a lesson directly then pressing
back safely reaches My Courses. A proposed correction would let the header
and hero adapt to width/text size and let icon-bearing button labels wrap.
It requires temporary shared-file ownership for `auth_shell.dart` and
`app_button.dart` and coordinated ownership of the common auth widget in active
Issue 183's broader scope. No source correction has been made or source-owner
task taken over by this review.

Analyzer reported one const hint in the new review probe; that probe-only hint
was corrected. No source analyzer diagnostic was reported. The full Flutter
suite is running, including the reproducer; no clean-suite claim is made.
The remote prototype could not be opened through the web tool, so exact visual
fidelity is not verified. Backend Auth, hosted settings and consent storage
remain unchanged; this review does not assert deployed password policy or
legal-consent implementation.

## 2026-10-18 resolution in the authorized CSA-265 takeover

The preceding sections preserve the original RED review record. The owner subsequently authorized the bounded source corrections, then authorized takeover of issue #183 and reconciliation with PR #185. The corrected auth header, hero and button were copied from this review worktree into the assigned CSA-265 integration worktree, preserving the originals. The corrections now pass the original signup/navigation probes and the 56-case light/dark, 320/390/768/1440-width, 200% text matrix. Exact comparison with the unavailable remote prototype remains unverified.

Current implementation owner, integration scope and final verification are tracked in docs/tasks/CSA-265.md and issue #183. This historical record does not claim a merge or production activation.
