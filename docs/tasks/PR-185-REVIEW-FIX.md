# PR 185 review remediation

Date: 2026-10-19 (Asia/Colombo). Owner: CODEX. Status: IN_REVIEW.
Authority: owner requested fixing the reported findings and reviewing again.
Branch: fix/csa-265-pr185-review. Isolated worktree: review-pr185-20261019.
Baseline: 6a1c55519480b1fb555f59f6ec6bec666e7b4761. Related issue: #183.

Scope: propagate the reviewed learning fixes from the separate PR 186 repair;
repair Settings sign-out and browser tab expectations; align password client,
local configuration, operator guidance and affected tests to the owner's final
six-character/no-composition decision. Temporary shared ownership covers only
the browser router test and local Auth settings/tool guards. The primary
checkout and its unrelated edits are excluded. No hosted setting changes.

The cherry-pick conflict in workspace initialization was inspected: PR 185
requested a lesson during mounting; the integrated repair defers it until after
the frame and queues it while initial progress is loading. The full reviewed
workspace retains that lifecycle repair. The new browser harness is intentionally
added and registered in the existing router test. Other PR 186 checkout/catalog
changes are not copied into this PR.

Acceptance: lesson URL/history and content agree; progress remains usable after
late URL requests; sign-out navigates or reports failure; five-character inputs
are rejected and six-character inputs have no composition rule; browser tests
use Home/Explore/My Courses/Profile. Independent verification and required CI /
approval remain gates. Local Windows Flutter attempts previously exhausted
memory; only completed checks will be reported as passing.
