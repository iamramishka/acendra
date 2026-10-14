# Phase 8 missing-flow implementation

Owner: CODEX root. User decision: implement missing flows, retain operational gates; hosted CI only. Existing parallel authorization retained. Base origin/dev fe68c6b0047dc956b291fd43f6813d39cec56696. Open PR inventory empty.
Branch: codex/feat/csa-178-185-flow-integration. Worktree: C:/Users/ramis/.codex/worktrees/phase8-flow-integration/acendra.
Coordination: existing issue129 CODEX ownership; task-specific continuation, no duplicate claim.

| Worker | Exclusive scope |
|---|---|
| backend_acceptance | lib/features/checkout/** and corresponding tests |
| recovery_acceptance | lib/features/bank_transfer/**, lib/features/admin/** and corresponding tests |
| web_acceptance | lib/features/learning/** and corresponding tests |
| root | This board, integration evidence and necessary scoped router registration only after worker coordination |

Workers use new isolated managed worktrees. Record their own claims before edits; no shared dependencies, migrations, backend endpoint activation or other workers' files. Implement only supported trusted contracts. Preserve provider/inspection/independent-credit/media operational gates. No client success/redirect can grant paid access.
Dependencies: existing handler interfaces and merged schema; approved contracts govern sensitive behavior. Missing operational services remain explicit acceptance dependencies.
Verification: hosted Flutter/Supabase CI exact integrated head, focused independent reviews, no local test execution. Root commits/integrates/opens PR and merges after required checks and review, as authorized by owner. No production deployment. Status IN_PROGRESS; no unfinished operational task marked DONE.
