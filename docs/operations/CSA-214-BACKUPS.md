# CSA-214 — Backup configuration specification

Status: IN_REVIEW, preparation only. Date: 2026-10-15 (Asia/Colombo).
Owner: CODEX. Assignment: [preparation board](../tasks/CSA-211-216-PREPARATION.md).
No production backup, account, destination or provider plan is verified.

## Accepted baseline and proposed implementation

The [accepted recovery baseline](../decisions/CSA-200-RECOVERY-OPERATIONS-BASELINE.md)
sets RPO at most 24 hours, RTO at most four hours, rolling 30-day separately
protected backups and project owner as lead. Designate an alternate before release.
These targets require measured evidence; a small disposable restore is insufficient.

Propose a complete recoverable set every 12 hours, freshness checks every hour,
immediate failure alert and escalation when the newest validated set exceeds
18 hours. Approve cadence after measuring capture duration and recovery capacity.
Scheduling every 24 hours leaves no failure margin; even 12-hour scheduling does
not guarantee RPO if retries, capture time or missing objects delay a valid set.
Measure the oldest recoverable component, including deletion/event records, and
declare breach at >24 hours. A database-only snapshot cannot establish a complete set.

| Component | Required backup and restore evidence |
|---|---|
| Database | Schema/migration revision, roles/grants/RLS, profiles, courses, orders/payments, grants/enrollments, progress, immutable audit and notification outbox; record snapshot consistency and restore integrity. |
| Auth/configuration | Approved export/recovery mechanism, identity/session behavior, function/release configuration and dependency inventory. Secret references belong in a vault; verify authorized credential recovery separately. |
| Private objects | Actual PDF/media/receipt/source bytes, bucket privacy, object identity/version/MIME/size/hash and database reference manifest. Metadata alone is insufficient. |
| Deletions | Independently retained authorized deletion/tombstone ledger through restore cutoff; replay before availability, including receipts and derivatives. |
| Financial events | Recoverable provider/bank evidence for reconciliation over backup-to-cutover gap; avoid using client redirects or receipts as settlement proof. |

## Activation checklist

- [ ] Verify actual production project, backup capability/plan and approved budget; preserve dummy targets until real deployment is authorized.
- [ ] Choose approved encrypted destination separate from primary failure domain; deny public access and use least privilege backup credentials independent of application credentials.
- [ ] Record encryption mechanism, key custodian/alternate, secure key recovery and tested ability to decrypt after primary-account loss. Do not commit keys.
- [ ] Configure supported consistent capture and object manifests; reject incomplete sets and validate checksums before declaring success.
- [ ] Protect backups against accidental overwrite/deletion with approved access controls; review integrity, read access and retention changes through audit.
- [ ] Enforce rolling 30-day retention and privacy deletion/hold policy across replicated copies. The diagnostic baseline does not authorize deletion of financial audit history or invent legal retention.
- [ ] Configure failure, freshness and missing-job alerts from [monitoring plan](CSA-213-MONITORING.md); prove delivery to named responders.
- [ ] Run isolated full restore and financial reconciliation using [runbook](CSA-216-RECOVERY-RUNBOOK.md), including corrupt archive and unauthorized access checks.
- [ ] Measure complete RPO/RTO at realistic volume; review transfer/decryption/restore capacity and cost. Approve exercise cadence (proposed monthly and after material recovery changes).
- [ ] Capture production configuration evidence and independent review. Mark DONE only after actual configuration and restore acceptance.

## Evidence manifest

Record set ID; environment/project; source release/schema revision; start/end UTC;
consistent data cutoff; each component cutoff; object inventory/hash algorithm;
deletion-ledger cutoff; restricted archive location; encryption/key reference;
retention expiry and holds; validation result; last successful heartbeat; job/alert
IDs; owner/reviewer. Store detailed private inventory outside the repository.

Restore evidence: selected set; declaration time; newest trustworthy recoverable
transaction/object/deletion cutoff; service verification/reopen times; measured
loss interval and full elapsed time; record/object checks; reconciliation conflicts;
denial tests; cleanup; authorization. Do not substitute backup creation time for
recoverable data cutoff or SQL import duration for full service recovery time.

No backup scheduler, paid plan, provider or production restore is activated here.
