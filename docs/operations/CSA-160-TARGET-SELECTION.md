# CSA-160 — delegated target and operator selection

Date: 2026-10-18, Asia/Colombo. Owner: CODEX. Coordination:
[issue #160](https://github.com/iamramishka/acendra/issues/160).
Decision preparation: IN_REVIEW. Production operations: BLOCKED.

The project owner nominated `acendra.vercel.app`, then delegated the remaining
target and operator choices to CODEX. These selections resolve that request;
they do not establish infrastructure that is absent. Existing services only,
zero spending, environment isolation and release approval remain requirements.

## Selected configuration

| Purpose | Selection | Acceptance boundary |
| --- | --- | --- |
| Frontend hostname | `https://acendra.vercel.app`, existing Vercel project `acendra` | Keep the nominated hostname. Current Hobby eligibility prevents certifying a commercial launch. |
| Backend candidate | Existing Supabase `worrsweluwjmppwsygre` (`Acendra`, `ap-northeast-1`) | This is the only project returned by the available account. It remains staging; no isolated production backend is established. Do not silently promote or reset it. |
| Release operator and recovery lead | Project owner `iamramishka` | Select the known repository owner. This names the accountable principal; it does not prove Supabase/Vercel recovery access, MFA, availability or independent review. |
| Backup destination candidate | Owner workstation, `C:/Users/ramis/AppData/Local/Acendra/Recovery/archives` | Outside Git and the source providers' failure domain. A proposed path, not an existing verified encrypted store; no private export may use it before the checks below. |
| Isolated rehearsal target | Existing PostgreSQL 17 binaries at `C:/Program Files/PostgreSQL/17/bin`; disposable local cluster from `tool/csa200_recovery.py` | Synthetic rehearsal only, loopback port `61319` after reserving/rechecking it. The tool creates its own temporary directory. Never point it at a hosted project or existing data directory. |
| Production recovery target | No suitable existing target verified | The native rehearsal has Auth/Storage shims. It cannot establish managed Auth, private Storage or full service recovery. Do not label it a production restore destination. |

These choices use existing resources without creating a hosted service, purchasing
a plan or assuming access to an unknown backup device. No compliant commercial
production configuration is demonstrated by this inventory.

## Fresh metadata inventory

Read-only inspection on 2026-10-18, using existing account configuration in memory.
Secret values were not printed or included here. No user, payment or private
object rows were queried.

- Supabase projects API returned one project: `worrsweluwjmppwsygre`, `Acendra`,
  `ACTIVE_HEALTHY`, `ap-northeast-1`. This describes projects visible to the
  available account; it does not exclude infrastructure in another account.
- Its backup API returned zero listed backups and `pitr_enabled: false`.
- Auth site URL is `https://acendra.vercel.app`; no custom SMTP host is configured.
  Hosted password settings report minimum length **6**, with no required character
  groups. This differs from the owner's confirmed eight-character letter-and-number
  rule in [PR #186](https://github.com/iamramishka/acendra/pull/186). Align trusted
  Auth settings through a reviewed configuration change before treating that rule
  as enforced beyond the client. No Auth setting was changed.
- Vercel team `team_EtrnsK9YUu6vKAJ92xpWe88T` reports active **Hobby** billing.
  Project `prj_xWYJdw35hJGS6caNi8fiQdnxenh2` is `acendra`, with provider production
  branch `dev`. Its domains API returned only verified `acendra.vercel.app`.
- The workstation volume inventory showed only `C:` with a drive letter, with
  approximately 12 GB free. No separate mounted backup disk was observed.
  Encryption, archive capacity, key recovery and 30-day retention are unverified.
- PostgreSQL 17 `pg_ctl.exe` exists. No listener on port `61319` was observed at
  inspection; this is not a reservation or permission to interrupt another task.

[Vercel's Hobby documentation](https://vercel.com/docs/plans/hobby), checked
2026-10-18, restricts use to personal, noncommercial projects. The nominated
commercial course-selling launch remains held on this plan. Do not upgrade,
start a trial or substitute another service under the zero-spend scope.

[Supabase's backup documentation](https://supabase.com/docs/guides/platform/backups),
checked 2026-10-18, recommends offsite exports for free projects and states that
database backups exclude Storage object bytes. An empty backup listing does not
prove no internal provider recovery exists; it supplies no usable complete set.

## Concrete backup and restore preparation

Use the workstation archive path only after authenticated archive encryption,
owner-only access, sufficient space and independent decryption recovery have been
configured and tested. A directory name, Windows login or same-account key is not
evidence of recoverable encryption. Do not invent a key, upload a dump to this
public repository, reuse the application bucket or create a paid backup service.
No directory, encryption key, capture job or archive was created in this task.

The capture manifest must cover consistent database schema/roles/data and Auth
recovery, configuration references, actual private PDF/media/receipt bytes with
hashes, and the deletion ledger through cutover. Retain 30 days with authorized
deletions and holds respected. Validate all components before declaring a set
successful. Measure capacity and runtime before activating the proposed 12-hour
cadence; RPO remains at most 24 hours and complete-service RTO at most four hours.
The [backup specification](CSA-214-BACKUPS.md) defines the acceptance evidence.

For a synthetic rehearsal, use the existing disposable native drill documented in
the [recovery runbook](CSA-216-RECOVERY-RUNBOOK.md). Reserve the loopback port,
inspect its current isolation guards, then execute only synthetic fixtures. Do not
substitute real backup data into this harness. A real managed recovery exercise
requires a separately verified isolated full-stack destination, complete protected
set, deletion replay, permission tests and financial reconciliation. Neither a SQL
import nor this synthetic tool demonstrates production RPO/RTO.

## Remaining execution gates and handoff

Names are selected; there is no outstanding request for the owner to supply them
again. The unmet gates are capabilities and evidence:

1. An existing commercially eligible host for the nominated launch and an isolated
   production backend within the no-new-service/no-spend scope.
2. Verified archive encryption, independent key recovery, capacity, retention and
   complete capture; an isolated full-stack restore with measured RPO/RTO.
3. Verified operator access/MFA, an actual alternate responder, delivered monitoring
   alerts, SMTP and the existing finance/live-provider acceptance requirements.
4. Reviewed hosted Auth policy alignment, accepted source revision, migration and
   Edge caller ordering, rollback evidence and explicit production release approval.

Branch: `codex/fix/csa-160-issue-reconciliation`. Worktree:
`C:/Users/ramis/Downloads/Acendra/pr165-review-20261017`. Base:
`269f0ddfd239ba40220f9e8615a79640fb6040f1`. Scope is this record and links from the
existing hosting/backup/recovery/readiness documents. Feature PRs #185/#186 and
their source checkouts remain outside this scope. No shared runtime, migration,
financial contract, workflow, secret or provider setting changed.

Verification: fresh allowlisted provider metadata, local tool/volume/port inspection,
Markdown target checks and `git diff --check`. No local test suite, recovery drill,
backup transfer, production deployment or notification was executed. Prior test
results in the linked runbooks remain historical. Hosted CI, if executed for this
documentation PR, validates source and cannot establish operational readiness.
