## Documentation review assignment — 2026-10-14

Owner: CODEX. Project owner requested review of CSA-178/179/180 and then
"update document". Status: IN_REVIEW (documentation reconciliation).
Base: dev `10c8b54d15c7e9b51e64a1db4aef4cf09c71e3c2`.
Branch: `docs/csa-178-180-review-update`.
Isolated clone: `C:/Users/ramis/Documents/Codex/2026-10-14/re/work/acendra-review`.
Scope: this assignment, TASKS.md's CSA-178/179/180 entries and
CSA-178-201-FINAL-EVIDENCE.md's dated review addendum. Temporary TASKS.md
ownership is limited to those three entries. No open PRs were found; issue129
retains the integrated acceptance scope and no listed active issue establishes
a conflicting documentation owner. This is a local documentation assignment,
not a new GitHub claim. Approval authority: project owner.
Verification: compare current implementation with docs/TESTING.md journeys,
record exact component results and their limits, review narrow diff and run
`git diff --check`. No operational task completion or deployment is authorized
by this documentation request.

## Historical integration assignment

Current assignment extension — 2026-10-14: project owner explicitly requested
parallel review of CSA-178/179/180/184/185/186/187/188/201 and merge with dev.
Three read-only reviewers cover journeys, finance/private files/uploads, and
web security/recovery. Root retains exclusive documentation edits and PR145
integration. Scope extends to those nine TASKS.md entries and the consolidated
dated review evidence. Runtime changes and endpoint activation remain outside
this documentation reconciliation. Merge authority: current project-owner
request, after review and exact-head CI pass.

Owner: CODEX root with three isolated workers; user explicitly requested remaining Phase8 tasks finished in parallel in one integration on 2026-10-13.
Status: IN_PROGRESS

Root scope extension: the actual HTTP journey reproducibly fails with42501 on
orders at transaction completion. CSA096's two deferred constraint functions are
SECURITY INVOKER and run after the trusted RPC definer context ends. Root exclusively
owns one new migration and its task-specific SQL regression to fix this required
financial acceptance defect. Existing applied migrations are preserved. No sibling
worker edits migrations; current open PR128 is marketplace-only. The fix retains
all financial invariants, empty search paths and revoked direct/client privileges;
it requires P0 review/CI before integration and does not enable production handlers.

Integration ownership update: workers committed their isolated test slices and
root integrated them. The backend worker's later diagnostic turn failed because
its model was at capacity; root now exclusively owns remaining journey diagnostics
in the integration tree. No previous worker worktree is modified. Known synthetic
provider/inspector boundaries and production gates remain intact.
Base: dev c89796f129d77ee1229a70108e9692a026f95f14
Integration branch: codex/test/csa-178-201-final-acceptance
Integration worktree: C:/Users/ramis/.codex/worktrees/csa-phase8-final-integration/acendra

Task allocation:
- Backend worker CSA178-180/182-186: new isolated codex/test/csa-178-186-final-acceptance, task-specific HTTP/database journey and permissions tests; ports61410..61419.
- Web worker CSA187-188: new isolated codex/test/csa-187-188-final-acceptance, malicious-text and synthetic log/header/compatibility verification tests; ports61510..61519.
- Recovery worker CSA200-201: new isolated codex/test/csa-200-201-final-acceptance, real disposable Supabase private object backup/restore/tombstone verification; ports61610..61619.
- Root: registry reconciliation CSA189/197 against closed Issues116/118, integration shared runner imports/test discovery, consolidated evidence and review.

Allowed scope: new task-specific tools/tests/evidence. Root exclusively owns TASKS.md and tool/supabase_smoke.mjs integration; no concurrent shared runner edits. Production handlers, migrations, dependencies, hosting/provider configuration and feature UI implementations are excluded unless separately coordinated. Primary marketplace branch and open PR128 remain outside scope.
Existing Issues117/119 retain their recovery acceptance scope; this issue coordinates authorized continuation and does not claim production readiness.

Requirements: TASKS Phase8 acceptance, SRS financial integrity and security/privacy/reliability requirements, SECURITY.md, docs/TESTING.md, approved bank/payment/media contracts.
Acceptance: current actual disposable Auth/SQL/Storage-integrated request journeys, effective role/isolation assertions, actual protected object byte restoration and deletion handling, malicious text/log tests, reviewed evidence with explicit deployment/provider boundaries, passing combined Flutter/Supabase checks and one reviewable PR.
Required tests: targeted failing tests for added critical scenarios, current disposable Supabase SQL/API/Storage verification, relevant Flutter malicious-text tests, formatting/analyzer/tests/release build; exact results recorded.
Dependencies: existing merged schema/handlers. Full UI/provider/bank/inspector/cloud operational acceptance requires actual available environments, which are not supplied; no synthetic substitute may be called real provider acceptance. Prior owner-delegated RPO24h/RTO4h/30day retention baseline applies without claiming implemented controls.
Approval authority: project owner/security/operations reviewer; no merge or production activation implied by implementation request. Completion evidence and PR will be added to local coordination record; tasks remain incomplete wherever an acceptance requirement is unverified.

## PR135 review-fix assignment — 2026-10-13

Project owner explicitly requested fixing findings, re-review and merge to dev.
Owner: CODEX root. Worktree: C:/Users/ramis/Downloads/Acendra/fix-pr135.
Branch: codex/fix/csa-135-review; delivery updates PR135's existing branch by fast-forward.
Scope: app_router.dart, router regression tests, and this task's review/evidence records.
Temporary shared router ownership is limited to removing references to missing screens
and displaying an explicit unavailable state using existing feedback components.
PR134 remains separately owned; its unmerged learning files are not modified or copied.
The dependency's content_text/content_image_url and thumbnail_url selections need
schema/contract review; enrollments itself exists. No new content contract is invented.
Base: PR135 head546a2b2 plus latest origin/dev merged without conflicts.
Verification: authenticated and unauthenticated direct-route tests, analyzer,
formatting, required Flutter/Supabase hosted CI and review of the final diff.
Merge authority: current project-owner request; production deployment and completion
of the seven operational acceptance gates are not authorized or implied.
Status: IN_PROGRESS. Existing task acceptance gaps remain recorded.

Scope extension: formatting-only fixes for 15 inherited PDF/video and bank test files identified by the mandatory whole-tree formatter; no APIs or behavior changed.
Scope extension: fix four inherited checkout test harness failures demonstrated in run38401609359, retaining validation and accessibility assertions.
