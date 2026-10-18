# PR #180 cleanup runbook review correction

Status: IN_REVIEW. Owner: CODEX. Date: 2026-10-18 (Asia/Colombo).

The project owner explicitly authorized fixing the parallel review findings in
this chat. This is a bounded local correction assignment against existing
PR #180, not a GitHub Issue claim. The original package maker remains CLAUDE;
CODEX owns only the correction below. No matching open Issue exists (the open
Issue list contains #160, unrelated operational holds).

- Reviewed PR head: `d6ec6d8535adbdb76c4fa04ee40fbdf44e6cdb79`.
- Reviewed base: `origin/dev` at `875c8bd1da53e879a59408d3da597262b32a64bf`.
- Correction branch: `docs/csa-cleanup-pr180-review-fix`.
- Isolated worktree: `C:/Users/ramis/Downloads/Acendra/review-pr180-20261018`.
- Allowed scope: this board, `docs/runbooks/CSA-SANDBOX-SEED-CLEANUP.md`, and
  misleading account-deletion comments in
  `docs/runbooks/sql/CSA-SANDBOX-SEED-CLEANUP.sql` only.
- Dependencies: existing profile creation trigger (CSA-060), Auth/profile
  `ON DELETE RESTRICT` relationship (CSA-059), reviewed archival SQL, and
  PR #180 owner coordination. Open Issues, PRs, task records and worktrees
  were checked; PR #180 is the existing package, and the owner-authorized
  correction is confined to its runbook. PRs #177/#179 corrections have
  disjoint file scopes. No shared application or migration files are claimed.
- Correction: defer all account/profile deletion to a separately approved
  future procedure; explain why zero counted dependents do not establish
  that Auth deletion is supported; retain existing archive/retention gates.
- Verification: inspect the complete runbook and SQL comments for contradictory
  deletion instructions, confirm executable SQL is unchanged, review the diff,
  and run `git diff --check`. No additional runtime tests are required for this
  documentation correction.
- Approval authority: project owner/designated maintainer for final integration;
  hosted execution still requires the runbook's separate written owner approval,
  independent human review, backup and authorized maintainer. The current chat
  authorizes this correction, not hosted execution or account deletion.
- Handoff: commit locally for independent root-agent review. This correction
  agent will not push, post to GitHub, merge, or operate a hosted database.

## Prior review evidence

Before this correction, CODEX replayed the actual migrations in an isolated
native PostgreSQL 17 cluster with minimal Auth/Storage schema shims, then
persisted the constrained CSA-096 synthetic financial fixtures. Dry run,
rollback rehearsal, committed archival and idempotent reapplication passed.
A fresh Auth account with no profile dependents still failed Auth-row deletion
with SQLSTATE `23503` (`profiles_id_fkey`), demonstrating the documented error.
The native cluster was stopped. This is local review evidence, not hosted
Supabase Auth API execution or approval to operate on accounts. The catalog
and direct-detail test files also passed three tests during that earlier review.

## Correction and verification

All account/profile deletion is now explicitly deferred in the scope table,
approval roles, execution step 7, closure instructions, recovery guidance and
limitations. The runbook explains automatic profile creation and the expected
restricting foreign key. The SQL's introductory comment matches that scope;
all executable SQL is unchanged. Prior local rehearsal claims are distinguished
from the original maker's unexecuted evidence and from hosted runtime checks.

Before final correction verification, the task branch merged reviewed
`origin/dev` (`875c8bd1da53e879a59408d3da597262b32a64bf`) normally, without
conflicts. Incoming admin-reporting changes are retained without editing them.
The correction remains limited to the three allowed documentation paths.

Verification: full runbook/script comment review, executable-SQL comparison,
`git diff --check`, and correction diff self-review passed. No runtime tests
were rerun for the documentation-only correction. Independent review and
authorized integration remain pending; hosted execution gates remain unchanged.
