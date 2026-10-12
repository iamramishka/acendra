# CSA-155 learning progress persistence tests

Owner: CODEX progress test worker. Coordination: root issue #101 and active
implementation issues #93/#97. Branch: codex/test/csa-155-progress-tests.
Worktree: C:/Users/ramis/.codex/worktrees/csa-155-progress-tests/acendra.
Status: IN_REVIEW; prerequisite integration remains pending.

Scope is only tool/csa155_progress.test.mjs, tool/csa155_progress.sql, and this
handoff. No production source, shared manifest, migration, or active worker file
was changed. Parent integrates the result; this worker opens no separate PR.

## Contract and dependency

The tests independently exercise committed CSA-133 public RPCs:
`csa133_save_progress(uuid,boolean,integer,numeric,integer)` and
`csa133_read_progress(uuid)`, inspected read-only at commit 6d3aadb. Ownership,
current session, entitlement, typed resume, nullable snapshot, and completion
semantics follow docs/contracts/CSA-133-PROGRESS.md and SRS BR-013/014.
CSA-127/133 migrations are not present on the test branch's origin/dev baseline
9cd6c39. The new SQL is outside auto-discovered supabase/tests/database, so it
cannot fail unrelated dev CI solely because those RPCs remain unmerged.

The Node test is auto-discovered through the existing tool/*.test.mjs glob.
It explicitly skips with a dependency reason by default. Opt-in requires
ACENDRA_CSA155_DB_TEST=1 and a validated local disposable PostgreSQL port in
ACENDRA_CSA155_PG_PORT (or ACENDRA_FINANCIAL_PG_PORT). The executable can be
selected by ACENDRA_CSA155_PSQL (or ACENDRA_FINANCIAL_PSQL). An opted-in target
missing either RPC is also an explicit dependency skip, never a persistence pass.
Connection failure, SQL failure, or missing assertion results fail the test.

## Requirement-to-evidence mapping

| Requirement or risk | Evidence |
| --- | --- |
| Text/image completion persistence | Actual authenticated save/read equality with typed nullable fields |
| PDF page and offset persistence | Exact page 7 and numeric offset 0.625 in saved record and later reads |
| Video resume persistence | Duration-boundary 90-second roundtrip (contract-supported SHOULD behavior) |
| Retry and completion changes | Single stored row; unchanged payload; nondecreasing timestamps; later clear snapshot |
| Invalid resume inputs | Zero page; negative/overflow/missing-page/NaN offset; negative/over-duration seconds; cross-type fields; unchanged persisted row |
| Student-owned progress | Equally entitled peer sees empty progress, writes only own row; owner later reload retains original rows |
| Current matching session | Foreign session and expired owner session deny both save and read |
| Revoked access | Both read and save denied, previously saved history retained unchanged |
| No entitlement side effects | Exactly two fixture grants remain; no direct authenticated table read/write grants |

## Fresh verification, 2026-10-12

- `node --test tool/csa155_progress.test.mjs` on origin/dev baseline: exit 0,
  0 passed, 1 explicitly dependency-skipped; this is not persistence evidence.
- Same command with opt-in against parent-owned PostgreSQL 16 localhost:55518,
  final committed Phase 6 snapshot cecda45, migrations 001-024: exit 0, 1 passed,
  0 skipped, all 14 named SQL assertion groups passed. Run repeated after adding
  expired-session checks; final run passed. Database uses synthetic Supabase
  Auth/Storage schema shims and synthetic identities, not a hosted deployment.
- All fixture inserts, progress saves, role switches, grants, and revocation run
  inside one transaction rolled back at the end. The test creates no persistent
  schema or student data and leaves the parent's database intact.

This verifies real PostgreSQL stored rows and RPC readback, not browser reload,
network interruption, mobile offline sync, or hosted Supabase Auth transport.
Real Supabase CI execution and integration of CSA-127/133 remain review gates.
No merge, deployment, provider call, or production configuration was performed.
