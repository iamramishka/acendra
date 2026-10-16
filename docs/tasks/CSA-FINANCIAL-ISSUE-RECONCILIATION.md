# Financial issue reconciliation — 2026-10-16

Owner: CODEX root. Status: IN_REVIEW (documentation reconciliation). User authorized parallel fixes for
issues #72, #77, #80, #81, #82 and #85, limited to code fixes and development
verification; no service configuration or live acceptance.

Branch: docs/csa-108-financial-issue-reconciliation.
Worktree: C:/Users/ramis/.codex/worktrees/financial-issues-reconcile/acendra.
Base: dev 75d74ae. Approval authority: project owner/designated maintainer.

Exclusive writable scope: this record, stale Phase 5 descriptions in TASKS.md,
CSA-102.md, CSA-103.md, CSA-108-113-INTEGRATION.md, CSA-114-120.md and the
CSA-114-120-ENTITLEMENTS.md contract status header. No implementation, migration,
API shape, dependency or production configuration changes.

Open issues, PRs, task records and worktrees were inspected. No open PR or
conflicting active documentation claim was found. The CSA-226–235 preparation
assignment explicitly excludes these files. Existing implementation owners and
historical branch/worktree records remain preserved. Three authorized read-only
agents reviewed separate receipt/bank, entitlement/notification and webhook/test
surfaces; only root edits documentation in this isolated worktree.

Verification criteria: confirm merged PR evidence, run current Node tooling,
reconcile accepted development scopes without asserting live acceptance, and
review the diff. Database/Flutter execution is not required for text-only edits;
historical hosted CI must remain distinguished from fresh local verification.

## Findings and verification

No actionable implementation defect was identified in the three bounded reviews.
Fresh full `npm run tool:test`: 772 total, 762 passed, zero failed, 10 skipped
database suites. Focused reviews additionally passed 81 receipt/bank tests,
40 entitlement/notification tests and 50 webhook/adapter/probe tests; these
overlap the full suite and must not be added to its total. No fresh database,
Flutter, live provider, Storage or email acceptance is claimed.

| Issue | Verified development result | Remaining work |
| --- | --- | --- |
| #72 | Coverage fixes integrated through PR #71 (972a160b) | Real PayHere sandbox acceptance remains tracked by CSA-100/#65 |
| #77 | Webhook integrated through PR #79 and subsequently merged PR #78 | Real callback/retrieval evidence and financial acceptance; IN_REVIEW |
| #80/#81/#82 | Receipt/bank implementation integrated in PR #84 (a19fd048), with successful hosted Flutter/Supabase checks and private Storage lifecycle evidence | Production inspection and banking operational gates remain separate |
| #85 | PR #86 (1729117e) accepted CSA-114/116/117/118/120 development implementation | CSA-119 live provider/sender, deduplication, scheduler and delivery acceptance; IN_REVIEW |

PR #159 later introduced an authorized exact staging sandbox gate. Historical
claims that the callback is unconditionally disabled are superseded by that
staging-only gate; no production enablement or provider acceptance follows.

No new code fix is warranted by these reviews. Stale progress/CI/dependency text
is corrected while original dated implementation evidence is retained as history.
Issue #85 stays open for CSA-119 and #77 stays open for provider acceptance.
