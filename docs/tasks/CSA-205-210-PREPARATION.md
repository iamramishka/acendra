# CSA-205–210 production preparation

Date: 2026-10-14 (Asia/Colombo). Status: IN_REVIEW for documentation;
all six operational tasks remain pending. User authorized parallel preparation
with dummy details and deferred live configuration. No production deployment,
secret injection, migration, purchase or payment activation is authorized by
this preparation record.

## Ownership and scope

No corresponding open GitHub task found during issue/PR inspection. This is a
local documentation assignment under AGENTS.md section 8, not a GitHub claim.
Initial base: ca3158b; integration refreshed onto origin/dev e7a1cdc.
Open PR #146 continues Phase 8 acceptance and is outside this scope.
No overlapping production worktree or open production PR was found.

| Tasks | Accountable owner | Exclusive writable scope | Branch | Isolated worktree |
| --- | --- | --- | --- | --- |
| CSA-205/206 | CODEX hosting agent | docs/deployment/CSA-205-206-HOSTING.md | docs/csa-205-hosting-placeholders | ../acendra-csa-205-hosting |
| CSA-207/210 | CODEX secrets/payment agent | docs/deployment/CSA-207-210-SECRETS-PAYMENTS.md | docs/csa-207-production-placeholders | ../acendra-csa-207-secrets |
| CSA-208/209 | CODEX database agent | docs/deployment/CSA-208-209-DATABASE-STORAGE.md | docs/csa-208-production-placeholders | ../acendra-csa-208-database |
| Integration | CODEX root | this record and integration of the three documents | docs/csa-205-production-preparation | ../acendra-csa-205-preparation |

Restricted files: all runtime code, migrations, workflows, shared requirements
and TASKS.md. No shared-file changes are needed. Project owner/designated
maintainer controls acceptance and later concrete release approval.

## Dummy target contract

- Canonical domain: https://courses.example.invalid
- Staging domain: https://staging.courses.example.invalid
- Hosting account/project: DUMMY_HOST_ACCOUNT / DUMMY_HOST_PROJECT
- Hosting provider: UNSELECTED (no provider recommendation or purchase implied)
- Production Supabase project: DUMMY_PRODUCTION_PROJECT_REF
- Production Supabase URL: https://supabase.example.invalid
- Release commit/operator: DUMMY_RELEASE_COMMIT / DUMMY_RELEASE_OPERATOR
- PayHere live merchant: DUMMY_PAYHERE_MERCHANT_ID; payments remain disabled
- Credentials: REPLACE_IN_APPROVED_SECRET_STORE; never real secrets in these files

These values are intentionally unusable. Do not send network requests, build a
release or run deployment commands with them. Replace them with verified approved
targets during the later configuration task.

## Dependencies and verification

Dependencies: Phase 8 release/security acceptance, managed backup and restore
evidence, provider/domain selection, authorized target access and concrete release
approval. PayHere additionally requires real sandbox acceptance and a reviewed
runtime enablement change. CSA-206 follows hosting target selection; CSA-209
policy verification follows the single ordered CSA-208 migration application.

Preparation verification: inspect actual source references, verify no fabricated
credential binding or deployment evidence, review each diff and run git diff
--check. Documentation review does not satisfy production acceptance or replace
Flutter, database, provider or browser verification.

## Deliverables

- [Hosting and HTTPS preparation](../deployment/CSA-205-206-HOSTING.md)
- [Secret and payment preparation](../deployment/CSA-207-210-SECRETS-PAYMENTS.md)
- [Migration and storage preparation](../deployment/CSA-208-209-DATABASE-STORAGE.md)

Operational next action: replace dummy targets through authorized account access,
complete retained release gates, then execute and record production verification.

## Preparation completion evidence

Three agents prepared the documents in parallel in the isolated worktrees above.
Root integrated their commits through cherry-pick after refreshing the base.
Reviewed actual environment reads, payment entry-point gates, migration filenames,
test filenames, public configuration validation and ignored local config pattern.
The integrated diff contains only these four documentation files.
`git diff origin/dev --check` passed. Local documentation link validation passed.
No runtime or production checks were run for this documentation-only change.
The preparation is submitted for review; all six operational tasks remain pending.
