# CSA-012: Environments and budget approval proposal

Owner approval recorded 2026-10-11 (Asia/Colombo): the project owner replied "go ahead" after these six reviews were presented. This accepts the documentation baseline and authorizes merge; runtime, legal/processor, provisioning and production gates remain unverified. See [approval and completion record](../requirements/CSA-011-017-APPROVAL.md). Earlier proposal/pending wording below describes preparation or retained downstream conditions, not a missing owner decision.

Date: 2026-10-11 (Asia/Colombo)
Status: APPROVED environment/budget baseline - owner accepted 2026-10-11; provisioning/recovery gates retained
Preparation owner: CODEX video-budget agent
Integration base: e1cf11f (origin/dev); branch: codex/docs/csa-012-phase0-review
Scope: this document only. No environment was provisioned, bill incurred or live configuration changed.

## Decision to approve

Use local isolated development/CI plus separate hosted staging and production. For launch readiness, propose two separate Supabase Pro organizations, each with one Micro project, and a combined **USD 150/month planning ceiling** for infrastructure. Keep development at USD 0 in hosted recurring charges. Reserve USD 35 for staging, USD 95 for production and USD 20 contingency. These are approval thresholds, not provider-enforced hard caps or a spend authorization.

Mux Basic signed 1080p video follows CSA-011's pending recommendation. Proposed data region is specific Singapore (ap-southeast-1) for both Supabase projects, conditional on latency testing and CSA-015 processing/transfer review. The business country is Sri Lanka and course billing remains LKR under the approved PayHere decision; USD is only the infrastructure budgeting unit. No exchange rate is assumed.

Separate Pro organizations cost more than two projects in one organization but isolate usage quotas, billing and organization-level access. A single Pro organization with two Micro projects is approximately USD 35/month; do not adopt that cheaper alternative without reviewing shared quotas and production dashboard access. Free hosted staging can support early synthetic experiments, but does not substitute for Pro feature parity/release testing.

## Requirements and coordination

TASKS.md CSA-012; PLAN.md cost management and risks RISK-008..010; SRS.md NFR-SEC-002/003/008/012, NFR-REL-001/005/007, NFR-PRIV-001..009, section 11.4 and open hosting-budget decision; SECURITY.md environment, secret, logging and backup requirements; AGENTS.md sections 12, 35, 39 and 41; docs/PARALLEL_WORKFLOW.md.

Current origin/dev accepted CSA-003 roles, CSA-004 PayHere/LKR, CSA-006 lifetime access/refunds and protected PDF policy remain binding. Their approvals were confirmed by the coordinator's merged-PR review, not reset by this proposal. Local branch started at 9355311 and is rebased onto current origin/dev for documentation-only integration. Exclusive scope/assignment is recorded in the coordinator's CSA-011-017 parallel board.

## Environment matrix

| Environment | Backend and data | Payment/video/email | Access and deployment | Recurring allocation |
| --- | --- | --- | --- | --- |
| Development | Local Supabase per task; synthetic fixtures; isolated ports, project IDs and volumes | PayHere sandbox or explicit mocks; video fixtures, synthetic receipt files; email captured locally | Assigned agent worktree; no production credentials; local builds | USD 0 hosted |
| Pull-request CI | Ephemeral isolated backend/test data, migrations from clean state; no writable shared test DB | Mock provider tests plus isolated sandbox only when approved; no real payouts or customer data | Untrusted PR jobs receive no deployment secrets; minimum permissions | Use existing included runner quota; paid runners require separate approval |
| Staging | One dedicated Supabase Pro Micro project in a nonproduction organization; synthetic accounts and objects | Sandbox PayHere credentials; separate Mux environment/signing keys and fixture assets; mail sink or allowlisted test recipients | Approved maintainers; reviewed deployment; isolated callback URLs, Auth redirect allowlist, storage and domain | USD 35 |
| Production | Separate Supabase Pro Micro organization/project; production RLS/grants and private storage | Approved live PayHere merchant; production Mux environment; approved SMTP; bank receipts restricted | Owner/designated release maintainer, least privilege and MFA; explicit release approval, audited secret injection | USD 95 |
| Contingency | Available only through owner review | No automatic paid upgrades | Owner controls allocation; cannot relax security for price | USD 20 |

Proposed public domains are placeholders awaiting ownership: staging.<approved-domain> and <approved-domain>. Do not configure redirects, CORS or CSP with unrestricted wildcards. Assets, user IDs, JWT issuers/audiences and callback secrets must never cross environments. Mux billing allowances may be shared across environments/account: credential separation does not imply separate free allowances. Confirm provider organization access supports the intended split; use separate accounts if keys alone do not prevent staff access to production.

## Current price evidence

