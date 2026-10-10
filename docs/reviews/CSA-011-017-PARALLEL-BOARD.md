# Phase 0 parallel review board

Date: 2026-10-11 (Asia/Colombo). Base: `9355311` on `dev`.
Authority: the project owner requested CSA-011, 012, 013, 014, 015 and 017 in parallel. CODEX owns preparation; the project owner retains decision approval. This explicitly authorizes CODEX preparation for CSA-014 despite its suggested CLAUDE label.

No open GitHub issues were returned by `gh issue list --state open --limit 100`. This board records local assignments, not fabricated GitHub assignments. Existing mutable UI files in the primary checkout are outside scope.

| Task | Preparation owner | Initial status | Exclusive writable scope | Branch / worktree |
| --- | --- | --- | --- | --- |
| CSA-011 | CODEX video-budget agent | IN_PROGRESS | docs/decisions/CSA-011-VIDEO-PROVIDER.md | codex/docs/csa-011-phase0-review / C:/Users/ramis/.codex/worktrees/csa-011-phase0/acendra |
| CSA-012 | CODEX video-budget agent | CLAIMED | docs/decisions/CSA-012-ENVIRONMENTS-BUDGET.md | codex/docs/csa-012-phase0-review / C:/Users/ramis/.codex/worktrees/csa-012-phase0/acendra |
| CSA-013 | CODEX coordinator | IN_PROGRESS | PLAN.md, AGENTS.md, this board, docs/reviews/CSA-013-GOVERNANCE-REVIEW.md | codex/docs/csa-013-phase0-review / C:/Users/ramis/.codex/worktrees/csa-013-phase0/acendra |
| CSA-014 | CODEX design agent | IN_PROGRESS | DESIGN_SYSTEM.md, docs/reviews/CSA-014-DESIGN-REVIEW.md | codex/docs/csa-014-phase0-review / C:/Users/ramis/.codex/worktrees/csa-014-phase0/acendra |
| CSA-015 | CODEX security agent | IN_PROGRESS | docs/decisions/CSA-015-PRIVACY-SECURITY-BASELINE.md | codex/docs/csa-015-phase0-review / C:/Users/ramis/.codex/worktrees/csa-015-phase0/acendra |
| CSA-017 | CODEX acceptance agent | CLAIMED | docs/testing/CSA-017-MVP-ACCEPTANCE.md | codex/docs/csa-017-phase0-review / C:/Users/ramis/.codex/worktrees/csa-017-phase0/acendra |

PLAN.md and AGENTS.md are temporarily locked to the coordinator; DESIGN_SYSTEM.md is temporarily locked to the design agent. Release upon submitted review artifacts. TASKS.md, SECURITY.md, code, migrations, dependencies and CI are read-only for this batch.

Each agent must inspect relevant requirements, record assumptions and requirement references, produce a reviewable artifact, run `git diff --check`, self-review and commit only its files. Acceptance is documentation completeness and consistency, not implementation verification. Each task remains IN_REVIEW until required owner decisions and review are recorded. Do not configure paid services, deploy, merge or claim approval.

Dependencies: drafts may proceed independently from the committed proposed baseline; final acceptance must reconcile CSA-011 with CSA-012 and CSA-015 with CSA-017. Existing unmerged policy worktrees must be identified as unapproved evidence, never silently imported.

Deviation: higher-priority desktop branch prefix `codex/` is used. The six requested preparations exceed the suggested initial one-task concurrency limit by explicit owner request, with independent scopes and worktrees. Four agents execute the six tasks; video/budget and security/acceptance may sequence their paired tasks when the four-agent capacity requires it.

PRs and completion evidence will be added after preparation. No task is DONE and no policy is approved by this board.
