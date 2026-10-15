# CSA-208/209 migration and private storage preparation

Date: 2026-10-14 (Asia/Colombo). Owner: CODEX database agent.
Status: IN_REVIEW documentation; CSA-208 and CSA-209 remain operationally pending.
Assignment: [parallel preparation record](../tasks/CSA-205-210-PREPARATION.md).
This document prepares later configuration with dummy details. No database,
storage, deployment, secret or payment configuration was changed.

## Current existing-service/free-only handoff — 2026-10-15

CSA-208 and CSA-209 operational status: **BLOCKED**. Coordination: issue #160 and
[worker scope](../tasks/CSA-PHASE9-FREE-SECURITY-BOARD.md). No production target is
approved; the existing project is staging. Do not create a service, enable paid
backups, alter policies or apply migrations to remove this hold.

Merged PR #153 added `20261014000100_csa179_bank_reads.sql` and
`20261014000200_csa179_bank_read_alias_fix.sql`; the reviewed release now contains
**33 migrations**. The 31-file count below is historical. Earlier staging work
recorded all 33 applied, all 34 application tables with RLS and restricted
finance RPCs. That is staging evidence, not production migration acceptance.
Compare all actual versions and drift at the reviewed release revision. Root's
2026-10-15 read-only inventory reconfirmed 33 applied migrations, latest
`20261014000200`, all 34 application tables with RLS and all three protected
buckets private. No production designation, managed backup listing entries or
PITR were observed. This is a deployment inventory, not a restore test or
positive protected-delivery acceptance.

[`tool/phase9_security_inventory.sql`](../../tool/phase9_security_inventory.sql)
is a no-install, transaction-read-only metadata preflight for the authorized
existing SQL console. Confirm console project identity before execution. It
lists migration versions, application RLS, protected bucket settings, policy
metadata and finance RPC EXECUTE grants. It does not list objects, read receipts,
create signed URLs or modify records. **Not executed** by this worker; root owns
hosted inspection. Missing rows are missing evidence, never PASS. Confirm all
protected buckets exist/private, expected limits/MIME settings, and trusted
finance RPCs deny anon/authenticated EXECUTE while allowing service_role.

Policy names/RLS flags do not prove safe predicates or actual Storage API
isolation. CSA-208 resumes only with an existing approved isolated production
target, reviewed release, recovery evidence and migration authorization.
CSA-209 then requires actual anonymous/student/cross-user and authorized delivery
checks after application. No local test suites or hosted mutation ran. Root
verified included Actions capacity and controls the bounded hosted CI dispatch.

## Historical dummy target

| Field | Intentionally unusable value |
| --- | --- |
| Production project | DUMMY_PRODUCTION_PROJECT_REF |
| Production backend URL | https://supabase.example.invalid |
| Canonical application URL | https://courses.example.invalid |
| Staging application URL | https://staging.courses.example.invalid |
| Release commit | DUMMY_RELEASE_COMMIT |
| Release operator | DUMMY_RELEASE_OPERATOR |
| Credentials | REPLACE_IN_APPROVED_SECRET_STORE |

Do not issue requests or execute deployment commands with these values. The
later operator must verify the actual project identity, organization, environment,
region and approved release commit through authorized account access. Repository
`supabase/config.toml` describes `acendra-local`, not a production target; no
linked-project metadata was available during preparation. Staging backend identity
must also be recorded separately before verification.

## Ordered execution for the later authorized release

1. Record one accountable migration/storage operator, exclusive shared-resource
   ownership, concrete release approval, reviewed commit and change window. Confirm
   that Phase 8 acceptance and outstanding security/release gates are resolved.
2. Inspect the target read-only. Compare its migration history and schema against
   the approved chain; inspect bucket identity/privacy, object paths, policies,
   grants, triggers and existing data. Record drift and obtain a reviewed resolution
   before applying changes. Never repair history, reset a database, overwrite
   objects or weaken RLS merely to make replay succeed.
