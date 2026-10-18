# CSA-DASH-001 Phase 2

Owner: CODEX. Status: IN_REVIEW. Authorized by project owner on 2026-10-17.
Issue: https://github.com/iamramishka/acendra/issues/173.
Branch: feat/csa-dash-001-student-home; same-task continuation of PR #174.
Worktree: C:/Users/ramis/.codex/worktrees/student-home-phase1/acendra.
Dependency: Phase 1 models/fixtures at 6f38f1f (open in the same PR).

Scope: dashboard widgets, centralized presentation copy, widget tests, this
handoff and bounded TASKS.md reconciliation. No overlapping open task/PR was
found before edits. No router, shell, backend, dependency or shared model edits.
Owner retains merge/release authority. No delegation or deployment.

Acceptance: carousel, category chip/row, featured course card/grid, Why Learn
section; theme tokens, responsive layouts, readable empty states, semantic
controls, formatted prices, safe timer disposal and reduced motion. Category,
course, CTA and View All navigation is supplied via callbacks for Phase 3/4.
Absent callbacks disable actions; synthetic IDs never trigger backend requests.

Implementation choices: natural-height Wrap layouts replace fixed-ratio grids
to preserve readability at enlarged text. Course cards reuse CourseThumbnail
gradient placeholders. Icon enums map to Material icons in presentation only.
Hero height measures slide copy at the current width/text scale. Autoplay pauses
on focus, hover, background lifecycle, disabled TickerMode or reduced motion;
manual paging and explicit pause are available. No visible Home route exists yet.

Verification: dashboard/test formatting passed; full flutter analyze --no-pub passed with no issues; all 18 dashboard widget tests passed. Tests cover both themes at 320/390/600/768/1024/1440 widths and 200% text scale, responsive column placement, empty states, keyboard activation, identity callbacks, formatted prices, background pause/resume, auto advance, selected dots, explicit pause, reduced motion, collection shrink and timer disposal. Shared routing/shell/backend files remain untouched. Hosted checks run on PR #174 after push. Temporary registry ownership is released for review. Remaining work: Phase 3 screen composition and Phase 4 navigation wiring; visual browser acceptance follows integration. No merge performed.
