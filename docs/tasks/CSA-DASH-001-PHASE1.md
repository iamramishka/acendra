# CSA-DASH-001 Phase 1

Owner: CODEX. Authority: project owner requested Phase 1 on 2026-10-17.
Coordination: https://github.com/iamramishka/acendra/issues/173.
Status: IN_REVIEW.
Branch: feat/csa-dash-001-student-home; base dev f761369.
Worktree: C:/Users/ramis/.codex/worktrees/student-home-phase1/acendra.

Scope: new dashboard entities, offline sample data, four Riverpod providers,
this handoff and a bounded TASKS.md registry entry. No overlapping open issue,
PR or dashboard branch was found before claiming. Existing marketplace entities,
router, shell, dependencies, backend and subsequent phases are excluded.
Temporary TASKS.md ownership is restricted to this task's registry entry.

Dependencies: existing CourseSummary and Riverpod. Acceptance: three hero slides,
four categories, four to six demo courses with synthetic UUIDs/slugs and LKR minor
unit prices, four highlights, immutable models/lists and no network calls.

The category wrapper preserves the shared Category contract. Domain icons use
semantic enums; future widgets map these to Flutter icons. CourseSummary has no
thumbnail field and no marketplace thumbnail mapping exists; planned gradient
placeholders require no shared entity extension. Hero routes use the existing
/marketplace path without importing application routing into the data layer.

All courses explicitly identify themselves as demos. Synthetic IDs must not be
used for real detail/checkout requests or course access. Categories also need
live identity mapping before applying real marketplace filters.

Verification: dashboard formatting passed (five files); marketplace regression suite passed (31 tests). Full flutter analyze and focused dart analyze passed with no issues. The first focused analyzer attempt hit a local Dart perf-witness file error; retry with process-local LOCALAPPDATA succeeded. Self-review confirmed no network calls or shared application/model edits. PR evidence follows in the linked issue. No UI/build acceptance is claimed for this data-only phase. Temporary registry ownership is released at this review handoff. Review and
CI are required before merge; owner retains merge/release approval authority.
