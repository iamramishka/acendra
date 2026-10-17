# CSA-DASH-001 Phase 4

Owner: CODEX. Status: IN_REVIEW. Authority: project owner, 2026-10-18.
Issue #173; same-task PR #174, branch feat/csa-dash-001-student-home.
Worktree: C:/Users/ramis/.codex/worktrees/student-home-phase1/acendra.
Dependency: Phase 3 73d0ae0 and earlier phases on this branch.

Temporary shared ownership: route_names.dart, app_router.dart, StudentShell,
associated router/shell tests and bounded TASKS.md phase entry. Additional scope:
dashboard copy, Saved placeholder screen, navigation tests and this handoff.
Open Issues/PRs and task boards checked before edits; no active conflicting owner
found. No delegation. Phase 5 branding/search, backend and dependencies excluded.

Acceptance: /dashboard redirects to new authenticated /dashboard/home within
StudentShell; four tabs Home/My Learning/Saved/Profile use correct routes and
selected indices, including profile edit. Saved has no existing implementation:
/dashboard/saved explicitly announces coming soon and links to marketplace,
without implying saved records or persistence. Default navigation guards apply
to both new routes. Existing Explore/account/admin controls are retained.

Compact navigation also covers tablets below 1024 and enlarged desktop text to
avoid a crowded header. Desktop links expose Home, My Learning, Saved and Explore;
Profile remains reachable through the existing account menu. No app-bar branding
or search changes. StudentShell continues to bound routed scroll views.

Verification: formatting and full Flutter analysis passed. Targeted VM run passed all 49 dashboard tests plus shell/route regressions; six account-popup tests initially needed a more specific selector because Profile now also appears in navigation. All 14 account-menu tests passed after that correction. Chrome app-router guard/integration command compiled to the loading stage but produced no test results and was interrupted; this is unverified, not a pass. Its expanded authenticated/anonymous deep-link and real-tab regressions must pass before acceptance. Temporary registry ownership is released at review handoff; the browser verification limitation remains explicit for review. Current-head hosted CI follows push; standard VM CI alone does not establish browser-only guard acceptance. Owner retains merge/release authority; no merge performed.
