# CSA-009 / CSA-016 Completion Reconciliation

Date: 2026-10-11 (Asia/Colombo)
Owner: CODEX; authorized by owner's request to resolve task/ADR gaps.
Branch: docs/csa-009-016-reconciliation
Workspace: C:/Users/ramis/.codex/worktrees/csa-009-016-reconcile/acendra
Base: origin/dev at 7a6acc3
Scope: TASKS.md, docs/decisions/** and this record. Temporary shared editing
ownership belongs to CODEX and releases at handoff. Runtime, migrations,
threat-register changes and other worktrees are outside scope.

## CSA-009

[PR #1](https://github.com/iamramishka/acendra/pull/1) merged the initial threat
model into SECURITY.md at be0aede4bebc03160ea511b04184c923c6944a69.
The task covers creating the model, not mitigating every identified threat.
The owner requested reconciliation of this completed deliverable. Status: DONE.
CSA-015 security/privacy approval and implementation risk controls remain open;
this edit declares no security threat mitigated.

## CSA-016

[PR #2](https://github.com/iamramishka/acendra/pull/2) merged twelve ADR drafts.
[PR #3](https://github.com/iamramishka/acendra/pull/3) accepted MVP/roles/PayHere/
LKR/bank policies. [PR #4](https://github.com/iamramishka/acendra/pull/4) accepted
architecture/database/lifetime/refund/PDF baselines and twelve-topic numbering.

Eleven records now reflect those approvals, record approver/date, and move into
docs/decisions/. Payment/PDF decisions are updated to the selected strategies.
ADR-010 remains pending under CSA-011; no provider selection is invented.
CSA-016 is DONE for drafting and reconciling initial records. It does not subsume
video selection, governance review, implementation testing or deployment.

## Verification and Remaining Work

Verify twelve unique ADR identifiers, eleven Accepted records and one pending;
check moved-record/index links and diff scope/whitespace. Application tests are
not applicable to Markdown-only reconciliation; no runtime/security pass claimed.
CSA-011, CSA-013, CSA-015 and provider/retention/CI/migration/PDF runtime/release
gates remain open. Old draft paths remain discoverable through Git history and
the updated indexes. No other worktree or uncommitted draft was changed.
