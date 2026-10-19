# PR #197 integration with merged dev

Date: 2026-10-19 (Asia/Colombo). Owner CODEX; status IN_REVIEW.
Owner requested parallel review/fixes and merging into dev. Scope: deliberate
artwork integration in catalog/My Courses/course detail, preserved existing
media migration/configuration and validation evidence. Isolated csa267-recovery
worktree and existing PR #197 branch. Primary-checkout edits remain untouched.

Dev advanced to `3049c16e33d11d0547f0252ae5258ad2d48e21ee` during verification,
including PRs #185/#186/#187/#188. Two conflicts were inspected. Keep dev's
category-aware responsive catalog and My Courses progress/filter/resume tiles;
replace only their cover region with the validated artwork widget. Course
details now uses the same course-identity artwork URL. No old grids, progress
logic, routes or password rules are restored. The automatic config merge retains
both the six-character/no-composition policy and artwork function registration.

PR #196's implementation is included through the merged #186 source. Its only
remaining diff against dev's merge base is its reconciliation record; no unique
UI implementation needs another merge. Original branch history is preserved.

Pre-integration preview verification: 36 Flutter tests, 41 media Node tests,
clean analyzer/format and release build (324.2s including Wasm dry run) passed.
The existing Cupertino font warning remains. Repeat affected catalog/progress/
admin regressions, analysis and migration replay against the combined tree.
Do not claim earlier full-suite/CI evidence as a current combined-head pass.
Required CI and approval remain merge gates. No deployment or hosted migration.
