# Issue 164 integration ownership

Owner: CODEX root. Status: IN_PROGRESS. Authorized by project owner to fix reported thumbnails, admin course/student lists and account navigation in parallel and open one PR.
Issue: https://github.com/iamramishka/acendra/issues/164
Base: dev ae272329. Branch: fix/csa-164-admin-navigation-thumbnails.
Worktree: C:/Users/ramis/.codex/worktrees/csa164-repair-integration/acendra.

Parallel ownership: navigation worker owns navigation shells/menu/role provider and tests; thumbnails worker owns shared course cover/card/admin tile/row and tests; admin-data worker owns admin directory repositories/screens, Edge adapter, migration and tests. Each uses its previously assigned isolated worktree. Root owns integration, supabase/config.toml, package.json and this evidence record. No overlapping active GitHub PR was present at inspection. Existing root untracked assets and bug report are excluded.

Dependencies: existing authenticated role projection, reporting authorization helper and approved course/profile schema. Acceptance: authorized actual course/student records replace stubs, sandbox course is visible to authorized admin, all course cards have consistent cover fallback, avatar opens working profile/logout menu, current staff roles expose Admin navigation while ordinary/anonymous users do not.

Verification: focused tests from each worker, fresh integrated formatting/analyzer/full Flutter suite/release build, Edge contract tests and SQL permission regression. Review and production integration remain project-owner authority. No deployment or merge performed.

## Integration evidence — 2026-10-17

Integrated worker commits: navigation 39f0b1e, thumbnails 87cbf3e, directory d5ac8d6f. Root reviewed the combined diff and added endpoint registration, tooling test wiring and cursor continuation/repetition regression tests.

