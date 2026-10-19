# CSA-268 — trusted course management

Owner: CODEX. Status: IN_PROGRESS. Coordination: GitHub issue #199.
Authority: project owner requested fixing course save/delete, publication,
curriculum and lesson editing on 2026-10-20 (Asia/Colombo).
Base: dev `d46ae1c`. Root branch `fix/csa-268-course-management`.
Root worktree: `C:/Users/ramis/Downloads/Acendra/acendra-codex-csa268`.

Root owns the additive CSA268 authoring migration, admin-course-management Edge
function/tests, publication entrypoint release integration, function/test
registration, contract, SQL tests and final integration. Frontend worker owns
admin course entities/repository/providers/editors/curriculum/list and tests in
its separate `acendra-csa268-flutter` worktree, plus the bounded lesson-editor
section query parameter in app_router.dart. Shared migration/config/package/router
ownership is temporary and restricted to these changes. No overlapping open task
was found; #193 artwork operations, #160 production operations and #198 router
tests remain independent. Primary-checkout edits and historical worktrees are
excluded. Each implementation surface has one owner.

Dependencies: CSA089 course creation, CSA165 publication/readiness, CSA164
authorized directories and CSA267 media. Preserve current role/session/MFA and
course-assignment enforcement, private content, exact money, immutable audit,
idempotency, optimistic revisions and existing entitlements. Permanent deletion
policy is pending owner clarification; independent actions can proceed.

Acceptance: real persistent create/edit; metadata and publication saved through
trusted APIs; authorized curriculum/lesson reads, creates, edits, ordering and
removal; no arbitrary first-section reassignment, placeholder IDs or rounded
prices; actionable safe errors and session-safe refresh. Draft-only curriculum
edits preserve publication validation. Source implementation does not activate
hosted services or approve production deployment.

Required checks: RED/GREEN repository/UI and handler regressions, disposable SQL
authorization/concurrency/audit/persistence tests, formatting/analyzer, affected
Flutter/Node suites and release build; self-review and final scope checks.
Approval authority: project owner. Required CI/review/merge remain distinct from
local implementation and hosted activation. No unrelated feature changes.

## Backend implementation and verification

- Added service-only, role/session/assignment-checked metadata authoring and
  safe curriculum reads with immutable mutation audit, exact LKR minor units,
  actor/request idempotency and original microsecond revisions. No direct client
  table grants, financial/entitlement mutations or private body/path exposure.
- Section/lesson parent checks, draft-only curriculum edits, safe reordering and
  enrollment/progress/media retention are enforced in PostgreSQL. Existing
  enrolled curriculum cannot be hidden by switching published markers off after
  course unpublication. Existing publication authority/readiness RPC is retained.
- Explicit origin-validated server opt-ins replace the publication source-only
  transport disable and guard the new endpoint; defaults remain unavailable.
  No hosted configuration or activation was performed.
- Initial new endpoint/RPC regressions failed because those implementations did
  not exist. Focused handlers now pass **73 tests** (51 new authoring, 22 existing
  publication). Full `npm run tool:test -- --test-concurrency=1`: **918 passed,
  12 conditional skips**, zero failures/cancellations, exit 0.
- Final clean disposable native PostgreSQL 17 replay: **41 migrations and 43 SQL
  suites passed**. Two pgTAP-only suites (`000_foundation`, `csa179_bank_reads`)
  were skipped because native pgTAP is unavailable. Existing `supabase/seed.sql`
  replayed twice in a separate disposable clone without any seed-file change.
- The first reorder design reproduced a seed incompatibility with deferrable
  unique constraints. Final design preserves the original immediate uniqueness
  and uses a free temporary range plus two bulk updates in one transaction.
  Regression includes sparse positions at INT_MAX, full-permutation validation
  and atomic swaps. Independent read-only review found no remaining issue in
  arithmetic, lock scope or transactional ordering.
- Purchased-visibility regression first failed with `Purchased section hidden`;
  section/lesson marker guards made it pass. Independent read-only review also
  identified and rechecked frontend session-refresh/reviewed-revision fixes.
  AI review does not replace maintainer acceptance.
- Final actual two-session authoring tests: **3 passed** (parent plus two races),
  proving one same-revision update commits and a waiting write loses authority
  after assignment revocation. CI database verification now includes this suite.
- Native Auth/Storage schemas, roles and bucket/object RLS/grants are synthetic
  shims, not managed Supabase runtime evidence. Initial host memory failures were
  mitigated with task-local 8 MiB shared buffers and serial checks. The task-owned
  server is stopped; no system memory settings or other processes were changed.
- Markdown links and `git diff --check` pass. Flutter integration, current
  combined checks and course-deletion decision remain outstanding below.

## Outstanding owner decision

The requested course Delete action still awaits clarification of archive versus
permanent deletion of unused drafts. SECURITY.md explicitly leaves deletion and
retention policy open, and course/audit/financial references must survive. No
physical course/audit deletion or inferred archival behavior is implemented.
Independent save/publication/curriculum work is completed for integration; task
status remains IN_PROGRESS until the decision and remaining checks are resolved.
