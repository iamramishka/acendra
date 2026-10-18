# PR-181 payment-list review fixes

Owner: CODEX, assigned by the project owner's 2026-10-18 request to fix findings and merge into dev.
Coordination: GitHub #184; existing integration PR #181. Status: IN_REVIEW.
Branch: `fix/csa-paylist-pr181-findings`.
Workspace: `C:/Users/ramis/.codex/worktrees/review-pr181-20261018/acendra`.

Scope: payment-list handler/tests, unapplied migration/database fixture, payment-list contract reconciliation and this record.
Temporary ownership covers that migration and contract; no unrelated shared-file changes.
Dependencies: reviewed contract corrections merged in #179; current `dev`.
Approval authority: project owner; independent review and normal protected-branch requirements remain applicable.

Acceptance: latest rejected bank submission reports rejected until a newer preparation; submitted receipt reports processing;
terminal order states retain precedence. Live counts carry `count_as_of` separately from fixed cursor `as_of`.
The disabled read-only default and authorization/privacy boundaries remain intact.

Verification: focused Node and SQL regressions, full tooling suite, disposable Supabase migration replay/database tests/lint,
CI, independent review and protected-branch merge.

## Changes and verification

- Merged current dev into the PR ancestry and reconciled both contract versions explicitly, preserving #179 corrections.
- Latest rejected bank submission now affects pending-payment classification; later preparation and terminal order states take precedence.
- SQL returns the current `count_as_of`; the handler validates and forwards it separately from the fixed `as_of` cutoff.
- Added handler regression tests: old handler failed 10/53 after the new response contract was introduced; corrected handler passes 53/53.
- SQL fixture exercises trusted rejection, retry preparation/finalization and approval, then checks list/detail/counts and snapshot semantics.
- Corrected original SQL fixture bank settlement setup to bind a synthetic destination and matching immutable bank snapshot.
- Independent read-only Codex review found no remaining concrete issue after fixture corrections; this is not human approval.
- Full `npm run tool:test`: 854 tests, 843 passed, 10 skipped, 1 failed. The unchanged dev browser CSP test timed out waiting for Chrome.
- Local `npm run db:test`: blocked before replay because no local Docker Linux engine is available. Docker Desktop cannot start: missing installation registry entry.
- Diff whitespace check passes. No Flutter code changed; fresh PR CI must verify integration, database replay/tests and lint.

## Handoff

Remaining: fresh CI, any required independent approving review, normal protected-branch merges of #181 and #182.
Runtime activation and production database execution are separate release decisions. Shared-file claim remains limited to this PR's migration/contract until integration or explicit handoff.