- Locked dependencies restored with flutter pub get --enforce-lockfile (exit 0).
- Integrated flutter analyze --no-pub: no issues (exit 0).
- dart format --output=none --set-exit-if-changed lib test: 262 files unchanged (exit 0).
- npm run tool:test: 787 total, 777 pass, 10 skip, zero failures (exit 0). Skipped suites require isolated external services; they are not claimed as verified.
- node --test supabase/functions/admin-directory/*.test.mjs: 15 pass (exit 0).
- Root independently reran csa164_admin_directory.test.sql with ON_ERROR_STOP against task-owned native PostgreSQL17: pass. Worker replayed all ordered migrations first. Auth/Storage schema shims do not establish hosted Supabase runtime acceptance. Task-owned database subsequently stopped.
- Initial full Flutter regression: 654 pass (exit 0). Final post-integration suite and release build evidence pending below.

## Release and scope limits

Deploy the migration and admin-directory Edge Function together; configure ACENDRA_ADMIN_ALLOWED_ORIGINS for the actual frontend. No live database, storage or deployment was changed. Student PII requires current super-admin authority and MFA; content managers see only assigned courses. Frontend Admin visibility never grants backend permission.

Missing artwork now has a consistent accessible title-based cover. This does not populate actual uploaded photos or expose opaque private thumbnail_path values. Actual artwork delivery remains a separate approved storage-delivery integration.

The admin Students directory no longer uses seed rows. Separate dashboard/payment providers still use placeholders and require their own reviewed reporting/list integration. Existing reporting release gates remain intact. Unwired course/account/enrollment mutations now fail with an explicit unavailable error instead of fabricated local success; verified financial totals are shown as unavailable, never invented zero.

Status: IN_REVIEW; owner approval, hosted CI and release acceptance remain required.

## Session-isolation review correction

Root-assigned follow-up commit 2cdedfd (integrated as 942b187) closes a P1 cache boundary found during review: repository providers depend on the current session, directory providers watch those repositories, prior searches cannot restore data after account changes, and search terms reset. Root inspected the implementation and independently ran all six session-switch/in-flight regressions: PASS (exit 0). This is client privacy isolation in addition to existing trusted backend authorization.

The combined suite initially identified one obsolete icon assertion after the intentional cover redesign (677 passed, one failed). Root replaced that assertion with the required missing-cover message and reran shared widget/directory tests: 20 passed. No production failure was hidden. Final integrated analyzer: no issues (exit 0); full formatting: 263 files unchanged (exit 0); diff whitespace check clean. Initial release build passed including Wasm dry run; it emits the existing missing Cupertino font warning. Final cache-change release rebuild omits only the already-passed Wasm dry run.

Documentation-only conflict during cache integration was resolved by retaining the navigation evidence and the cache scope/evidence addendum; no code conflict occurred.

## Final root verification

- flutter test --no-pub --reporter compact: 678 passed, zero failures (exit 0), final integrated sources. The six newly added session-isolation regressions were additionally executed directly against the final branch and passed (exit 0).
- flutter build web --release --no-pub --no-wasm-dry-run after session correction: PASS (exit 0). Earlier normal release build also passed its Wasm dry run. Existing Cupertino font warning persists; no dependency changes were introduced.
- Final flutter analyze --no-pub: no issues (exit 0). Final formatting: 263 files unchanged (exit 0). Final whitespace review clean.

Final status: IN_REVIEW. PR creation follows; hosted CI and authorized review remain separate acceptance gates. No production changes or merge performed.

## PR165 review follow-up ownership — 2026-10-17

Owner: CODEX root, authorized by project owner to review PR165 and fix confirmed issues. Reuse existing isolated integration branch/worktree; reviewed head 378ddf9 against origin/dev. No overlapping task or PR found; issue164 remains current coordination record. Review scope: changed directory client/provider/Edge/SQL boundaries and navigation/card behavior. Root temporarily owns changes and regression tests within those existing surfaces plus this evidence file. No deployment, merge, financial mutations or unrelated dashboard integration authorized. Acceptance: reproduce each confirmed issue, make bounded correction, verify negative/session tests and applicable checks, then update the same PR. Status: IN_PROGRESS.

Confirmed review finding: course list includes complete descriptions, so 20 valid 40KB descriptions overflow the Edge adapter 512KiB cap and make admin course listing unavailable. Root owns additive migration 20261017000200_csa164_directory_course_summaries.sql and SQL regression; original shared migration remains unchanged. Reproduction: native SQL regression failed with course list exceeds Edge response cap (psql exit 3).

Review findings and corrections:
- P1 availability: course pages included every full description and could exceed the 512KiB Edge response cap (20 legitimate 40KB descriptions reproduced the failure). Additive migration now returns empty descriptions in list summaries and retains full descriptions when requesting an individual course. No shared/applied migration was rewritten; grants and authorization remain unchanged. SQL regression failed before the correction and passed after it. Fresh disposable database replay: all 35 ordered migrations and the expanded directory authorization/size regression passed.
- P2 correctness: the initial AsyncNotifier build could finish after a newer search and replace the filtered results (deterministic failing test returned unfiltered@synthetic.test instead of the newer result). Searches/refresh now invalidate and rebuild through Riverpod's existing Future lifecycle. Obsolete values and failures are discarded; same-account rebuilds retain the search term, while logout/account switches reset it.
- Added regressions cover late initial success/failure, older search failure, same-account query retention and all previous session privacy cases. Focused directory/session/navigation suite: 46 passed (exit 0).
- Initial host test launcher stalled and its task-owned process tree was terminated. Using a task-local LOCALAPPDATA resolved the launch issue; the product regression then failed reproducibly before the fix and passed after it. No host setting was persisted.

No further concrete findings in the reviewed navigation/card or Edge authorization diff. Existing dashboard/payment and actual artwork-delivery limitations remain as documented; review does not authorize release-gate activation or deployment. Final full-suite/analyzer/build evidence follows after execution. Status: IN_REVIEW pending final checks and updated PR.

Follow-up static checks: full Dart formatting passed (263 files unchanged), analyzer passed with no issues, and all 15 directory Edge boundary tests passed. Full Flutter/release checks continue; their final results will be recorded in PR165's description. Review-fix scope is complete; status remains IN_REVIEW pending CI and owner acceptance.
