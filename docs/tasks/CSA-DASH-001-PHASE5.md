# CSA-DASH-001 Phase 5

Owner CODEX; IN_REVIEW. Authority: project owner, 2026-10-18. Issue #173,
PR #174, branch feat/csa-dash-001-student-home; isolated worktree
C:/Users/ramis/.codex/worktrees/student-home-phase1/acendra.
Dependency: prior phases through b5adf0a.

Temporary shared ownership: StudentShell, optional AccountMenu icon argument,
app_router.dart marketplace builder, marketplace screen/providers for focused
search, dashboard copy and related tests (including test/features/responsive_layouts_test.dart for obsolete Phase 4 expectations); bounded TASKS.md entry and this handoff.
No overlapping open Issue/PR found before edits. No delegation.

Acceptance: existing logo plus wordmark, accessible search and menu actions,
preserved theme/account/profile/admin/logout behavior and responsive themes.
Search opens /marketplace?search=true; router passes focusSearch to the screen.
An intent counter supports repeat taps even on that same URL without changing
query or category state. Marketplace owns/disposes its FocusNode; loading data
can finish before initial autofocus. Ordinary entry does not steal keyboard focus.
AccountMenu retains its default avatar API; StudentShell supplies the menu icon.
Brand row scales down to fit constrained app bars without overflowing controls.

No logo asset, backend, dependency or authentication changes. Prior Phase 4
browser-only guard verification limitation remains. Owner retains merge/release
authority. Verification: formatting and full Flutter analysis passed. Dashboard/marketplace/navigation suite passed 113 tests, including first/repeated search focus, delayed data, ordinary entry, unchanged query, logo/wordmark, 320-1440 widths, both themes and 200% text; responsive-layout suite passed 34 tests (147 total). Previous Phase 4 hosted run failed four assertions expecting old two-tab/768px navigation; these now assert the approved four-tab and tablet compact behavior. No application behavior was weakened to satisfy tests. Current-head hosted CI follows push. Temporary shared ownership released at review handoff. Phase 6 and browser-only guard acceptance remain; no merge performed.