3. Verify recoverable backups before mutation: database/Auth/configuration plus
   private object bytes, consistent manifests and deletion/tombstone records.
   Record encrypted backup location, restricted access, key recovery, retention,
   restore evidence and the recovery operator/alternate. Verify the selected
   RPO of 24 hours and RTO of 4 hours against actual recovery evidence.
4. Replay the exact approved release chain on an isolated staging target with
   synthetic fixtures. Verify migration ordering, grants/RLS, financial invariants
   and real Storage API denials. Review existing staging drift separately; a fresh
   disposable CI replay alone does not prove an existing target can be upgraded.
5. Review the target-specific pending-migration preview and backup/recovery plan.
   Apply the approved pending migrations once, in filename order, under the single
   operator. Record the actual tool/version, target, release hash, migration list,
   start/end times and result without credentials or private response bodies.
6. Verify CSA-209 against the resulting database/storage configuration and actual
   Storage API. Record all protected bucket flags, expected policies/guards,
   client denials and bounded authorized operations using exact synthetic fixture
   paths. Remove only the task-owned fixtures and record cleanup results.
7. Hold activation until the required security, content-access, payment,
   backup/recovery and release smoke evidence is accepted. On failure, stop the
   release and use the reviewed recovery procedure; do not invent automatic
   reverse migrations or delete financial audit data.

CSA-208 and CSA-209 must not mutate production in parallel. Storage provisioning
and policy changes are already embedded in the migration chain; CSA-209 is the
subsequent configuration and access verification. Independent documentation work
can proceed in parallel with hosting and secret preparation.

## Existing migration contracts

| Repository migration | Relevant behavior and target preflight |
| --- | --- |
| `supabase/migrations/20261011001700_csa108_113_bank_workflow.sql` | Creates private `bank-receipts`, a 5 MiB JPEG/PNG/PDF configuration, restrictive direct-client object denial and guarded receipt lifecycle. Inspect existing limits/MIME configuration as well as privacy; conflict handling does not establish every existing setting matches. |
| `supabase/migrations/20261011001800_csa108_receipt_deletion_guard.sql` | Extends trusted receipt lifecycle/deletion safeguards; preserve deletion/audit semantics during recovery. |
| `supabase/migrations/20261012002400_csa139_pdf_storage.sql` | Creates private `course-pdfs`, bounded PDF-only storage (at most 50 MiB), restrictive client object/bucket denial, opaque versioned paths and immutability guards. Unsafe existing bucket configuration or invalid stored paths abort application. |
| `supabase/migrations/20261012002500_csa140_pdf_derivatives.sql` | Depends on private PDF configuration and supports controlled derivative delivery. Direct original or signed Storage URL access must remain denied. |
| `supabase/migrations/20261012003100_csa164_media_uploads.sql` | Creates private `course-media` and trusted upload operations. Bucket insertion has no conflict clause: an existing bucket requires drift review before application, rather than blind replay. |
| `supabase/migrations/20261013003400_csa165_private_image_readiness.sql` | Publication readiness checks private media/PDF configuration. |
| `supabase/migrations/20261013003500_csa178_deferred_financial_checks.sql` | Corrects deferred financial invariant checks after RPC definer context ends. Include it in approved ordering; do not grant direct financial mutation privileges as a workaround. |

These are highlights, not a substitute for the entire reviewed migration chain.
At preparation base `fe68c6b0047dc956b291fd43f6813d39cec56696`, the directory
contains 31 SQL migrations: filename suffixes `001` through `025`, then `030`
through `035`. The first is `20261011000100_csa059_profile_role_schema.sql`;
the last is `20261013003500_csa178_deferred_financial_checks.sql`. Apply the
actual filenames in ascending order after comparison with target history. The
absent suffixes `026` through `029` are not evidence of unapplied migrations;
do not create replacements or repair history based on numbering alone.

