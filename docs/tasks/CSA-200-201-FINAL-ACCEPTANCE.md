# CSA-200/201 final acceptance continuation

Owner: CODEX/recovery. Claim: https://github.com/iamramishka/acendra/issues/129.
Status: IN_PROGRESS. User authorized parallel completion. Base: origin/dev c89796f.
Branch: codex/test/csa-200-201-final-acceptance.
Worktree: C:/Users/ramis/Downloads/Acendra/csa-200-201-final-acceptance.
Scope: new tool/csa200* and this record; no production handlers, migrations or shared files.
Root owns shared runner integration. Existing Issues117/119 retain external gates.
Dependencies: actual disposable Supabase Storage/Auth APIs on hosted CI; no hosted project supplied.
Approval: project owner/security/operations. Approved targets RPO24h/RTO4h/retention30days
do not establish deployed controls or measured cloud recovery.
Overlap: root assigned disjoint recovery scope; backend worker owns financial HTTP journeys.
Acceptance: real private bytes downloaded into a durable archive, exact object loss via
Storage API, metadata absence, tombstone replay before restore, checksum verification,
metadata reconciliation and anonymous/student denial after restoration. Corrupt archives
must fail validation before any restore action. Cleanup touches exact task UUID paths only.

This tests pinned disposable Storage service recovery, not managed-cloud backups,
production volume, encryption/key recovery or actual RPO/RTO. Existing CSA201 SQL and
notification tests remain independent financial failure evidence.

## Current verification

`node --test tool/csa200_storage_recovery.test.mjs`: 5 passed, zero failures/skips.
Tests reject corruption in even tombstoned bytes, duplicate/missing/unbound objects,
wrong MIME/size/bucket/version/base64 and tombstone removal or additions. The entire
archive is validated against independently retained exact fixture identities and
tombstones before any restored object upload. `git diff --check` passed.
Explicit denial/missing-object statuses are required;500,503,429 and redirects
cannot masquerade as access-control success. Archive cleanup runs even when exact
remote fixture cleanup fails.

Real API execution is pending root's combined hosted CI run. Local host has no Docker
Linux runtime; parser tests do not simulate or establish actual service recovery.
Root shared runner integration calls `runStorageRecoverySmoke` with its existing
guarded local Storage context. The module cleans exact UUID object names on failure
and success, then deletes only its generated private temporary archive directory.
It suppresses service credentials, file bytes and arbitrary API error bodies.
