# CSA-101–105 coordinated integration

Date: 2026-10-11 (Asia/Colombo). Owner: CODEX root. Issue #76.
Status: IN_PROGRESS. User explicitly requested all five tasks in parallel.
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
