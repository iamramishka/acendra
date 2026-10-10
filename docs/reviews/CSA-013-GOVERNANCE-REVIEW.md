# CSA-013: PLAN.md and AGENTS.md review

Date: 2026-10-11 (Asia/Colombo)
Status: IN_REVIEW; proposed refinements, not owner approval.
Owner: CODEX coordinator. Initial inspected local source: 9355311 (`dev`). PR base: origin/dev e1cf11f.
Branch: `codex/docs/csa-013-phase0-review`.
Workspace: `C:/Users/ramis/.codex/worktrees/csa-013-phase0/acendra`.

## Scope and acceptance

Review planning and agent governance against the actual repository, SRS,
TASKS and parallel workflow. Correct document locations and clarify how
bounded planning can proceed before Issues exist, while preserving security,
task ownership, isolation, review and production approval. No implementation,
business rule approval or TASKS milestone completion is included.

Requirement references: SRS NFR-MAIN-004, NFR-MAIN-005, NFR-MAIN-006;
SRS section 21 release acceptance; PLAN sections 9, 16, 45 and 46;
AGENTS sections 8, 12, 19, 40, 52 and 54.

## Findings and refinements

| Finding | Evidence | Resolution |
| --- | --- | --- |
| Testing document references point to a missing root file | Actual file is docs/TESTING.md | Correct PLAN and AGENTS references; review/approval remains pending |
| API contract tree differs from committed location | Actual file is docs/API_CONTRACTS.MD, not docs/api-contracts/ | Correct PLAN inventory; do not move shared contract file |
| Planning still calls for creation of existing workflow | docs/PARALLEL_WORKFLOW.md exists | Change applicable PLAN actions to review and approve |
| Issue claiming is mandatory although no issues exist | Open Issue and PR queries returned empty on inspection | Add bounded, owner-requested documentation fallback with local board and explicit reconciliation; no fabricated GitHub claim |
| Suggested one-task initial concurrency does not describe requested six-task batch | Owner explicitly requested these preparations in parallel | Record isolated scopes and exception; production concurrency still needs its dry-run |
| Generic phase gate can obscure outstanding decisions | SRS DEC-009 video, DEC-011 budget, DEC-014 retention remain open on origin/dev | Add explicit proposal/approval distinction and acceptance evidence to Phase 0 |
| Proposed documents use wording such as approved technology baseline | Header still says Proposed - Pending Approval | Treat stack as requested engineering constraint; do not infer formal approval from section titles |
| Dev has UI commits and uncommitted work while early phase gates remain unchecked | Base 9355311 and primary status inspection | No invented phase completion or regression result; owner must reconcile milestones using evidence |

## Safe parallel allocation

See [coordination board](CSA-011-017-PARALLEL-BOARD.md). The root owns only
PLAN/AGENTS governance, and the design agent owns DESIGN_SYSTEM. Provider,
budget, security and acceptance agents write unique new documents. Shared
code, TASKS, SECURITY, dependencies, migrations and CI are read-only.

Fetching origin/dev confirmed that PRs #1 through #5 already merged the
requirements, roles, PayHere/LKR, bank, lifetime/refund, PDF, threat model and
ADR baselines. Task commits are rebased onto e1cf11f to preserve these policies
and exclude unrelated local UI commits. Earlier approved policies are not
reopened; remaining operational gates and new proposals still need acceptance.

## Approval and integration checklist

- [x] Actual branch/worktree isolation and mutable primary checkout inspected.
- [x] Open GitHub Issue/PR overlap queried; no matching open records found.
- [x] Shared documentation scope and local ownership recorded before editing.
- [x] Security/payment/privacy/production rules remain intact.
- [ ] Owner accepts the governance changes at a specific commit.
- [ ] Reconcile TASKS milestones and GitHub ownership through designated owner.
- [ ] Approve PLAN/AGENTS revisions separately from drafting this review.
- [ ] Verify configured CI and required review before integration.

## Verification and handoff

Documentation verification: review the small PLAN/AGENTS diff and run
`git diff --check`. No runtime code changed; Flutter/database suites are
not evidence for this documentation review and are not run for this task.
No backend implementation, operational security, purchase, deployment,
merge or policy acceptance is claimed.

Next owner: project lead. Review proposed changes, reconcile prior policy
work and accept or request changes through the task PR. Other task artifacts
remain independently reviewable; financial implementation stays gated by
its approved business contracts.
