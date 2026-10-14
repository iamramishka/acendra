# Phase 8 hosted acceptance continuation — 2026-10-14

Owner: CODEX root. Authority: owner explicitly requested all Phase 8 Codex tasks completed in parallel, with no local tests. Status: IN_PROGRESS.
Existing issue #129 retains CODEX ownership. Live open PR inventory was empty at allocation. Base origin/dev e7a1cdc5bf4ea8b02864b3094be3c129876dc562.
Root reuses attached isolated sample worktree, branch codex/test/csa-129-sample-acceptance. Primary checkout and all existing unrelated worktrees are excluded.

| Worker | Task scope | Allowed files |
|---|---|---|
| backend_acceptance | CSA-178–180/184–186 | New task-specific acceptance tests/tools/docs in its own worktree |
| web_acceptance | CSA-187–188 | New task-specific web security tests/tools/docs in its own worktree |
| recovery_acceptance | CSA-200–201 | New task-specific recovery tests/tools/docs in its own worktree |
| root | CSA-182/183/189/197 evidence, integration and hosted CI | This board, consolidated evidence, bounded TASKS.md annotations and required workflow test wiring |

Temporary exclusive shared-file ownership: root holds only Phase 8 Codex TASKS.md annotations and any necessary acceptance wiring in existing CI workflows. Workers must coordinate before touching shared files. No schema, paid purchase, production deployment, financial state machine or endpoint activation is authorized by this allocation.
Dependencies: current merged implementation and hosted Linux GitHub Actions. Real provider, independent bank-credit, approved inspector, staging browser and managed recovery/logging acceptance require actual available environments.
Approval authority: project owner/security/finance/operations; no automatic merge or release authorization. Existing accepted DONE scope is retained; incomplete evidence remains explicit.
Verification: hosted Flutter and Supabase jobs on integrated PR revision; exact run links and results; independent diff review. No local runtime tests.

Integration review: root restored the CI workflow after GitHub rejected workflow updates for missing token scope. The new hosted scan test is discovered by the existing npm tool:test glob only in the Flutter baseline Linux job, after the release build. It verifies the pinned Gitleaks 8.30.1 archive against the official GitHub asset SHA256, suppresses scanner streams and prints only safe acceptance metadata. History coverage is limited to the existing checkout refs, potentially shallow; it is not claimed as a new complete-history audit. Recovery and web changes received read-only cross-worker review. No local tests were run for this continuation.
