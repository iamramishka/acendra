# CSA-211–214 and CSA-216 parallel production readiness

Date: 2026-10-15, Asia/Colombo. Base: 7916c6e on dev.
Status: IN_REVIEW for completed dummy preparation; operational acceptance remains pending.

The owner requested these five tasks together in parallel and instructed CODEX to
discover context. Repository and GitHub inspection located the tasks. No matching
open task issue was found. Open PR #153 changes checkout and finance flows and is
outside this scope. This local assignment follows AGENTS.md section 8; it is not
a GitHub task claim or production activation record.

After inspecting the latest deployment records and asking for actual targets,
the owner explicitly confirmed: "Prepare with dummy targets". This batch is
authorized preparation with intentionally unusable placeholders, not live setup.

| Tasks | Owner | Exclusive writable scope | Branch | Isolated checkout |
| --- | --- | --- | --- | --- |
| CSA-211 | CODEX payments agent | docs/deployment/CSA-211-PAYMENT-NOTIFICATIONS.md | docs/csa-211-payment-verification | ../csa211 |
| CSA-212 | CODEX finance agent | docs/deployment/CSA-212-FINANCE-PERMISSIONS.md | docs/csa-212-finance-verification | ../csa212 |
| CSA-213/214/216 | CODEX operations agent | docs/operations/CSA-213-MONITORING.md, CSA-214-BACKUPS.md, CSA-216-RECOVERY-RUNBOOK.md | docs/csa-213-216-operations | ../csa213-216 |
| Integration | CODEX root | this board; five matching notes in TASKS.md; sequential integration of listed documents | docs/csa-211-216-production-readiness | ../acendra-production |

Restricted: runtime code, migrations, workflows, environment configuration,
secrets, shared specifications and other TASKS.md entries. Temporary shared-file
ownership covers only the five task notes until review/handoff. Approval authority: project owner
or designated maintainer. Existing deployment documents contain deliberately
unusable dummy targets; they do not identify an accessible production environment.

Dependencies: verified target access and release identity, Phase 8 acceptance,
real payment sandbox acceptance, reviewed bank/payment runtime enablement,
selected notification/monitoring/backup providers, operational contacts and
managed restore evidence. Independent document preparation and offline
regressions may proceed in parallel; production mutations remain dependency ordered.

Verification criteria: inspect actual source references; run relevant local
regressions in isolated checkouts; review integrated diff; validate relative
document links and git diff --check. Keep all five operational task boxes
unchecked until their real acceptance evidence exists. Mock tests do not prove
production permissions, payment delivery, alert routing or recoverability.

No request for purchases, messages to third parties, role changes or live
financial transactions is inferred. Deliver concrete operator procedures and
record the exact missing access/evidence instead of inventing completion.

## Deliverables and local evidence

- [Payment notification protocol](../deployment/CSA-211-PAYMENT-NOTIFICATIONS.md): provider callback and student email boundaries, acceptance matrix and restricted evidence template.
- [Finance permission procedure](../deployment/CSA-212-FINANCE-PERMISSIONS.md): role/MFA/session/independence, storage/RPC denials, concurrency and audit acceptance.
- [Monitoring plan](../operations/CSA-213-MONITORING.md): proposed thresholds, safe telemetry, escalation and delivery evidence.
- [Backup specification](../operations/CSA-214-BACKUPS.md): accepted recovery baseline, proposed cadence and failure margin, encryption/key recovery and retention evidence.
- [Recovery runbook](../operations/CSA-216-RECOVERY-RUNBOOK.md): containment, isolated restore, deletion replay, financial reconciliation and authorized reopening.

Three agents prepared the five documents concurrently in isolated worktrees.
Root sequentially integrated commits 4949c8e, 76d9b69 and 2700ff8, then aligned
the finance deployment placeholders with the existing common dummy contract.
Only these documents, this board and the five matching TASKS.md notes changed.

Fresh isolated verification: payment suites 78 passed; finance HTTP suites 175
passed; recovery Python safeguards 5 passed and Storage/notification Node
safeguards 7 passed. All completed without failures; Node suites had zero skips.
The notification recovery suite is included in both payment and operations
commands: 265 passing test executions include two repeated tests, not 265
distinct test cases. Exact commands and limits are recorded in the task documents.

These are local/synthetic regressions. No production requests, provider charges,
email delivery, alerts, secret injection, managed backup configuration or actual
managed recovery drill occurred. SQL/live Auth/storage/permission acceptance,
operational recipients, selected providers and target-specific runtime enablement
remain pending. All five operational task boxes remain unchecked.

Integrated validation passed: 39 relative links resolve; all five operational
task boxes remain unchecked with pending notes; git diff origin/dev --check is
clean. Root reviewed the scoped diff, and an independent agent found no concrete
source-fact, unsafe-procedure, link or scope defects. Owner/designated maintainer reviews preparation, then
authorizes later real target configuration under retained release requirements.
Temporary shared-note ownership is released at this review handoff.

## Source-fact refresh — 2026-10-16

Dev tip moved from `7916c6e` to `422362f` after the initial preparation.
Three source-visible changes affect the prep documents; CSA-213 and CSA-214
operations docs are unaffected (no monitoring/backup source files changed).

**Payment entry-point architecture** (`CSA-207-210`, `CSA-211`): All three
payment functions now route through `_shared/payments/staging-entrypoints.mjs`.
The shim opens the gate only when `APP_ENV=staging` plus three matching staging
identifiers are present simultaneously. A production deployment
(`APP_ENV=production`) does not satisfy the guard; the gate remains closed.
A separately reviewed production runtime enablement change is still required
after provider acceptance. Updated: `CSA-207-210-SECRETS-PAYMENTS.md` PayHere
code gate section; `CSA-211-PAYMENT-NOTIFICATIONS.md` webhook description.

**New `bank-transfer-read` Edge Function** (`CSA-212`): CSA-179 added a new
function exposing `csa179_read_bank_transfer` (student own-order and
finance-team queue, `service_role`-only, no env enable flag). Added to the
`CSA-212-FINANCE-PERMISSIONS.md` release boundary section with its regression
references (`csa179_bank_reads.test.sql`, `csa179_bank_read.test.mjs`).

**New migrations** (`CSA-208/209`, updated separately 2026-10-16):
`20261014000100/000200_csa179_bank_reads.sql` — covered in the database/storage
preparation doc update recorded there.

No operational blockers changed. All five task boxes remain unchecked.
