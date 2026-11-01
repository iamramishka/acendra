# Phase9 existing-service readiness and operational holds

Current selection, 2026-10-18: the owner delegated target/operator choices. See the
[selected configuration and fresh inventory](../operations/CSA-160-TARGET-SELECTION.md).
`iamramishka` is selected as release operator; the nominated hostname is retained.
The single visible backend remains staging, and encryption/full recovery are not
verified. Production tasks remain BLOCKED on capabilities, not unanswered names.
GitHub reconciliation, 2026-10-31: the repository is public. Both source PRs
[#172](https://github.com/iamramishka/acendra/pull/172) and
[#187](https://github.com/iamramishka/acendra/pull/187) are merged and contained in
`dev` at `cff285a554625b4956776c8f10ccf83c25142921`. Its
[Flutter baseline](https://github.com/iamramishka/acendra/actions/runs/41186415288)
and [SSH deployment](https://github.com/iamramishka/acendra/actions/runs/41186883246)
both succeeded, including the deployment smoke test. The 2026-10-19 private
repository/payment-limit block is historical; it is not a current CI blocker.
These runs establish source checks and deployment evidence, not complete
production acceptance for the hold matrix below. No account settings changed.

Date: 2026-10-15 Asia/Colombo. Owner: CODEX root. Coordination: [issue160](https://github.com/iamramishka/acendra/issues/160) and [parallel board](CSA-PHASE9-EXISTING-FREE-BOARD.md).

The owner authorized parallel work, no new services and no spending, with missing prerequisites held. All three isolated workers completed bounded documentation/preflight work. Production tasks remain BLOCKED until their operational requirements are met. No staging environment is reclassified as production.

## Historical read-only inventory, 2026-10-15

The provider observations below were not refreshed in the 2026-10-31 GitHub
review. They remain release prerequisites to verify, rather than current claims
about provider configuration. The later successful SSH deployment supersedes
earlier absence of deployment evidence, but does not verify backend isolation,
live merchant acceptance, notification delivery or backup/restore readiness.

- Vercel project acendra is on Hobby. Its only configured domain is verified acendra.vercel.app; provider production branch is dev. This provider label does not override the owner's staging designation. The commercial eligibility restriction is documented in [hosting readiness](../deployment/CSA-205-206-HOSTING.md).
- Supabase worrsweluwjmppwsygre is ACTIVE_HEALTHY in ap-northeast-1. Auth site/redirects are acendra.vercel.app. Custom SMTP is not configured. Secret names include platform configuration and sandbox PayHere settings; no live-provider/email setting names were observed. Values were never printed or committed.
- Metadata query found33 migrations, latest20261014000200;34 public/private application tables, all34 with RLS. bank-receipts, course-pdfs and course-media buckets are private. Metadata presence is not a complete authorization acceptance test.
- Backup API returned no listed backups, PITR disabled and WAL capability present. WAL capability alone does not establish an accessible backup, protected object bytes, recovery target or successful restoration. No backup was downloaded, scheduled or restored.
- Root executed [metadata preflight](../../tool/phase9_security_inventory.sql) once through the authorized staging management SQL API. It uses a read-only transaction and rollback, with statement/lock timeouts. Both csa112_review_bank_transfer and csa179_read_bank_transfer deny anon/authenticated EXECUTE and allow service_role. Only the final SELECT's two metadata rows were returned by this API; other counts above came from a separate read-only aggregate query. No table data, credentials, object keys or financial payloads were queried.
- PayHere vinyup.com Active sandbox registration is previous observed evidence. Hosting/DNS mapping and live merchant configuration were not changed or established by that registration.

## Production hold matrix

| Task | Free work completed | Resume condition |
| --- | --- | --- |
| CSA-205 | Existing host inventory, release/rollback prerequisites | Existing commercially eligible host, approved isolated production target and release operator; no upgrade or replacement service authorized |
| CSA-206 | Domain/HTTPS checklist and exact binding dependencies | Owner-controlled DNS scope, approved hosting/domain mapping, certificate and redirect verification |
| CSA-207 | Public/server secret inventory and fail-closed configuration review | Approved production target and secret versions; no staging-secret reuse or real injection performed |
| CSA-208 | Migration inventory and read-only preflight | Approved production database, recovery evidence and reviewed application/replay authorization |
| CSA-209 | Private bucket/RLS inventory and policy-review procedure | CSA-208 prerequisites plus production policy verification and entitlement/isolation tests |
| CSA-210 | Exact staging sandbox boundary review | Existing active live merchant/domain, retrieval/network access, reviewed production binding and approved controlled live verification |
| CSA-211 | Callback/email acceptance procedure | CSA-210 plus existing configured notification delivery and original callback/retrieval/email evidence |
| CSA-212 | Service-only finance RPC metadata and role/MFA matrix | Approved production role/session/MFA accounts, independent bank evidence and observed full workflow |
| CSA-213 | Existing-console diagnostic steps and private evidence template | Approved production designation, existing eligible telemetry/alert route, responders and delivered test alerts |
| CSA-214 | Actual empty backup inventory and complete-set checklist | Existing independent encrypted destination/key recovery, complete database/object/deletion set and isolated restore evidence within targets |
| CSA-216 | Concrete staging triage/CI commands and recovery hold checklist | Production target, named alternate, real backup/recovery destination and measured RPO/RTO drill |

No new service/account, paid plan, scheduled automation, production deployment, migration, secret injection, DNS change, live charge, alert message or backup transfer was performed. Existing phase8 owner acceptance remains separate from production release approval.

## Verification and cost boundary

The allowance figures below are historical 2026-10-15 evidence. Current public
repository workflows use standard Ubuntu runners, which are
[free for public repositories](https://docs.github.com/en/actions/concepts/billing-and-usage).
The private-repository minute-reserve condition below does not apply while
that eligibility holds. Recheck visibility and runner eligibility before future
runs; no paid runners, allowance changes or additional storage are authorized.
The 2026-10-31 repository API reports five caches totaling 2,157,119,674 bytes and
42 artifacts totaling 657,784 bytes. Those repository snapshots do not certify
account-wide storage allowance. This change adds no cache or artifact settings.

Historical verification: all scoped diffs reviewed with git diff --check; no local test suite ran. Source links and SQL identities were checked against the repository. Remote metadata preflight succeeded without mutations.

### Historical private-repository capacity condition, 2026-10-15

The repository is private. An authorized read-only GitHub billing query found an existing Pro subscription and2934 Actions Linux minutes in October with reported net Actions amount zero. [GitHub's published Pro allowance](https://docs.github.com/en/billing/concepts/product-billing/github-actions) is3000 minutes/month. This is a snapshot, not a charge guarantee or permission to upgrade. Root must recheck before starting CI and permit at most one existing workflow pair only if at least60 included minutes remain: Flutter timeout25 plus Supabase timeout30, with reserve. Concurrent usage can change the available allowance. Do not dispatch additional runs, add paid runners, artifact destinations or schedules; hold CI if capacity cannot be verified. Test outcomes will be recorded only after observed execution.
