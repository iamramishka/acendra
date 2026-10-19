# PR 185–188 review remediation

Date: 2026-10-19 (Asia/Colombo). Owner: CODEX. Status: IN_PROGRESS.
Authority: the project owner requested fixing the reported PR findings and reviewing again; earlier merge-if-clean authorization remains subject to required approval and checks.

Root branch: fix/csa-265-pr186-review. Isolated worktree: C:/Users/ramis/Downloads/Acendra/review-pr186-20261019. Base: PR 186 d996e6f6de9dc186d0a8bf08ce8d01228fdae9e0. Related issue: #183 (CSA-265). Existing PR heads and worktrees were checked before changes. The primary checkout's unrelated edits are excluded.

Root scope: settings sign-out and tests; auth input/configuration and affected tests only after a supported password decision; task/decision evidence; deliberate integration of the learning fixes and propagation into PR 185. Temporary shared ownership is limited to supabase/config.toml and directly affected auth tooling tests if policy alignment is authorized. No financial migration, runtime payment contract, provider settings or deployment changes.

Independent worker ownership:
- Learning worker: fix/csa-265-learning-review in fix-pr186-learning-20261019; learning provider/workspace and regression tests only. Integrate its commit sequentially.
- Dependency worker: PR 188 review worktree and fix/csa-pr188-dependency-review; pubspec.yaml, lockfile and its task record only. Restore the compatible build_runner pin while preserving the other upgrades.
- Verification worker: read-only backend-policy feasibility and second review.

Password decision: after verification that Supabase enforces a six-character floor, the owner explicitly selected **six characters without a strength/composition rule**. This supersedes the earlier five-character request and the previous eight-character letter-and-number decision. Align client/local configuration and tests; no hosted Auth change is authorized or needed from a dated snapshot alone.

Acceptance: settings sign-out navigates on success and reports failures; displayed lesson and URL/history remain consistent; URL lesson requests cannot cancel initial progress loading; PR 185 browser expectations match the approved tabs; PR 188 restores locked dependencies on Flutter 3.44. Current-head format, analysis, focused regressions and hosted CI are required before a clean review verdict. PR 187 has no code findings and remains subject to required approval.

Verification: regression tests first where practical, focused suites at low concurrency, fresh independent review of the resulting changes, and current-head CI. SDK/pub restoration is serialized across worktrees. Source changes remain IN_REVIEW until required checks and approval are satisfied.
