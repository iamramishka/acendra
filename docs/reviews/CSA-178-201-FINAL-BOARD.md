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
