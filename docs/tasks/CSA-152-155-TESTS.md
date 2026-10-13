# CSA-152–155 parallel test integration

Owner CODEX root, issue101. Isolated codex/test/csa-152-155-learning-security
managed worktree csa-152-155-tests; base merged origin/dev9cd6c39.
Workers own separate test files/docs only; no active implementation edits.
Scope root new csa153 SQL, task handoff and TASKS four IDs only.

| Task | Evidence | Remaining integration |
| --- | --- | --- |
| CSA152 |34 actual PDF handler+authorizer adapter tests pass against immutable PDF snapshot ab8441b; external Auth/RPC/Storage controlled by tests | Real resolver/Storage transport with approved delivery dependency |
| CSA153 |9 real SQL assertions pass: next-request denial with same bearer after revocation, historical grant replay no revival, independent course preservation, course/account restrictions | Full PDF/video dependent request integration |
| CSA154 |23 actual video handler tests pass on immutable phase6 snapshot cecda45; real csa136 SQL scope/publication/expiry/revocation scenario also passes | Provider/runtime acceptance and merged dependency |
| CSA155 | Worker tests actual SQL persistence in disposable root database; explicit opt-in runner | Final integrated real Supabase acceptance |

Native PostgreSQL16 isolated55518 database uses synthetic Auth/Storage schema
shims and committed ordered migrations001–024 from phase6cecda45. Fixtures roll
back. Committed source exported with git archive into ignored build paths; no
pending source copied. Dependency snapshots used only for verification, not
silently merged into test branch. On merged dev absent PDF/video targets generate
explicit named skips, not passing assertions; progress native runner opt-in.
Production delivery remains disabled and no deployed provider/queue readiness
is claimed. Status IN_REVIEW pending dependency integration/CI/authorized review.
No merge/deployment authorized. Project owner controls acceptance.CSA155 final commit0eaacb2 integrated: actual native RPC persistence runner passes1 test containing14 named SQL assertion groups,0 skips. Text/image/PDF/video save-read, retry/clearing/bounds, peer/session isolation, revocation denial and unchanged history verified. Dev absence remains explicit opt-in/dependency skip. New production code not copied.

## PR #103 review and dev integration — 2026-10-12

Project owner authorized review, fixes and merge into dev. CODEX retains issue #101 ownership in the isolated csa-152-155-tests worktree; writable scope is these regression tests, their handoff documents and TASKS.md entries CSA-152–155.

Integrated current origin/dev, including accepted progress/video/PDF dependencies. Fixed two review findings: missing PDF/video implementation now fails imports rather than skipping coverage; CSA-155 SQL now lives in supabase/tests/database/csa155_progress.test.sql and runs in the regular disposable Supabase database CI suite. The optional native runner reads that same canonical SQL.

Local verification: 57 PDF/video request tests passed, zero skips. Full tool suite: 483 passed, 6 optional runtime/database suites skipped; those skips do not establish database acceptance. Fresh Flutter and Supabase CI on the integrated PR head remain the merge gate. Adapter tests deliberately control Auth/RPC/Storage boundaries; real entitlement/PDF/video SQL and Storage suites verify separate trusted boundaries. No hosted provider or production readiness is claimed.
