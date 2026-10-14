# CSA-216 — Operator recovery runbook

Status: IN_REVIEW; operational acceptance pending. Date: 2026-10-15 (Asia/Colombo).
Owner: CODEX; incident/recovery authority: project owner or designated maintainer.
Assignment: [preparation board](../tasks/CSA-211-216-PREPARATION.md).
Production project, provider controls, named alternate and live evidence remain unverified.

## Preconditions and incident declaration

Apply [accepted RPO24h/RTO4h baseline](../decisions/CSA-200-RECOVERY-OPERATIONS-BASELINE.md),
[backup specification](CSA-214-BACKUPS.md) and [monitoring plan](CSA-213-MONITORING.md).
Before operational use, name lead/alternate, finance reconciler, security reviewer
and release approver; verify their restricted access and approved contact channels.
Record actual source/destination project IDs, region, provider procedures, release
revision, vault references, backup catalog, key custody and dependency inventory.
Dummy deployment targets are not real recovery destinations.

1. Lead declares incident, severity, scope and UTC start; start the full RTO clock.
2. Preserve minimal restricted audit/provider evidence. Identify last trustworthy
   transactions and objects, suspected compromise and affected credentials.
3. Obtain authorized containment actions: restrict affected payment/approval/content
   entry points and pause workers as necessary. Preserve pending outcomes and durable
   retry evidence. Do not disable RLS or grant entitlements to resolve an outage.
4. Freeze conflicting releases and record one incident implementation owner.
   For compromised keys, contain/rotate through approved provider procedure; ensure
   restored configuration cannot reintroduce exposed keys or unsafe signed access.
5. Establish an isolated recovery destination with no public traffic, no production
   email/payment side effects and no automatic worker execution. Confirm actual IDs
   independently before mutation. Production database changes require release approval.

## Select and validate a recoverable set

6. Select the newest trustworthy complete set; record component cutoffs, encryption,
   manifest and deletion ledger. Retrieve/decrypt with restricted independent access.
   Preserve originals; operate on a reviewed copy.
7. Validate the entire archive before any restore: expected set/version/identity,
   object names, sizes, MIME, hashes, completeness and independently bound tombstones.
   Reject corruption, duplicates, path traversal, unexpected/missing objects and
   missing ledger. Quarantine suspect sets; select a trustworthy earlier set and
   explicitly report any RPO breach. Never silently skip invalid objects.
8. Define consistent database/object/event cutoff and recoverable gap. Obtain
   independent provider/bank evidence covering that gap; ambiguity remains pending.

## Restore and reconcile in isolation

9. Follow reviewed provider-specific restoration procedures for database and Auth;
   record each operation/result. Restore schema, financial/audit/outbox records,
   approved grants/RLS and configuration at compatible revisions. Do not apply
   ad-hoc migrations or restore revoked credentials to make checks pass.
10. Restore object bytes with private bucket configuration and version identities;
    replay all authorized deletions through cutover before making objects available.
    Preserve deletion obligations across receipts, source objects and derivatives.
    Verify restored hashes and database/object references; account for all missing
    and orphaned entries. Never expose raw receipt or media paths in public evidence.
11. Check Auth identity/revocation/session behavior; force approved reauthentication
    where necessary. Verify anonymous/student/finance/admin boundaries, including
    direct API/RPC/Storage requests and cross-user denial, before enabling traffic.
12. Finance reconciles recovered orders, events, settlements, grants, enrollments,
    audit and outbox with authentic provider/bank credit evidence. Enumerate every
    backup-to-cutover event and unresolved discrepancy. Use approved idempotent
    handlers with original event identity; no direct financial row edits, client
    success assumptions, fabricated settlements or duplicate grants.
13. Inspect notification leases and retries. Retain stable provider idempotency keys
    when acknowledgement was lost; unknown delivery remains retryable/uncertain.
    Do not blindly resend messages or declare exactly-once delivery without provider
    evidence. Notification failure must not undo verified settlement.

