# CSA-DASH-001 Phase 3

Owner: CODEX. Status: IN_REVIEW. Authorization: project owner, 2026-10-18.
Issue: https://github.com/iamramishka/acendra/issues/173; PR #174 continuation.
Branch: feat/csa-dash-001-student-home.
Worktree: C:/Users/ramis/.codex/worktrees/student-home-phase1/acendra.
Dependencies: Phase 1 6f38f1f and Phase 2 bc28a09, same open PR.

Scope: dashboard screen, presentation providers/copy, dashboard tests, this
handoff and bounded TASKS.md entry. No overlapping task or PR found before edits.
No router, shell, backend, dependency or shared marketplace edits. Temporary
registry ownership covers phase/status reconciliation only. No delegation.

Acceptance: ConsumerWidget composes all four dashboard sections; all four source
providers feed an asynchronous composition provider for loading/error/retry.
Offline data remains explicitly disclosed as sample content. Existing marketplace
navigation works from CTA/View All; default sample-category/course actions show
preview explanations and never request demo IDs. Optional callbacks expose
identity-preserving hooks for future integration. Theme tokens, bounded content
width, scrolling, empty states and accessible loading feedback are retained.

This phase adds no Home route or StudentShell changes; those remain Phase 4.
Async composition introduces no network calls. Error text is fixed public copy.
Project owner retains review/merge/release authority. Verification: formatting and full flutter analyze --no-pub passed; all 32 dashboard tests passed (14 screen and 18 widget tests). Screen tests cover all four source overrides, pending-to-empty state, sanitized errors, composition/source retry, marketplace CTA/View All navigation, safe preview actions, callback identities, and both themes at 390/768/1440 with 200% text and scrolling. Phase 2 hosted CI also passed before this continuation. Self-review confirmed the writable scope and no shared application edits. Current-head hosted CI follows the PR push. Temporary registry ownership released at this review handoff. Remaining: Phase 4 routes/shell integration and later browser visual acceptance. No merge performed.
