# PR #188 dependency review repair

- Owner: CODEX, PR #188 dependency repair worker.
- Status: IN_REVIEW (2026-10-19).
- Authorization: project owner's request to fix review findings and review again; parent coordinates the original merge-if-clean request targeting dev.
- Related PR: https://github.com/iamramishka/acendra/pull/188
- Baseline: 6e0bc16b7e56367951d9b823288d82360196efd0.
- Branch: fix/csa-pr188-dependency-review.
- Worktree: C:/Users/ramis/Downloads/Acendra/review-pr188-20261019.
- Writable scope: pubspec.yaml, pubspec.lock, and this task record only.
- Temporary shared-file ownership: pubspec.yaml and pubspec.lock for PR #188 repair only; assigned exclusively by the coordinating parent. Other PR repairs use isolated worktrees.
- Prerequisites: existing full dependency diff reviewed; original Flutter CI run 39195728154 confirms a dependency solve failure; clean isolated worktree confirmed before edits; parent grants exclusive local Flutter SDK/pub cache operations for restore.
- Dependencies: Flutter 3.44.0 and its SDK-pinned packages; retain go_router 18.1.0 and supabase_flutter 2.18.3 updates.
- Approval authority: project owner; parent performs independent review, remote-head verification, publication and merge decisions.

## Finding and repair plan

The build_runner 2.16.2 update requires analyzer ^14.3.0 and meta ^1.18.3, which conflicts with Flutter 3.44.0 flutter_test's meta 1.18.0 pin. Restore build_runner 2.15.1 and regenerate the lockfile with the supported SDK. Do not change application source or add dependencies.

## Verification criteria

1. Flutter 3.44.0 restores dependencies successfully.
2. flutter pub get --enforce-lockfile succeeds with the generated lockfile.
3. Analysis and proportionate existing routing/authentication tests pass, with any environment limits recorded.
4. Diff retains the requested go_router and Supabase upgrades and contains no unrelated changes.
5. Independent review and required remote CI remain integration gates.

## Evidence

Restored build_runner 2.15.1 and regenerated the lockfile using Flutter 3.44.0.
The go_router 18.1.0, supabase_flutter 2.18.3, supabase 2.16.5 and realtime_client
2.13.2 upgrades remain. Generator/SDK transitive packages return to the compatible
versions selected by the supported SDK. No application source changed.

Initial `flutter pub get` and `flutter pub get --enforce-lockfile` completed
successfully before the interrupted session. A later locked-restore retry reached
successful resolution but its Dart process then exhausted Windows memory; that
retry is not a passing command. Local analyzer/tests did not complete. Current-head
hosted CI must supply complete analysis, tests and build evidence. `git diff
--check` passed; the manifest/lock diff was independently inspected against dev.
