# CSA-101–105 coordinated integration

Date: 2026-10-11 (Asia/Colombo). Owner: CODEX root. Issue #76.
Status: IN_REVIEW. Integrated draft PR #79. User explicitly requested all five tasks in parallel.
Base: origin/dev. Branch: codex/feat/csa-101-105-integration.
Root worktree: C:/Users/ramis/.codex/worktrees/csa-101-105-integration/acendra.

| Tasks | Accountable implementation owner | Exclusive scope |
| --- | --- | --- |
| CSA-101 | CODEX checkout_initialization | initialize-checkout function/tests, CSA101 docs |
| CSA-102/103 | CODEX verified_webhook | payment-provider-webhook function/tests, CSA102/103 docs |
| CSA-104/105 | CODEX financial_finalization | All new database migrations and SQL tests/RPCs, CSA104/105 docs |
| Integration | CODEX root | This record, shared integration contract, package test discovery, new integration/race tests and TASKS.md these five IDs |

Existing migrations and CSA098/100 implementation remain unchanged. Prior PR75
owns older task reconciliation; root changes only CSA101–105 entries here.
Single migration/state-machine owner serializes shared financial changes.
Each worker registers a GitHub issue and isolated managed worktree before edits.
Approval authority: project owner/designated maintainer. No merge or deployment
is implied by implementation. Final acceptance requires actual CI/review evidence.

Dependencies: merged CSA092–100 foundations, approved CSA004/006/008 and
DATABASE_DESIGN section38. CSA100 real provider acceptance remains BLOCKED;
user confirmed approved sandbox integration/domain unavailable. New deployed
online entry points remain hard disabled with no environment enable switch.
Underlying workflow tests explicitly inject enablement using synthetic evidence.
No live provider calls, configuration, paid purchases or production execution.

Contract agreement: root approved implementation interface coordination between
workers on 2026-10-11 before dependent implementation. See the integration contract.
Required verification: RED/GREEN critical tests, unauthorized/session/ownership
checks, forged/malformed/exact-money callback denial, independently retrieved
settlement binding, event replay/concurrency/reconciliation and rollback of all
payment/grant/audit/outbox effects. Full migration replay/lint/API and current-head
CI remain required. Report any skipped or unavailable verification explicitly.

## Integrated verification in progress

Checkout initialization: 27 synthetic boundary tests passed; webhook: 35 handler
and 14 existing adapter tests passed. Full Node tooling suite: 182 passed, zero
failed, two deliberate real-database suites skipped in the ordinary tooling run.
Those suites are run enabled separately and by db:test in CI.
Native PostgreSQL16 synthetic Auth bootstrap replayed migrations001–016; worker
SQL tests passed30 assertions before finite-time hardening. Root first race fixture
used an invalid evidence_reference; corrected it to the agreed authenticated
retrieval reference. Three actual independent-session scenarios then passed:
competing initialization keys reuse one attempt, duplicate verified delivery
creates one settlement/grant/event/outbox/audit, and distinct actual settlements
preserve extra money for reconciliation with one grant. Final hardened migration,
a fourth cross-order settlement reuse race and CI remain pending.
No native bootstrap result is claimed as full Supabase Auth/PostgREST verification.
## Final local integrated evidence

Final migration001–016 replay passed on a fresh native PostgreSQL16 database.
Financial SQL suites CSA092/096/098/101_105 passed; new workflow suite32 assertions
passed. Root reran final hardened RPCs with four real independent-session race
scenarios: all passed (five tests including parent). Cross-order settlement reuse
loser raises22023 and leaves its order unpaid; duplicate delivery yields one
settlement/event/grant/audit/outbox; extra real payments preserve two settlements
with one grant. These results supersede the earlier in-progress race note.
Full native pgTAP suites were unavailable because extension is not installed;
full Supabase migration/lint/API/Auth and current-head CI are still required.
No production/provider calls occurred. Draft PR #79 contains ordered disjoint
worker commits. Tasks remain IN_REVIEW with external provider acceptance blocked.
## Integration security review

A separate worker performed read-only review of the combined handlers/migration.
No blocking financial defect found: service-only RPC grants, unique stored lookup,
exact stored amounts, global scoped settlement serialization, duplicate conflicts,
late/extra reconciliation, conservative revoked projection and transactional
settlement/grant/audit/outbox rollback are consistent. This AI cross-review does
not replace authorized financial approval. A trusted-config snapshot timing issue
in checkout initialization was fixed with a regression; Auth/database requests
also explicitly reject redirects. Final current-head CI is required after that fix.
Root config sets provider webhook verify_jwt=false for callback transport only;
its deployed entry point remains hard disabled before all parsing or external I/O.
Final checkout handler now passes29 boundary tests including config mutation and redirect controls. Final tooling suite184 pass, two database suites gated and separately verified. Required current-head CI links/results are recorded on PR #79/issue #76 when available.

## Strict lint repair

CI at5097028 passed full Supabase db:test (ordered replay, all SQL suites and
both enabled concurrency suites) but strict warning-level lint failed. Review
identified a settlement row variable assigned only to inspect FOUND; migration016
now uses PERFORM1 with the same condition/FOUND behavior. All32 actual native SQL
assertions passed after this repair; task-owned cluster stopped cleanly.
Lint strictness is unchanged. Wrapper now emits only known repository function
names, severity, bounded SQLSTATE and fixed diagnostic categories; raw messages,
queries, customer values and credentials remain private. A focused redaction test
passes. Final current-head CI must confirm the warning repair and full integration.