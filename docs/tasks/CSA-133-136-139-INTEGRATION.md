# CSA-133 / CSA-136 / CSA-139 parallel integration

Owner CODEX root; issue #93; user authorized these three tasks in parallel.
Status IN_PROGRESS. Branch codex/feat/csa-133-136-139-integration.
Worktree C:/Users/ramis/.codex/worktrees/csa-133-136-139-integration/acendra.
Base e4d627b, unmerged CSA-127 PR #92. Dependency remains explicit; no approval
or merge of that prerequisite is inferred from implementation authorization.

Worker ownership:
- CSA-133: migration022, progress SQL tests and progress task/contract records.
- CSA-136: migration023, authorize-video handler/signer/tests and task/contracts.
- CSA-139: migration024, PDF Storage tests/smoke and task/contracts.

Root exclusively owns test discovery, shared smoke wiring, integration records
and the three TASKS.md entries. Existing migrations and financial invariants are
unchanged. New objects are independent; migration ordering is serialized here.

Acceptance: current-session owned entitled lesson progress; private attested Mux
signed-playback binding and short-lived signature; private PDF bucket denying
direct student access. Root verifies combined ordered migrations, negative SQL
tests, cryptographic token tests, pinned real Storage lifecycle, strict lint,
existing regressions and Flutter CI. Worker assertions alone are not integrated
verification. No production configuration, provider purchase or enablement.

Protected PDF entitlement/proxy/watermark delivery remain CSA-140/141/148;
video provider provisioning and playback PoC remain retained release gates.

## Integrated candidate

Progress commits4a23315/2b4e7bf/ef317a9; PDF storage a17107b; video fcb171f/
6b691fd/cecda45; shared smoke4e3f805; discovery57b0342; archived access correction
b31eda0. Worker source commits preserved in their isolated branches.

Fresh full Node suite:324 passed, zero failed, four locally gated DB suites.
Root review corrected video's catalog-publication requirement to preserve existing
entitled archived/draft course access; lesson/section publication still required.
Full ordered migration021–024, new SQL tests and real pinned Storage lifecycle
are running on hosted disposable Supabase. Runtime passes will be recorded only
when checks finish. Intermediate runs cancelled when superseded by final head.

PR #102 is stacked on CSA-127 PR #92. Tasks remain IN_REVIEW pending combined
runtime verification and acceptance. No dev merge or production enablement.