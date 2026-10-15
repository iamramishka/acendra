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

## Existing-service, zero-spend backup decision (2026-10-15)

User instruction: use existing services only; hold prerequisites that would require
new services or spending. The current known Supabase project
`worrsweluwjmppwsygre` is staging. No backup capture, download, retention change,
scheduler, destination or restore was activated in this work.

[Supabase's current backup documentation](https://supabase.com/docs/guides/platform/backups)
recommends CLI exports with offsite retention for free projects. Managed daily backup
access and PITR must not be assumed available on a free account. Database backups
exclude Storage object bytes. These provider capabilities do not establish this
project's accepted 30-day separately protected complete backup set.

Use this decision sequence in the existing account:

1. Open [Database Backups](https://supabase.com/dashboard/project/worrsweluwjmppwsygre/database/backups)
   and inspect capability and available sets without selecting restore or upgrade.
   Record plan/capability, safe set timestamps and completeness; do not copy private
   database content. A provider backup listing is not successful recovery evidence.
2. If only manual export is available, hold activation until the owner identifies
   an **existing** encrypted destination, approved custodian and independent key
   recovery. An application bucket in the same project is not independent backup.
   Git, public CI logs/artifacts and this repository must not store database dumps,
   Auth exports, private receipts, object bytes, keys or detailed private manifests.
3. Prepare a reviewed capture procedure using the provider's
   [CLI backup/restore guide](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore).
   It must cover schema/roles/data, Auth/configuration, actual object bytes and
   tombstones with mutually consistent cutoffs. Scope and destination are unresolved,
   so no credential-bearing export command is executed or supplied as a default.
4. Independently approve cadence, capacity and retention within existing resources.
   Manual ad-hoc capture does not guarantee RPO24h. Do not add scheduled Actions,
   account integrations, backup destinations or paid PITR under this authorization.
5. Hold restore until an existing isolated destination and data-handling authority
   are confirmed. Never use the current staging project as a disposable restore
   target: it contains accounts and ongoing acceptance work.

| Gate | Current disposition | Resume condition |
|---|---|---|
| Managed daily/PITR capability | Not established; paid enablement skipped | Existing eligible capability confirmed without upgrade |
| Offsite complete capture and 30-day retention | HOLD | Existing encrypted independent destination and key recovery approved |
| Automated freshness/failure alerts | HOLD | Existing scheduler and delivered alert route approved, with capacity checked |
| Full isolated restore | HOLD | Existing isolated target and representative protected set available |
| Measured RPO/RTO and production acceptance | HOLD | Complete reviewed restore/reconciliation and production designation |

**Hold:** CSA-214 remains IN_REVIEW for specification; operational backup configuration
is BLOCKED on the conditions above. Free-only scope does not waive recovery targets.
Source checked 2026-10-15; no upgrade, new service or backup data transfer performed.

Root read-only inventory reported 2026-10-15 for the existing staging project:
backup-list API returned zero available sets, `pitr_enabled: false`,
`walg_enabled: true` and empty physical backup metadata. This does not establish
an accessible managed backup or a complete restorable set; internal WAL capability
is not evidence of paid entitlement or tested recovery. No backup was downloaded
or restored. Keep the backup activation and measured restore gates on HOLD.
