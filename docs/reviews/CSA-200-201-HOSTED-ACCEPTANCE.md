# CSA-200/201 hosted acceptance handoff

Date: 2026-10-14 (Asia/Colombo). Owner: CODEX/recovery_acceptance.
Status: IN_REVIEW; new hosted results pending. Coordination: CSA-200-201-HOSTED-BOARD.md.

No tests were run on the user's local machine in this continuation. Existing
historical results remain historical; this document adds no passing claim.
The new tool/csa201_hosted_recovery_boundaries.test.mjs covers a delayed provider
acceptance arriving after timeout and a successful reclaimed lease: late completion
must never generate a third acknowledgement or overwrite the recorded successful
retry. A second regression checks distinct payment events for the same recipient
use distinct provider idempotency keys. Tests use the real notification worker
with explicit synthetic transport/store collaborators; no external email is sent.

Hosted command: npm run tool:test (discovers tool/*.test.mjs automatically).
Focused hosted command: node --test tool/csa201_hosted_recovery_boundaries.test.mjs.
Existing hosted db:test covers csa201_financial_failure_recovery.test.sql and
runStorageRecoverySmoke from tool/csa200_storage_recovery.mjs. No runner,
production handler, migration, dependency or workflow is changed in this scope.

CSA-200 remains IN_REVIEW with release acceptance BLOCKED. The disposable
PostgreSQL and Storage archive/loss/restore exercises verify synthetic fixtures,
checksum/metadata consistency, deletion tombstones and denied restored access.
They cannot establish managed backup encryption/key recovery, 30-day enforced
retention, a named recovery alternate, separately protected backups, representative
volume, Auth/configuration restoration, or measured RPO <=24h and RTO <=4h.
Those selected targets are in docs/decisions/CSA-200-RECOVERY-OPERATIONS-BASELINE.md.

CSA-201 remains IN_REVIEW. SQL transaction failure/retry and notification recovery
coverage is implemented. Actual approved provider reconciliation after persistence
failure, operational bank evidence and browser refresh recovery still need hosted
operational acceptance evidence. Synthetic provider responses are not settlement
verification. Hosted CI success accepts executed test scope, not these external
operational checks. Root owns consolidated evidence, PR and final status updates.
