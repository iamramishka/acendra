# PR #186 learning review corrections

Owner: CODEX learning worker; coordinating CODEX completed the handoff after an
interruption. Status: IN_REVIEW. Date: 2026-10-19.
Authorization: project owner requested fixes and another review of PRs #185–188;
the coordinating CODEX agent assigned the two learning findings exclusively here.
Base: PR #186 d996e6f6de9dc186d0a8bf08ce8d01228fdae9e0.
Branch: fix/csa-265-learning-review.
Worktree: C:/Users/ramis/Downloads/Acendra/fix-pr186-learning-20261019.

Writable scope: learning_provider.dart, learning_workspace_screen.dart, bounded
learning regression tests, and this record. No auth, settings, router, dependency,
financial, global-token or deployment changes. Parent owns integration into the
PR branches and final review; this worker does not push or merge.

Acceptance: a URL lesson requested during curriculum/progress loading preserves
the progress read and wins over the saved resume lesson; the latest requested
lesson wins. Sidebar, previous/next and completion navigation update the lesson
URL. Restored browser history entries select their addressed lesson. Existing
module/course completion navigation and direct MaterialApp harnesses still work.
Backend authorization and fail-closed progress writes remain authoritative.

Verification: deterministic delayed-read regressions first, browser route/content
regressions through the existing browser harness, affected learning tests,
formatting, analysis and self review. Serialize Flutter SDK/cache use with the
coordinator; no installs or overlapping Flutter work while another worker owns it.
Record actual RED/GREEN evidence below before handing off a bounded commit.

Implemented queued URL requests through initial progress loading, latest-request
selection, lesson route updates, retained widget updates and mobile drawer closure.
The first local RED attempts failed at Dart VM memory allocation, so no product
failure is claimed from those attempts. After serializing verification, all 43
affected learning tests passed in the integrated PR 186 worktree, including the
three deterministic request-timing regressions. The browser harness uses the
supported GoRouter route-information provider API; its first compile exposed an
unsupported Flutter test-binding helper, which was corrected. Browser execution
and required CI remain separate gates. No payment/access authorization changed.
