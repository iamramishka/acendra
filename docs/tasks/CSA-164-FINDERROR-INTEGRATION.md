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
