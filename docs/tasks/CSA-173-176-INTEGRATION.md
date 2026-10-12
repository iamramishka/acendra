# CSA-173–176 parallel admin security integration

Owner CODEX root; coordination issue #108; authorized user request 2026-10-12 Asia/Colombo. Status IN_REVIEW. Approval authority project owner/security reviewer. No merge or production activation inferred.

Base: completed admin implementation handoff2e6798a, refreshed to e187433 from dependency PR107 before combining workers. PR107/issue106 remain separate review dependencies. Existing dirty accessibility/marketplace checkout untouched.

| Task | Owner | Isolated worktree under C:/Users/ramis/.codex/worktrees | Branch | Writable scope |
| --- | --- | --- | --- | --- |
| CSA-173 | CODEX permissions worker | csa-173-admin-permissions/acendra | codex/security/csa-173-admin-permissions | New permission SQL fixture and task inventory only |
| CSA-174 | CODEX audit worker | csa-174-audit/acendra | codex/security/csa-174-audit | New cross-ledger SQL fixture and audit inventory only |
| CSA-175 | CODEX root | csa-175-roles/acendra | codex/security/csa-175-roles | Role endpoint, role HTTP/SQL tests, task handoff |
| CSA-176 | CODEX denial worker | csa-176-admin-denials/acendra | codex/test/csa-176-admin-denials | New cross-endpoint HTTP/SQL denial fixtures, task handoff |
| Integration | CODEX root | csa-173-176-integration/acendra | codex/security/csa-173-176-admin-integration | Shared test discovery, task pointers, test timing repair and safe diagnostics |

Each worker had distinct PostgreSQL cluster on loopback ports55473–55476. No mutable database shared while workers ran. Root integration runs combined synthetic SQL sequentially on root's55475 cluster. No new migrations: existing grants/roles/audit invariants reviewed and preserved. Worker commits preserved by cherry-pick after reported completion; no incomplete code silently copied.

Acceptance: current backend authority for all implemented admin HTTP/RPC/direct-write surfaces, append-only attributed atomic audits, trusted current-session role changes with self/replay protections, and real negative API/database calls without side effects. Approved CSA003 roles and SRS policy applied; no new financial policy. Inventories distinguish available operations from planned absent APIs. Audit reader, course staff/price/editor operations and bank configuration are absent; no unrestricted reader or fake capability added. Existing disabled admin production entries stay disabled.

Implementation: permission matrix13 restricted RPCs; audit integrity across role/course/media/publication/generic ledgers; bounded role request/Auth/RPC responses, credential redirect rejection, authenticated object checks and strict filtered role result; denial matrix10 endpoint variants and13 RPCs. Repository policy and tests retain current MFA/session/role/assignment checks. No UI or schema change.

Shared integration adjustments: GitHub OAuth refuses workflow-file updates without workflow scope. Existing workflow files are preserved; dispatch existing CI workflows against the stacked branch instead. Tool runner already discovers new tests via tool/*.test.mjs and role wildcard. SQL diagnostics identify only repository-known test filenames/line numbers and bounded literal assertion labels, never arbitrary database values. Existing entitlement fixture used100ms expiry, which failed during real operations on Windows; preserve every assertion with5second setup allowance and wait until actual expiry. No production time or entitlement logic changed.

Worker evidence:173 22 SQL assertions and29 existing SQL suites;174 new suite plus7 existing audit suites, identified timing fixture failure fixed by root;175 17 HTTP tests plus10 new and55 existing SQL assertions;176 130 HTTP tests and91 actual denied RPC calls plus unchanged public/app_private row snapshots. Actual root combined counts and CI evidence appended below.

Remaining acceptance: authorized security review, dependency PR107 acceptance, and separate production activation. Hosted Supabase and Flutter verification passed; exact evidence follows. Native PostgreSQL uses modeled Auth/Storage rather than live gateway. Native pgTAP foundation extension unavailable. Do not mark checklist DONE until review/CI/acceptance requirements are met. Task-specific records provide exact scope and known limitations.

## Integrated evidence

Root combined suite:646 Node tests discovered,640 passed/6 intentional opt-in runtime skips (five PostgreSQL concurrency suites and one Linux watermark supervisor test);32 non-foundation SQL files passed on PostgreSQL17 root55475 after replay. Existing CSA116 timed test passes with all assertions retained. Native foundation pgTAP unavailable; real Supabase CI provides this check. Supabase's modeled default storage grants/RLS were applied only to the disposable bootstrap, not repo policies. Individual task records retain original worker evidence.

Dependency advanced to ddd82f9 while verification ran (publication TAP output and safe diagnostics). Root integrated that completed committed fix; the sole tool/local_supabase conflict was reviewed and resolved using a generalized allowlist of actual repository filenames, preserving both scopes' diagnostic goals. New CSA174 DO assertions now emit a TAP plan/success result for real Supabase pg_prove; SQL recheck passed and9 tooling tests passed after reconciliation.

Draft PR110: https://github.com/iamramishka/acendra/pull/110. Existing workflows dispatched on task branch because OAuth cannot push workflow-file changes. No workflow files modified. Original dispatched runs precede the final TAP/dependency fix; fresh final revision runs required. Hosted results will be recorded against exact verified revision.

Read-only peer review found session fault cases could be masked by absent staff roles. Root fixed CSA176 to retain active super-admin authority throughout session faults and revoke it only for the final role case;13 valid-session positive authorization probes must either pass (rolled back) or reach a declared non-authorization business error. Invalid/expired/deleted sessions then fail42501 with unchanged state. Stronger SQL suite passed; hosted CI rerun against corrected revision. No independent human approval claimed.

Hosted Supabase run38284185506 exposed an AAL enum fixture mismatch in CSA173 (native initial model used text). Fixed fixture via jsonb_populate_record(null::auth.sessions) to resolve actual column types; all4 new SQL suites pass after native model upgraded to auth.aal_level enum. Safe diagnostics additionally report source-controlled literal SQL labels, excluding arbitrary server values. Initial hosted failures remain recorded until corrected revision is verified.

## Hosted verification and final handoff

Verified implementation revision8be652e8db350fdf2ae86e9da9c68963809ea7fb:
- Supabase foundations SUCCESS: https://github.com/iamramishka/acendra/actions/runs/38285136301. Pinned actual Supabase replay and SQL tests (including foundation pgTAP and four task suites), opt-in concurrent database verification, strict database lint, live isolation/API smoke, and real MFA/trusted-role HTTP tests passed. Task-owned stacks cleaned up.
- Flutter baseline SUCCESS: https://github.com/iamramishka/acendra/actions/runs/38285141785. Locked dependencies, Dart formatting, analyzer, Flutter tests, release web build and tooling checks passed.
- Latest native actual-enum model: all32 non-foundation SQL suites passed. Native loopback cluster stopped; all four worker clusters stopped. Worktrees preserved for review.

After this verified revision only documentation evidence changes are made. Early failed/cancelled runs are superseded by the two successful exact-revision runs above. The AAL enum error was real; other reported SQL locations included diagnostic context/notices and were not proof of failures. Real Supabase audit tests now pass.

PR110 is stacked on PR107; dependency changes through51f3596 incorporated, including strict dashboard JSON lint fix. No merge, deployment, policy approval, real role mutation or production activation performed. TASKS checkboxes remain unchecked with IN_REVIEW evidence links. All4 requested implementation/review/test scopes complete for available operations; absent planned APIs/audit-reader remain explicit in inventories. Required next action: authorized security review and acceptance of dependency and this PR. Root addresses review findings before approved integration. Temporary implementation ownership stays reserved through reviewed stage; no other agent's active files changed.