## Validate, authorize reopening and follow up

14. Exercise approved synthetic journeys: valid paid entitlement, pending/forged
    denial, revoked access, protected delivery, role restrictions, progress and
    retry/replay behavior. Server errors, redirects and throttling are not successful
    authorization-denial evidence. Verify deletion privacy and audit completeness.
15. Verify current backups, alert heartbeat/delivery, deployment security controls,
    corrected credentials and provider integrations. Confirm read/write capacity and
    full recovery elapsed time. Record unmet tests and financial uncertainty explicitly.
16. Lead/security/finance reviewers approve reconciliation and integrity; authorized
    release approver approves cutover. If integrity, privacy or access remains uncertain,
    keep affected functions contained and escalate. Define a reversible cutover plan
    preserving new writes; rollback must not discard post-recovery financial events.
17. Reopen approved functionality gradually; observe errors and financial invariants,
    reconcile delayed callbacks safely and confirm no duplicate outbox effects.
    End RTO only when usable authorized service meets agreed acceptance, not at import.
18. Record incident outcomes, measured RPO/RTO, deviations and follow-up ownership.
    Remove only verified task-owned disposable resources; retain protected evidence
    and backups under applicable retention/holds. Review root cause and drill lessons.

## Offline tooling and safe rehearsal

Run these from an isolated repository checkout with Python and Node available:

```powershell
python tool/csa200_recovery_test.py
node --test tool/csa200_storage_recovery.test.mjs tool/csa201_notification_recovery.test.mjs
```

These test environment sanitization, reserved ports, synthetic object boundaries,
tombstones, archive integrity/identity/denial safeguards and notification retries.
They do not access production and do not prove deployed backup or email capability.

Optional native disposable drill requires PostgreSQL17 binaries, a free coordinated
loopback port in 61000–61009 or 61310–61319 and permission to create local temporary
clusters. The executable accepts no connection URL and removes PG environment
overrides. It creates its own temporary data and cleans its own cluster:

```powershell
python tool/csa200_recovery.py --postgres-bin 'C:/Program Files/PostgreSQL/17/bin' --port 61319
```

Reserve the port with other workers before execution. This uses synthetic Auth/Storage
shims and fixtures; never substitute a production data directory or infer cloud RTO.
Record actual JSON output and failures. This optional drill was not run in this preparation.

The real disposable Storage rehearsal is exported as `runStorageRecoverySmoke` in
[csa200_storage_recovery.mjs](../../tool/csa200_storage_recovery.mjs), invoked by the
existing guarded [Supabase smoke harness](../../tool/supabase_smoke.mjs). It needs
the repository's isolated local Linux Docker/Supabase test layout and synthetic
credentials/context. It is not a standalone production restore CLI. The local
runner `node tool/local_supabase.mjs test test` resets its disposable test database;
review its isolation/port ownership before use. Do not use these fixture harnesses
as operating backup jobs or supply hosted credentials to bypass their local guards.

## Preparation verification and evidence record

On 2026-10-15 at base dev `7916c6e`, bundled Python executed
`tool/csa200_recovery_test.py`: **5 passed**, zero failures. Node executed the two
test files above: **7 passed**, zero failures/skips (5 Storage safeguards and
2 notification retry tests). No native cluster, Docker/managed service, production
backup, live provider, operational alert or full recovery drill ran.

For each operational exercise retain: incident/drill ID; source/destination IDs;
authority/participants; revision; declaration/cutover/reopen timestamps UTC;
selected set/component cutoffs; key recovery result; object/record checks;
deletion replay; denied/authorized access results; provider/bank reconciliation;
notification disposition; observed data loss; full elapsed time; RPO/RTO result;
exceptions; cleanup and reviewers/approval. Keep secret values and personal records
outside repository reports. Final runbook acceptance requires a successful reviewed
tabletop and actual managed database/Auth/private-object recovery exercise.
