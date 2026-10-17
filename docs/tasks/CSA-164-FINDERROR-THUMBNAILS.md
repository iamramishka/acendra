# CSA-164 finderror thumbnail repair

Owner: CODEX thumbnail worker, delegated by integration owner for GitHub #164.
Status: IN_REVIEW
Branch: fix/csa-020-021-course-thumbnails
Worktree: C:/Users/ramis/.codex/worktrees/course-thumbnails/acendra
Base: dev ae272329
Scope: shared course thumbnail widget, CourseCard, admin course tile/row and tests.
Shared ownership: core/widgets thumbnail and card files assigned exclusively to this worker; navigation excluded.
Dependencies: existing Flutter design tokens; no new dependency or API contract.
Approval authority: project owner; integration/review remains required.
Acceptance: consistent course-specific missing-artwork cover; trimmed valid URL rendering; loading/error fallback; 16:9 crop and semantic description; themes and compact layouts.
Security: thumbnail_path is an opaque private storage reference, not a URL. No public URL construction or storage policy changes.

Verification: 41 tests passed across course_thumbnail_test, course_card_test and admin_course_publishing_journey_test. Targeted flutter analyze: no issues. Dart formatting and git diff --check passed.
Limitation: missing artwork uses a course-specific generated cover; actual uploaded artwork delivery remains dependent on an approved public-thumbnail delivery contract. No private storage path is requested as a public image.
