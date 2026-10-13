# Phase 8 acceptance continuation

Date: 2026-10-13, Asia/Colombo. Authority: project owner's explicit request to
complete CSA-184–188, CSA-200 and CSA-201 in parallel. Owner: CODEX root.
Base: origin/dev `8365d844dc717cb2dc572205635639ba148c003f`.
Open PR inventory was empty at allocation. Existing merged task worktrees are
preserved; the primary checkout has unrelated dirty marketplace work and is excluded.

| Scope | Accountable worker | Branch | Reserved runtime ports |
|---|---|---|---|
| CSA-184–186 permissions, private storage, uploads | security_runtime | codex/test/csa-184-186-acceptance | 61110–61119 |
| CSA-187–188 browser, headers, secret scans | web_security | codex/test/csa-187-188-acceptance | 61210–61219 |
| CSA-200–201 recovery evidence | recovery | codex/test/csa-200-201-acceptance | 61310–61319 |
| Integration and registry reconciliation | root | codex/docs/csa-184-201-acceptance | none |

Workers create separate worktrees from the stated base and record task-specific
claims before edits. Root owns this board, existing task evidence updates and any
bounded TASKS.md reconciliation. Workers own only their new task-specific tools,
tests and acceptance documents. Migrations, production handlers, shared contracts,
dependency files and CI workflows are excluded unless coordinated separately.

Dependencies: merged PRs #120/#123/#124/#125/#126, approved security requirements,
disposable runtime availability and existing hosted CI. Issue #119 and #117 retain
their existing CODEX ownership; this is an owner-authorized continuation, not a
duplicate claim. Missing CSA-184–188 Issues use the bounded documentation fallback
in AGENTS.md section 8; implementation work requires recorded task coordination.

Verification: fresh effective SQL/Storage evidence where feasible, dedicated
history/build scans, explicit local versus deployed browser evidence, actual
recovery checks, independent review and scoped diff verification. No production
data or credentials, deployments, real provider transactions, policy approval,
issue closure or merge is authorized by this record. Project owner retains P0
acceptance, recovery-policy decisions and release authority.

Status: IN_REVIEW. Exact commands, outcomes and remaining dependencies are
be recorded in task acceptance documents. DONE requires all applicable acceptance
requirements; passing component tests or merging evidence alone is insufficient.

Coordinated scope extension: security_runtime holds temporary exclusive ownership
of `tool/supabase_smoke.mjs` for only importing/calling a new task-specific admin
media Storage smoke. This closes a discovered private thumbnail/lesson-image REST
verification gap in the existing disposable CI stack. Existing policies, production
handlers and inspector gates remain unchanged. Root integrates the completed commit
and releases the shared ownership after review.

Owner decision update: the project owner replied “you can decide” to the operations
question. The selected baseline is recorded in
`docs/decisions/CSA-200-RECOVERY-OPERATIONS-BASELINE.md`; selection is resolved,
while actual implementation and measured recovery/hosting/logging evidence are not.

Integration handoff: root reviewed the Storage smoke and recovery harness changes,
and the recovery delegate independently reviewed the header/scanner changes.
Review defects (accepting server errors as denials and overly broad header policies)
were fixed with regression tests before integration. Root reruns passed eight header
tests, three Storage safeguards, two notification-loss tests, five recovery safeguards
and the explicitly enabled scanner regression. The optional scanner test is skipped
on platforms without configured Gitleaks and is not reported there as scanner evidence.

Hosted Supabase run38353918916 passed the exact Storage smoke revision88d5ea8,
including all SQL, real private image/receipt/PDF transport, MFA and cleanup.
The combined branch is submitted for its own CI and owner review. Worker clusters,
browser and local server were stopped; worker worktrees and source evidence remain
preserved. Shared runner ownership is released into root's reviewed integration.

Remaining requirements: approved real file-inspection integration and enabled
operational finance/media journeys; deployed response policies and stored/authenticated
browser payloads; configured release/log controls; actual managed backup/object/service
restoration, representative volume and provider reconciliation. These are explicit
acceptance gaps, not resolved by local policy selection or component test success.
