# CSA-226–230 and CSA-235 parallel preparation

Date: 2026-10-16 (Asia/Colombo)
Status: IN_REVIEW — documentation preparation complete; implementation remains BACKLOG.

## Authorization and ownership

The project owner requested all six tasks in parallel and then selected “Prepare proposals for my review.” CODEX owns this bounded preparation. Approval authority: project owner; financial and authorization implementation still requires the repository review gates.

Branch: `codex/docs/csa-226-235-parallel-preparation`.
Worktree: `C:/Users/ramis/.codex/worktrees/csa-226-235-preparation/acendra`.
Writable scope: this board and `docs/requirements/CSA-226-235-PROPOSALS.md` only. All application code, migrations, shared contracts, TASKS.md and existing worktrees are excluded.

Parallel read-only assignments:

| Tasks | Accountable preparation owner | Analysis worker | Scope |
| --- | --- | --- | --- |
| CSA-226, CSA-235 | CODEX | analytics_instructors | Analytics privacy and instructor authorization |
| CSA-227, CSA-228 | CODEX | coupons_bundles | Checkout pricing and bundle entitlements |
| CSA-229, CSA-230 | CODEX | subscriptions_referrals | Recurring billing and referral accounting |

Workers inspect only; they cannot edit files or claim implementation ownership. CODEX integrates proposals sequentially in this isolated worktree.

## Checks before editing

- Read repository AGENTS.md and relevant TASKS.md, PLAN.md, SRS.md and parallel workflow sections.
- TASKS.md section 25 lists all six as post-MVP titles requiring approved requirements and architectural review.
- Existing approved checkout baseline is one course per order; bundles are deferred.
- Inspected Git status, worktree inventory and task records. No matching active task worktree was listed. Existing deployment/operations modifications in the original checkout are excluded.
- Attached worktree inventory was empty before creating this worktree.
- `gh issue list` and `gh pr list` both failed: GraphQL could not resolve `iamramishka/acendra`. Remote ownership/locks cannot be verified. This is a local preparation record, not a GitHub claim.

## Dependencies and verification criteria

Before implementation: owner accepts feature rules and scope; requirements and contracts are reviewed; GitHub access and overlapping ownership are checked; each task receives isolated implementation ownership. Serialize changes to shared checkout/payment state, migrations, roles and routing.

Preparation acceptance: each task has proposed behavior, explicit unresolved owner decisions, security boundaries, integration points and meaningful future acceptance tests; no unapproved policy is described as accepted. Verify document consistency and `git diff --check`. No runtime test result or delivered feature is implied by documentation review.

Related issue/PR: unavailable; reconcile after repository access is restored. No production operation, paid purchase, release or merge is authorized by this preparation.

## Handoff

All three read-only workers returned findings, integrated into `docs/requirements/CSA-226-235-PROPOSALS.md`. Each of the six tasks has proposed scope, owner decisions, integration dependencies and future acceptance tests. No application or shared contract files changed. Original checkout modifications were preserved.

Verification: local link targets checked; document scope and proposal status reviewed; staged diff whitespace check recorded with the preparation commit. Runtime checks are not applicable to these documentation-only changes and were not run. GitHub access failure prevents remote ownership reconciliation and PR creation; no PR or independent approval is claimed.

Next owner: project owner reviews the proposal and resolves task-specific decisions; CODEX can then reconcile GitHub ownership and prepare implementation contracts. Preparation remains IN_REVIEW until accepted; the six feature tasks are not completed.

## Owner-authorized dev integration — 2026-10-16

The project owner requested “review and merge with dev.” CODEX reviewed both documents and checked the stated dashboard fixtures, course repository stubs, one-course order/grant constraint and lifetime paid grant constraint against local source. Local Markdown links resolve and whitespace checks pass. No blocking documentation findings were identified. This is implementation-owner self-review, not independent review.

The owner authorizes local integration of these preparation documents into `dev`. This instruction supersedes the earlier preparation-only merge restriction for these two files. It does not select unresolved business rules, approve feature implementation contracts or complete any of the six backlog features. Proposal status remains IN_REVIEW for those decisions. Remote PR/CI verification is not claimed; existing unrelated local modifications must remain intact.
