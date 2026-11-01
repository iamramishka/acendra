# CSA-267: bind media selection and preview to the original session

Date: 2026-11-01, Asia/Colombo. Owner: CODEX. Status: IN_REVIEW.
Issue: [#193](https://github.com/iamramishka/acendra/issues/193).
Branch: `fix/csa-267-session-boundary`; base: `3ba3954` from dev.
Isolated worktree: `C:/Users/ramis/.codex/worktrees/csa267-session-repair/acendra`.

## Reproduced defect

The media control guarded course/lesson changes, but not session changes. An
account could open the native picker, change session, then return a selection.
The repository snapshots its session only when upload starts, so that selection
would dispatch using the later session. The control also retained local artwork
preview bytes and success/error state after a session change.

RED: a widget regression switched from synthetic admin A to admin B while the
picker was pending. Expected zero upload calls; unchanged production code made
one call. This proves stale UI dispatch, not a bypass of trusted backend access
checks. Backend authorization remains required for every real upload/finalize.

## Repair and scope

Snapshot the starting user/token before opening the picker. Recheck that identity
and operation generation before dispatching upload or showing any async result.
Listen for user/token changes to invalidate pending UI work and clear preview,
busy and status state. Signed-out controls cannot open the picker. A new session
can explicitly select a new file; old completions cannot restore its predecessor's
preview or status. Token refresh is conservatively treated as a session change,
matching the repository's existing token-sensitive upload contract.

Only the media-control widget, its test file and this record change. Existing
course/lesson target guards remain intact. Repository, SQL, server authorization,
inspection policy, migrations, dependencies and workflows are unchanged. This
does not cancel a request already sent to the backend; existing repository and
trusted backend checks remain authoritative. No live account, upload, payment,
private object or hosted setting was changed during verification.

## Verification

The four focused upload/artwork suites pass **32 tests**, zero skips. Thirteen
new cases cover signed-out picker denial and account/logout/token changes during
picker, upload, preview and error phases. New explicit selections after account
or token replacement still dispatch normally. Existing transport/session checks,
authenticated draft preview, stale course targets, failure messages and responsive
390/768/1440 light/dark cases remain active. Fixtures are synthetic.

Commands: locked `flutter pub get --enforce-lockfile`; `flutter test --no-pub`
with `media_upload_control_test.dart`, `admin_media_repository_test.dart`,
`admin_course_thumbnail_test.dart` and `admin_artwork_repository_test.dart`.
Changed Dart files were formatted and `git diff --check` passed. Changed-file
analysis found no issues; all 22 adjacent course-publishing journey tests passed.
Total focused native checks: 54 passed, zero skips. Full
hosted CI and approving review remain required before normal dev integration.

## Fresh hosted inventory and remaining release gates

Read-only Supabase management metadata on 2026-11-01 confirms upload prepare and
finalize functions ACTIVE v5 and artwork ACTIVE v2. The secret-name inventory has
no inspector URL/key or matching media-policy setting. No secret values were
printed or committed; the current service cannot be certified ready for real
inspected uploads. This task does not install or activate a scanner.

Original [PR #197](https://github.com/iamramishka/acendra/pull/197) is merged and
its merge is an ancestor of this base; earlier CI/merge blockers are historical.
Real signed Storage transport, deployed full-signature scanner, managed
revocation/replacement and policy acceptance remain the separate release gates
in [the deployment contract](../deployment/CSA-267-MEDIA-INSPECTOR.md). Synthetic
widget tests and a source merge do not establish those capabilities. Vercel is
excluded from deployment testing per the owner's later server-only decision.
