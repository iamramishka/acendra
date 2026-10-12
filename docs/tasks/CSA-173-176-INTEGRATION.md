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

Remaining acceptance: hosted Supabase replay/lint/gateway/real Auth and Flutter CI, authorized security review, dependency PR107 acceptance, and separate production activation. Native PostgreSQL uses modeled Auth/Storage rather than live gateway. Native pgTAP foundation extension unavailable. Do not mark checklist DONE until review/CI/acceptance requirements are met. Task-specific records provide exact scope and known limitations.
