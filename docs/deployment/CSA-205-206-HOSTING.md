# CSA-205/206: existing hosting and domain readiness

Current selection, 2026-10-18: retain owner-nominated `acendra.vercel.app` and select
`iamramishka` as release operator. Fresh API inventory still reports Hobby and one
visible staging backend; no eligible isolated production target was established.
The [delegated decision record](../operations/CSA-160-TARGET-SELECTION.md) supersedes
the unanswered hostname/operator selection below, while retaining release gates.

Date: 2026-10-15 (Asia/Colombo). Owner: CODEX hosting worker.
Documentation: IN_REVIEW. Operational CSA-205 and CSA-206: BLOCKED (held).
Assignment: [Issue #160](https://github.com/iamramishka/acendra/issues/160) and
[exclusive ownership](../tasks/CSA-205-206-FREE-HOSTING-OWNERSHIP.md).

The owner requested parallel progress using existing services only, with no new
services or spending. Missing requirements are held. This replaces the current
dummy-only worksheet; the [earlier preparation](../tasks/CSA-205-210-PREPARATION.md)
remains historical. It does not authorize production release or move staging data.
The earlier [budget baseline](../decisions/CSA-012-ENVIRONMENTS-BUDGET.md) is planning
context, not permission to spend under the current free-only constraint.

## Existing targets and evidence boundaries

| Field | Existing staging value | Production gap |
| --- | --- | --- |
| Hosting | Vercel project `acendra`, Hobby | Commercial production eligibility not established |
| Account/project identity | Team `team_EtrnsK9YUu6vKAJ92xpWe88T`; project `prj_xWYJdw35hJGS6caNi8fiQdnxenh2` | Approved environment-isolated production target and operator absent |
| Verified hosting domain | `https://acendra.vercel.app` | No approved production canonical hostname |
| Git production branch | `dev` in Vercel provider settings | Provider naming is not production authorization |
| Backend | `https://worrsweluwjmppwsygre.supabase.co`, project `worrsweluwjmppwsygre` | Explicitly authorized as staging, not production |
| Additional domain | `vinyup.com` registered Active in PayHere Sandbox, as reported in prior acceptance work | Does not establish DNS control, Vercel mapping, TLS or live merchant approval |
| Release | Phase 8 merged in PR #159; this worker started from `e494d9a` | Production release revision, rollback evidence and approval absent |

The root's 2026-10-15 read-only Vercel inventory confirms the Hobby project,
`dev` production-branch label and only `acendra.vercel.app` verified domain.
This worker did not read credentials, call provider APIs or repeat deployment
probes. Prior staging deployment and browser checks belong to Phase 8 evidence;
they do not verify today's production state. Root owns any consolidated remote
inventory and must retain its timestamp and exact scope separately.

## Free-only decision and holds

[Vercel's Hobby documentation](https://vercel.com/docs/plans/hobby) and
[fair-use guidelines](https://vercel.com/docs/limits/fair-use-guidelines) restrict
Hobby use to personal, noncommercial projects (consulted 2026-10-15).
A commercial course-selling launch therefore cannot be certified eligible on the
known plan. Sandbox behavior does not establish a live commercial exception.
Do not purchase an upgrade, open another hosting service, use a trial that can
incur charges, or relabel staging as production to clear this hold.

| Task | Status | Free work prepared | Hold release condition |
| --- | --- | --- | --- |
| CSA-205 production hosting | BLOCKED | Existing target inventory, runtime prerequisite, build/release and rollback checklist | Existing host eligibility for intended commercial use, approved isolated production target and release operator; otherwise retain hold under free-only scope |
| CSA-206 HTTPS/domain | BLOCKED | Domain evidence boundary, exact configuration dependencies and HTTPS checklist | Verified owner-controlled hostname/DNS scope, approved hosting target and domain mapping; verified certificate and redirects |

Do not request new services merely to finish the checklist. Current work remains
preparation until these prerequisites exist within the owner's constraints.

## Runtime prerequisite before a production artifact

[EnvConfig](../../lib/core/config/env_config.dart) declares `APP_ENV`,
`SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`; legacy `SUPABASE_ANON_KEY` is a
compatibility fallback. The issue #160 integration wires
[bootstrap](../../lib/app/bootstrap.dart) through `readForStartup()` and the
existing environment, URL and public-key validator. Publishable-key-only builds
therefore initialize the backend. Only wholly unconfigured development builds
may skip initialization; partial configuration and unconfigured hosted builds
fail before initialization. The production build workflow explicitly selects
`APP_ENV=production` and the publishable-key binding. This source fix needs passing
CI and review before integration. The current repository is public and uses
standard hosted runners, superseding its earlier private-minute capacity hold.
It does not establish production configuration or release acceptance. See the
[current integration handoff](../reviews/CSA-160-CURRENT-INTEGRATION.md).

Only public browser configuration belongs in Dart defines. Never include database
passwords, Supabase service-role/secret keys, payment merchant/app secrets, SMTP
credentials or video signing keys. A successful unconfigured Flutter CI build does
not prove backend initialization. Configuration files and generated artifacts used
in earlier staging acceptance are ignored local material, not a tracked deploy job.

## CSA-205 release sequence after holds clear

1. Confirm the eligible existing account/plan, approved production target, operator
   and immutable release revision. Recheck cost and usage restrictions without
   buying or enabling paid features. Keep staging separate.
2. Obtain reviewed public backend configuration for that target, complete the
   bootstrap prerequisite and required hosted checks within verified included quota.
   Do not dispatch CI while its zero-cost execution cannot be established.
3. Compile only the reviewed revision using an ignored public configuration file
   after approval. Scan generated browser assets for privileged material and record
   artifact digest and CI/build evidence. A generic command or template is not proof.
4. Deploy only the verified artifact through the authorized process. Preserve static
   asset 404 responses; verify client deep links, refresh and browser history.
5. Record deployment ID, release SHA, artifact digest, timestamp, operator and last
   known good deployment. Exercise rollback in the approved isolated environment;
   hosting rollback must not imply database migration rollback or financial deletion.

## CSA-206 verification after target/domain approval

1. Verify registrar/DNS ownership and current records. Use the selected host's exact
   domain verification and DNS instructions. Preserve mail and unrelated records;
   do not infer authority over all subdomains from one payment integration.
2. Verify domain mapping and trusted certificate hostname/chain, expiration, renewal
   owner, HTTP-to-HTTPS and canonical redirects. Do not treat a sandbox Active badge
   as evidence for any of these checks.
3. Coordinate exact Supabase Auth redirects, API CORS origins, payment return/cancel
   and callback addresses, and media origins with the assigned owners. Staging is
   currently explicitly bound in payment code; changing a host is a reviewed runtime
   change, not merely a DNS edit. Keep live activation gates closed.
4. Verify enforced CSP, HSTS, nosniff, restrictive referrer policy, permissions and
   frame restrictions against [SECURITY.md](../../SECURITY.md). Choose HSTS coverage
   from verified domain authority; confirm the referrer policy permits the approved
   provider integration without exposing full user URLs.
5. When authorized, use the existing read-only header checker against the final
   approved HTTPS URL: `node tool/csa187_headers.mjs <verified-final-https-url>`.
   The [checker](../../tool/csa187_headers.mjs) rejects redirects; inspect redirect
   behavior separately. No checker was run by this documentation task.

A header pass does not prove safe stored content, working authentication or a
complete purchase-to-learning journey. Verify browser startup without mixed
content or blocked required resources; session/error states; direct links and
logout; accessibility and responsive widths; then approved checkout and protected
content journeys after their separate backend and entitlement gates are satisfied.

## Handoff and verification

Completed: source/requirements review, explicit existing staging worksheet,
commercial/free-plan eligibility hold, production/domain prerequisites and bounded
release/rollback instructions. No deployment, DNS/TLS change, production migration,
secret injection, provider purchase, CI dispatch or local test suite was performed.
Verification: source/reference review, local Markdown target existence and
`git diff --check`. Hosted CI remains subject to root's free-quota check.

Inspected: AGENTS.md; Issue #160; TASKS.md CSA-205/206; PLAN.md Phase 9;
CSA-012 environment/budget decision; earlier preparation board; EnvConfig;
bootstrap; existing header-checker entry point; root's read-only inventory report.
Next owner: CODEX root integrates these exclusive documentation files, reconciles
TASKS.md and retains both operational holds. Project owner/designated maintainer
controls production target, domain and release authorization.