Official sources checked 2026-10-11; USD before tax and currency conversion:

- [Supabase pricing](https://supabase.com/pricing): Pro starts at USD 25/month per organization; USD 10 compute credit covers one Micro. Includes 100,000 MAU, 8 GB database disk/project, 100 GB files, 250 GB uncached and 250 GB cached egress; daily database backups retained seven days. Quotas must be verified at their organization/project billing scope.
- [Cost controls](https://supabase.com/docs/guides/platform/cost-control): Pro Spend Cap covers certain usage but excludes compute and opted-in add-ons such as PITR, custom domain and IPv4. It cannot set a custom USD 150 overall cap. Exceeding covered quotas can restrict service.
- [Mux pricing](https://www.mux.com/docs/pricing/overview): Basic input free; 1080p storage USD 0.003/min/month; first 100,000 delivery minutes/month free, then USD 0.001/min in the modeled tier. PAYG USD 20 monthly credit is excluded from conservative budgeting. No DRM, live streaming, downloadable renditions or AI workflows included.
- [Supabase regions](https://supabase.com/docs/guides/platform/regions): specific Singapore is available. Region choice does not establish legal compliance or control all CDN/processor locations.

Email, hosting, monitoring, domain and object backups have allowances below, not verified provider quotes or selections. Payment fees, merchant subscriptions and refund/dispute costs require the accepted PayHere commercial readiness follow-up; they are excluded from the infrastructure ceiling and must be approved separately before live sales. This document does not authorize an unbounded transaction-fee budget.

## Monthly allocation and forecast

| Category | Staging allocation | Production allocation | Combined allowance | Basis |
| --- | --- | --- | --- | --- |
| Supabase Pro + one Micro each | USD 25 | USD 25 | USD 50 | Published baseline; no paid add-ons |
| Mux video | USD 1 | USD 24 | USD 25 | CSA-011 scenarios; gross usage before credits |
| Flutter static hosting | USD 0 | USD 5 | USD 5 | Planning reserve; provider not selected |
| Transactional email | USD 0 | USD 5 | USD 5 | Planning reserve; SMTP provider not selected |
| Monitoring | USD 0 | USD 5 | USD 5 | Reserve; redact credentials and private data |
| Encrypted object/source backups | USD 5 | USD 15 | USD 20 | Reserve, not a quote; include recovery egress |
| Domain renewal amortized | USD 0 | USD 2 | USD 2 | Reserve; annual invoice needs approval |
| Unallocated environment headroom | USD 4 | USD 14 | USD 18 | Buffer within each environment limit |
| Owner-controlled contingency | - | - | USD 20 | Additional review only |
| **Total ceiling** | **USD 35** | **USD 95** | **USD 150** | Includes headroom and contingency once |

Forecast assumes 1,200 stored production video minutes plus 60 staging minutes and 2,000 staging delivery minutes. No existing Mux-account usage consumes the shared allowance. Treat table demand as assumptions until provider dashboards/load tests verify it.

| Scenario | Production video delivery | Mux gross including staging | Supabase baseline | Known subtotal | Consequence |
| --- | --- | --- | --- | --- | --- |
| Pilot: 100 learners x 120 min | 12,000 min | USD 3.78 | USD 50 | USD 53.78 | Remaining services fit only after quotes/backup review |
| MVP: 500 learners x 180 min | 90,000 min | USD 3.78 | USD 50 | USD 53.78 | Below USD 25 video allowance; small margin before free delivery ends |
| Growth: 2,000 learners x 240 min | 480,000 min | USD 385.78 | USD 50 | USD 435.78 | Exceeds ceiling before other services; owner approves revised budget before scaling |

At fixed storage, the USD 25 video allocation allows approximately 121,220 total monthly delivery minutes, including staging, without relying on credit (3.78 + (121,220 - 100,000) x 0.001 = 25). Actual invoice resolution, upload minimums and repeated/prefetched playback can change forecast usage. Recheck plan/account allowance before relying on this threshold.

Nonvideo example: 500 learners receiving five 80 MB PDF deliveries/month produce approximately 200 GB delivery, before API traffic, images, retries and other consumers. At 2,000 learners the same behavior produces 800 GB. Do not assume all private PDF delivery is cached or spend another environment's quota. Preserve authorization; budget additional egress or optimize approved delivery instead of making private files public. Initial per-production operating targets: database <4 GB, private objects <50 GB, each egress category <150 GB/month, monthly active users <10,000. These are early review triggers, not guaranteed capacity/throughput or automatic user limits.

## Cost controls and response

1. Before provisioning, owner records approver, bill payer, monthly/one-time caps, provider plan and allowed administrators. No paid service/add-on starts on a draft allowance.
2. Keep Supabase Spend Cap enabled initially, reviewed database disk limits and no automatic compute/PITR/domain add-ons. Test quota exhaustion in staging; publish user recovery behavior. Cap-induced denial of payment callbacks is unacceptable without durable provider retries/reconciliation and an operations response.
3. Review actual cost and remaining quotas weekly in prelaunch/pilot; daily during launch or threshold events. Track projected month-end gross spend and separate invoice credits/taxes/FX. Select an operational monitor/task owner during release readiness; this document creates no scheduler.
4. At 50% usage/allocation consumed or forecast >80% of USD 150, investigate growth, token abuse and redundant fetches. At 80% provider quota or forecast above USD 150, owner decides spend increase or a communicated capacity plan before exhaustion. Mux review starts at 80,000 delivery minutes/month or 80% of its allowance, whichever first.
5. Rate-limit playback issuance, restrict uploads to authorized staff, bound upload size/duration and set a reviewed catalog storage limit. Token throttling cannot alone bound a valid token's replay/CDN delivery bill. Verify provider alerts/budget controls in its actual account; no universal hard stop is asserted.
6. Owner approval required for any additional project, compute upgrade, paid runner, DRM, PITR, paid hosting/email plan or cap removal. Maintain ledger of recurring and one-time commitments. Do not stop production payments or delete financial history/content merely to stay under a budget; use the authorized incident/capacity process and reconcile pending settlements.

## Recovery and release gates

Propose **RPO 24 hours and RTO 4 hours** for owner review as a minimum-cost candidate, not an accepted financial-loss tolerance or achieved recovery result. Daily database backups alone cannot guarantee these targets. If verified financial transactions cannot be reconstructed to an owner-approved point, strengthen the recovery design and revise the budget before release.

Supabase database backups exclude Storage object bytes. Maintain separate encrypted private object/source-master backups with a consistent manifest and restricted restore credentials; review retention/deletion with CSA-015 and do not use an arbitrary retention period as policy. Test full database/auth/object recovery in an isolated destination, reconcile payments/grants/audit/outbox with provider and bank evidence, then verify student access and signed content. Include backup storage, transfer and restore labor/cost in quotes. [Backup limitations](https://supabase.com/docs/guides/platform/backups).

A stricter financial RPO/PITR decision is open: [Supabase pricing](https://supabase.com/pricing) lists PITR from USD 100/month, so selecting it for production reopens the USD 150 envelope. No financial reliability requirement is waived to preserve the proposed limit. Record recovery test duration and last trustworthy transaction before approving RPO/RTO.

## Acceptance checklist and owner record

- [ ] Owner accepts environment separation, specific region after privacy/latency review, USD 35 staging + USD 95 production + USD 20 contingency, and names payer/operations/release owners.
- [ ] Provider plans, tax/FX assumptions, annual/one-time costs and payment-fee budget confirmed; email/hosting/monitoring/backup quotes fit the envelope or owner approves revision.
- [ ] CSA-011 selection/PoC and CSA-015 privacy/security decisions accepted; existing approved commerce and role policies preserved.
- [ ] Credentials, data, callback endpoints, Auth redirects, storage, Mux assets and least-privilege dashboard access are demonstrably isolated. Frontend bundles contain no privileged keys.
- [ ] Reviewed migrations and RLS/grants/negative authorization tests pass in staging with synthetic data; CI is isolated and untrusted PRs have no secrets.
- [ ] Load/playback/PDF tests and actual billable units confirm forecast capacity; limits/alerts/quota-exhaustion response exercised.
- [ ] RPO/RTO accepted after financial recovery review, restore drill succeeds with private object backups, retention/deletion agreed and backup quote included.
- [ ] Explicit release approval precedes production provision/deploy/live payments; task moves to DONE only after formal acceptance and required integration.

Approval record: Project Owner accepted environment/budget baseline on 2026-10-11; USD 150 planning limit approved; named billing owner, region/processor review and recovery feasibility pending; provider accounts not provisioned. Required final approval covers these concrete choices; implementation evidence remains a later release gate.

## Handoff

Task/owner: CSA-012 / CODEX preparation. Status: DONE for accepted documentation; downstream verification retained.
Files changed: docs/decisions/CSA-012-ENVIRONMENTS-BUDGET.md only.
Shared contracts changed: none; environment operations and billing proposal only.
Checks: git diff --check, arithmetic and scope self-review. No service configuration, load, restore, Flutter or database tests executed for this documentation-only change. Commit/PR: recorded by coordinator at submission.
Remaining: owner approval, quotes, operational assignees and recovery/privacy/PoC verification. Next owner: Project Owner for decisions; designated infrastructure maintainer for approved configuration. No purchase, deployment, merge or DONE claim.