Do not manually add duplicate dashboard policies. PDF MIME allowlisting is not
content inspection, and private buckets alone do not prove entitlement delivery.
The [PDF storage contract](../contracts/CSA-139-PDF-STORAGE.md) preserves authenticated
controlled delivery and prohibits issuing original Storage paths/signed URLs to
students. Receipt inspection, independent bank credit verification and production
media delivery remain separate operational requirements.

## Verification references and evidence limits

Actual repository checks include:

- `supabase/tests/database/csa108_113_bank_workflow.test.sql` for receipt/finance boundaries.
- `supabase/tests/database/csa139_pdf_storage.test.sql` and `csa140_pdf_entitlement.test.sql` for PDF storage and entitlement checks.
- `supabase/tests/database/csa164_media_uploads.test.sql` for trusted upload behavior.
- `supabase/tests/database/csa182_catalog_matrix.test.sql` for catalog-wide RLS/grants.
- `supabase/tests/database/csa178_deferred_financial_checks.test.sql` and `csa201_financial_failure_recovery.test.sql` for financial constraints/recovery.
- `tool/supabase_smoke.mjs`, `tool/role_api_smoke.mjs` and the `tool/csa200_storage_recovery.mjs` recovery module for disposable API evidence.
- `.github/workflows/supabase-foundations.yml` for disposable migration/test/lint/API verification; it does not deploy production.

[Integrated evidence](../reviews/CSA-178-201-FINAL-EVIDENCE.md) records successful
disposable Supabase tests and real private Storage archive/loss/restore checks.
It also retains managed-cloud restore, backup encryption/retention, production
scale recovery and deployed release acceptance gaps. Small synthetic recovery
timings cannot establish production RTO. PostgreSQL backups alone do not include
private Storage object bytes.

The [recovery baseline](../decisions/CSA-200-RECOVERY-OPERATIONS-BASELINE.md) selects
RPO 24 hours, RTO 4 hours and rolling 30-day backup retention, but does not prove
implemented controls. Restore into an isolated destination, reconcile database
references/object hashes and replay deletion records before exposing restored
data. Financial events require actual provider/bank reconciliation.

## Required completion record

### Dummy refresh verification and handoff — 2026-10-14

The isolated documentation branch `docs/csa-208-209-dummy-refresh` refreshed this
existing preparation only. Local inspection again found `project_id =
"acendra-local"` and no `supabase/.temp/project-ref` in the inspected checkout.
Those facts identify local configuration; they cannot establish a managed target,
remote migration history or deployed bucket state.

Fresh command in the isolated worktree:

```text
node --test tool/csa200_storage_recovery.test.mjs tool/local_supabase.test.mjs
```

Result: 14 passed, zero failures or skips. These tests cover archive integrity,
tombstone reconciliation, denial classification and local tooling isolation
guards with local fixtures. They do not replay SQL, inspect a live database,
prove Storage API denials or establish production restore readiness. No install,
database replay, database reset, hosted request or configuration mutation ran.

Operational blockers remain: actual staging/production identities and account
access; approved release hash, operator and exclusive migration ownership;
target drift/history inspection; staging upgrade and live access evidence;
recoverable encrypted backups and accepted restore/RPO/RTO evidence; and
outstanding Phase 8 security and journey acceptance. The latest integrated
review retains those acceptance gaps. CSA-208/209 remain unchecked in TASKS.md.

The next authorized operator must replace dummy target fields, collect the
completion record below and execute the ordered release gates. CSA-208 applies
the reviewed migration chain; CSA-209 then verifies resulting storage settings
and access. No concurrent production migration/storage mutation is authorized
by this refresh.

Retain the real target/organization and approved release hash, reviewer/operator,
migration history and drift review, staging upgrade results, backup/restore
evidence, actual applied migration list, post-application bucket/policy/grant
inventory, anonymous/student/cross-user denials, trusted lifecycle checks,
fixture cleanup and accepted release decision. Keep secrets and customer content
out of this record. Mark operational tasks complete only after those results are
verified; this dummy preparation provides no production completion evidence.
