# CSA-165 private image publication fix

Owner CODEX; authorized by project owner on 2026-10-13 (Asia/Colombo).
Issue #111; branch `codex/fix/csa-165-private-image-publication`.
Isolated worktree: `C:/Users/ramis/.codex/worktrees/csa-165-private-image-fix/acendra`.
Base merged PR107 on dev. Scope: additive migration034, publication SQL regression
fixture and this handoff. No concurrent ownership overlap found. Review/merge
authority: project owner, conditional on resolved findings and passing checks.

Finding: publication checked image MIME and nonempty paths but failed to recheck
the private bucket after media validation. Migration034 replaces only the existing
publication function, requiring Supabase provider, course-media private bucket and
canonical course/lesson/asset PNG or JPEG path. Existing authority, table locks,
PDF/video predicates, transactional audit and replay behavior are preserved.
Previously merged migration032 is unchanged. Production HTTP activation is unchanged.

TDD evidence: on a new isolated native PostgreSQL17 cluster at loopback55485,
actual baseline migrations were replayed with synthetic Supabase Auth/Storage.
The new regression failed before the fix with `public image bucket published`.
After migration034, the complete publication fixture passes: public/missing bucket,
wrong bucket/provider/path rejected and valid private image publication succeeds.
Fixtures use separate immutable media versions rather than rewriting validated
identities. All records roll back. This model is not live Supabase gateway evidence.
Related publication/upload HTTP tests:47 passed, zero failed/skipped. Diff whitespace
check passes. Hosted full migration/SQL/lint and Flutter checks remain required.

Status IN_REVIEW pending CI, review and conditional integration. No production
deployment, live data change, credential rotation or activation authorized.
