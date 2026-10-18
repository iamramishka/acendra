# AUDIT.md
# Acedra - AI Engineering Governance Audit

Document ID: CSA-AUDIT-001
Audit date: 2026-10-18
Auditor: CLAUDE (AI agent, self-run audit - not an independent human audit)
Audited ref: `dev` @ `f761369` (origin/dev)
Branch: `docs/csa-audit-001-ai-governance-audit`
Worktree: `../acendra-claude-audit-001`
Status: IN_REVIEW - findings require project owner acceptance

Local assignment record (AGENTS.md section 8 documentation fallback):
no GitHub Issue exists for this audit. Owner = CLAUDE, scope = `AUDIT.md`
and a bounded section 18 addition to `CLAUDE.md`. Approval authority = project
owner. This is a local record, not a GitHub claim. No code, workflow,
repository setting or production system was changed by this audit.

---

## 1. How to read this document

- `- [x]` = verified as in place, with evidence cited.
- `- [ ]` = missing, failing, or not verified. Each open item links to a
  finding ID.
- Findings are named `Audit-NNN`. Each has a **severity** and a
  **quality score**:

| Severity | Meaning |
|----------|---------|
| P0 | Production, financial or security exposure now. Fix before next deploy. |
| P1 | Control missing that the project rules require. Fix this phase. |
| P2 | Process weakness that lowers quality or accountability. |
| P3 | Hygiene. Fix when touching the area. |

Quality score = how well the control meets the project's own rules today,
0 (absent) to 10 (fully met and enforced).

Honesty limits of this audit:

- No dedicated AI security scanner or AI eval agent was run. None is
  installed in this repository or its CI (see Audit-009).
- `supabase test db` was **not** run locally: Docker is unavailable on this
  machine. Database evidence comes from the `Supabase foundations` CI runs.
- Production was checked with two read-only HTTP requests only.
- GitHub settings were read through the `gh` API with the owner's account.

---

## 2. Scorecard

| # | Area | Score /10 | Main findings |
|---|------|-----------|---------------|
| A | AI verification | 6 | Audit-001, Audit-014 |
| B | Standards | 7 | Audit-006, Audit-012 |
| C | Audits (trail and records) | 5 | Audit-008, Audit-010, Audit-013 |
| D | Comprehension gates | 2 | Audit-003, Audit-007 |
| E | Speed + quality + accountability | 3 | Audit-001, Audit-002, Audit-008, Audit-011 |
| F | AI security scanning + AI eval agents | 3 | Audit-004, Audit-005, Audit-009 |
| G | AI compliance audit (AGENTS.md rules) | 4 | Audit-001, Audit-002, Audit-003, Audit-013 |
| | **Overall** | **4.3** | 3 P0, 4 P1, 5 P2, 2 P3 |

Summary: the code-level controls are strong. CI pins actions, the Supabase
tests use a real database, and admin financial screens fail closed. The
process controls around that code are weak. Code reaches production without
passing CI, without a PR, and without a second reviewer. The rules in
AGENTS.md are written but not enforced by the repository.

---

## 3. Findings register

### Audit-001 - Production deploy bypasses the CI gate
Severity: **P0** · Score: 1/10 · Area: A, E, G

Evidence:
- `.github/workflows/deploy-production.yml` runs on every push to `dev`
  whose commit message contains `deploy`. It does not depend on
  `Flutter baseline`.
- Commit `1c38515` (`feat(auth): ... — deploy`): `Flutter baseline`
  = **failure**, `Deploy to Production` = **success**. Code that failed CI
  was deployed to production.
- The deploy job runs its own weaker checks: no `dart format` check,
  `flutter analyze --no-fatal-infos`, and no `--enforce-lockfile`.

Gap: AGENTS.md sections 19, 40 and 53 require passing CI before merge or
release. CLAUDE.md requires no deploy without authorization.

Fix:
- [ ] Trigger deploy with `workflow_run` on a successful `Flutter baseline`
      for `dev`, or `workflow_dispatch` only. Remove the commit-message
      keyword trigger.
- [ ] Use a GitHub `environment: production` with the owner as a required
      reviewer.
- [ ] Deploy the exact commit that CI tested.

### Audit-002 - `dev` is unprotected and receives direct pushes
Severity: **P0** · Score: 1/10 · Area: E, G

Evidence:
- `gh api repos/iamramishka/acendra/branches/dev/protection` returns
  `Branch not protected`. `dev` is the default branch, and no `main`
  branch exists.
- Non-merge commits pushed straight to `dev` on 2026-10-17 include
  `1c38515`, `a4952af`, `f975598`, `ec23fd2`, `ba0b9df` and `f761369`. Two
  of them, `a4952af` and `1c38515`, failed CI.

Gap: CLAUDE.md section 10 says "Do not push directly to main", and AGENTS.md
section 13 forbids direct commits to the default branch. The effective
default branch is `dev`.

Fix:
- [ ] Add a ruleset on `dev`: require a PR, require the `Format, analyze,
      test and build` status check, block force-push and deletion.
- [ ] Record in CLAUDE.md and AGENTS.md that `dev` is the protected
      integration branch, since `main` does not exist.

### Audit-003 - No independent review (maker-checker not enforced)
Severity: **P1** · Score: 2/10 · Area: D, G

Evidence:
- 27 of the last 30 merged PRs have **0 reviews**. All 30 were authored and
  merged by the same account (`iamramishka`). This includes financial and
  security PRs such as #133 (finance review UI), #157 (protected media)
  and #162 (admin UI, +10,238 lines).

Gap: AGENTS.md sections 19, 30, 43 and 53 require authorized review for
financial and authorization changes. CLAUDE.md section 10 forbids merging
your own PR without explicit instruction.

Fix:
- [ ] Adopt the maker-checker mode for P0-sensitive areas
      (CLAUDE.md section 18).
- [ ] Require one PR review comment in Evidence, Gap, Criteria format
      before merge. Record who checked: the other agent, or the owner.
- [ ] Limitation: GitHub cannot require approval from the PR author's own
      account. With one human account, the owner's approval must be a
      recorded review comment.

### Audit-004 - Production is served over plain HTTP with no security headers
Severity: **P0** · Score: 1/10 · Area: F

Evidence (2026-10-18, two read-only requests):
- `http://3.25.99.105/` returns `200` with no redirect to HTTPS.
- `https://3-25-99-105.sslip.io/`, which the deploy summary advertises,
  fails to connect.
- The response has no `Strict-Transport-Security`,
  `Content-Security-Policy` or `X-Frame-Options` header. It discloses
  `Server: nginx/1.28.3 (Ubuntu)`.
- Commit `ae27232`: "smoke test uses http not https - nginx is http only".

Gap: the app handles sign-in and Supabase sessions. Over HTTP, a network
attacker can modify the delivered JavaScript and steal sessions. This
breaks SECURITY.md transport expectations. The deploy summary claims an
HTTPS URL that does not work.

Fix:
- [ ] Issue a TLS certificate, redirect HTTP to HTTPS, and add HSTS.
- [ ] Add CSP, `X-Frame-Options`/`frame-ancestors`, and
      `X-Content-Type-Options`. Set `server_tokens off`.
- [ ] Make the smoke test check HTTPS and the required headers.

### Audit-005 - Secret scanning is off on a public repository
Severity: **P1** · Score: 3/10 · Area: F

Evidence:
- Repository visibility is `PUBLIC`.
- `secret_scanning`, `secret_scanning_push_protection` and
  `secret_scanning_non_provider_patterns` are all `disabled`.
- `.gitleaks.toml` exists, and commit `6b45730` is titled "fix(ci): add
  gitleaks allowlist", but **no workflow on `dev` runs gitleaks**. The
  config gives false assurance.
- The deploy job's only scan greps `build/web` for `service_role`.

Good:
- [x] `.env` is git-ignored. Only `.env.example` is tracked.
- [x] No `service_role` reference exists in `lib/`.

Fix:
- [ ] Enable GitHub secret scanning and push protection. Both are free for
      public repositories.
- [ ] Add a pinned gitleaks job to `Flutter baseline`, or delete
      `.gitleaks.toml` so it does not imply coverage.

### Audit-006 - Deploy workflow is below the project's own CI standard
Severity: **P1** · Score: 4/10 · Area: B, F

Evidence, comparing `deploy-production.yml` with `flutter-ci.yml`:
- No `permissions:` block, so the job gets the default token scope.
  `flutter-ci.yml` sets `contents: read`.
- Actions are pinned by tag (`checkout@v4`, `flutter-action@v2`), not by
  commit SHA. `supabase-foundations.yml` is also tag-pinned.
- The Flutter version floats on `stable`, while CI pins `3.44.0`. The
  deployed build is not the tested toolchain.
- It uses `StrictHostKeyChecking=no` even after `ssh-keyscan`.
- Server IP and user names are written in comments in a public repository.
- `supabase-foundations.yml` still triggers on the stale branch
  `security/csa-060-profile-rls`.

Fix:
- [ ] Add `permissions: contents: read`.
- [ ] SHA-pin every action, and pin Flutter to the CI version.
- [ ] Pin the host key (stored as a secret) and remove
      `StrictHostKeyChecking=no`.
- [ ] Move host details out of comments.

### Audit-007 - No comprehension gate on PRs
Severity: **P1** · Score: 2/10 · Area: D

Evidence:
- There is no `.github/pull_request_template.md` and no `CODEOWNERS`.
- In a sample of 8 recent PRs (#162–#174): **0/8** contain a Task ID,
  **3/8** list tests executed, and **1/8** has a security section.
  AGENTS.md section 42 requires all three.
- Oversized PRs: #162 (+10,238 lines, 42 files) and #165 (+3,051 lines,
  67 files). AGENTS.md section 2 requires small reviewable changes.

Gap: nobody can show that a human understood a change before it merged.

Fix:
- [ ] Add a PR template with Task ID, Evidence, Gap, Criteria, Security
      and "What a reviewer must understand".
- [ ] Set a size guideline: split PRs over about 800 changed lines unless
      they are generated code.
- [ ] Add a comprehension check: for P0 areas, the owner writes a short
      "why this is safe" note before merging.

### Audit-008 - Untraceable catch-all commits
Severity: **P2** · Score: 4/10 · Area: C, E

Evidence:
- `ba0b9df` "commit pending design system and feature updates".
- `f975598` "deploy bug fixes (issues 001-006)", which refers to
  `finderror.md`, not to GitHub Issues.
- Repeated `redeploy` commits (`ec23fd2`, `a2cb17b`, `6b67129`,
  `524426a`) are used as deploy triggers.

Fix:
- [ ] Use one CSA ID per commit or PR, and track bugs as GitHub Issues
      instead of `finderror.md`.
- [ ] Use a manual deploy trigger (Audit-001) so no empty commits are
      needed.

### Audit-009 - No AI eval agent, SAST or dependency-vulnerability gate in CI
Severity: **P2** · Score: 3/10 · Area: F

Evidence:
- No CodeQL or other SAST workflow exists.
- CI runs `npm ci --no-audit`. No `dart pub` advisory check or
  `npm audit` gate exists.
- No automated AI review or eval step runs on PRs. AI review happens only
  when an agent is asked in chat, and the result is not recorded on the PR
  (see Audit-003).

Good:
- [x] Dependabot version updates exist for pub, npm and actions, without
      auto-merge. Dependabot security updates are enabled.
- [x] A one-time dependency review was recorded (CSA-189,
      `docs/tasks/CSA-189.md`).

Fix:
- [ ] Add CodeQL for JavaScript, which covers the Edge Functions and
      tooling.
- [ ] Add an `npm audit --audit-level=high` step and a scheduled
      dependency advisory check.
- [ ] Define an AI review step: the checker agent posts Evidence, Gap,
      Criteria on the PR. It counts as a review aid, never as an approval.

### Audit-010 - Governance documents disagree on their own status
Severity: **P2** · Score: 5/10 · Area: C

Evidence:
- AGENTS.md is marked "Approved Documentation Baseline".
- TASKS.md and CONTRIBUTING.md are marked "Proposed - Pending Approval".
- CLAUDE.md is marked "Proposed".
- CLAUDE.md jumped from section 17 to section 19. This audit fills
  section 18 with the operating modes and PR review format.

Fix:
- [ ] The owner confirms which documents are binding and updates their
      status lines.

### Audit-011 - Worktree sprawl
Severity: **P2** · Score: 4/10 · Area: E

Evidence:
- `git worktree list` shows about 170 worktrees. Most are marked
  `prunable` (the directory is gone but the metadata remains), and about
  20 have detached `review-*` heads.

Gap: this makes isolation harder to verify (AGENTS.md section 12), and
agents risk resuming stale trees.

Fix:
- [ ] After owner review, run `git worktree prune` and remove merged
      worktrees. This audit did not do it, because it is destructive to
      other agents' records.

### Audit-012 - Fake financial records class lives in production code
Severity: **P3** · Score: 7/10 · Area: B

Evidence:
- `lib/features/admin/data/repositories/admin_payment_repository.dart:60`
  defines `StubAdminPaymentRepository`, which returns in-memory payment
  records.
- It is not wired in: `adminPaymentRepositoryProvider` returns
  `UnavailableAdminPaymentRepository` (verified), and the regression test
  "Payments displays unavailable rather than demo identities" covers this.

Gap: a one-line provider change would show fake payments as real ones,
which AGENTS.md sections 17 and 37 prohibit.

Fix:
- [ ] Move `StubAdminPaymentRepository` to `test/`.

### Audit-013 - DONE status lacks recorded review evidence
Severity: **P2** · Score: 5/10 · Area: C, G

Evidence:
- TASKS.md has 166 tasks checked `[x]` and 98 open.
- The Definition of Done (AGENTS.md section 52) requires "Required
  reviews are completed".
- Given Audit-003, most DONE entries have no recorded independent review.
  Some entries are explicitly honest about this, for example CSA-184,
  which states that the acceptance source is the owner's manual result.
- Commit `422362f` "document all completed Claude tasks across all phases"
  marked many tasks DONE in a single commit.

Fix:
- [ ] Keep tasks `IN_REVIEW` until the required reviews and acceptance
      criteria are complete. Record the review evidence per task before
      marking it `DONE`, as required by AGENTS.md sections 7 and 52.

### Audit-014 - Local test result differs from CI
Severity: **P3** · Score: 6/10 · Area: A

Evidence:
- `flutter test` locally on Windows fails one test:
  `test/core/widgets/cards/course_thumbnail_test.dart:154`
  "successful network image replaces loading cover". The "Loading cover
  image" text is still present.
- The same commit passes `Flutter baseline` on Linux CI.

Gap: the test is platform- or timing-dependent. "Passes on my machine"
and "passes in CI" are not the same claim.

Fix:
- [ ] Root-cause it with the systematic-debugging skill in a separate fix
      task. This audit did not change the test.

---

## 4. Area checklists

### A. AI verification
- [x] `dart format --output=none --set-exit-if-changed lib test`: 272 files,
      0 changed (local, `f761369`).
- [x] `flutter analyze --no-pub`: No issues found (local).
- [ ] `flutter test --no-pub` (local, Windows): 730 passed, 1 failed
      (Audit-014).
- [x] `npm run tool:test`: 787 tests, 777 pass, 0 fail, 10 skipped (local).
      The skipped tests need a real PostgreSQL instance or a hosted target.
      In CI, `db:test` runs the financial concurrency tests with
      `ACENDRA_FINANCIAL_CONCURRENCY=1`.
- [x] `Supabase foundations` CI: last 5 runs had 4 successes and 1
      cancelled, with a real disposable database, RLS lint and smoke tests.
- [ ] `supabase test db` run locally: not run, Docker unavailable.
- [x] `Flutter baseline` CI on `dev` tip `f761369`: success.
- [ ] Every production deploy is preceded by green CI (Audit-001).
- [ ] Verification evidence is attached to every PR (Audit-007).

### B. Standards
- [x] Feature-first structure: `lib/features/<feature>/` across 10
      features, plus `lib/app` and `lib/core`.
- [x] Every feature has tests (smallest: `my_courses`, 1 file).
- [x] Strict analyzer: `strict-casts` and `strict-raw-types`, plus extra
      lint rules.
- [x] 12 ADRs in `docs/decisions/` and 17 API contracts in
      `docs/contracts/`.
- [x] Logging is debug-only (`lib/core/utils/logger.dart`).
- [x] `flutter-ci.yml` SHA-pins actions, uses `contents: read` and
      `persist-credentials: false`, and enforces the lockfile.
- [ ] `deploy-production.yml` and `supabase-foundations.yml` meet the same
      standard (Audit-006).
- [ ] No fixture or financial demo data in `lib/` (Audit-012).
- [ ] Conventional Commits with CSA IDs used consistently (Audit-008).

### C. Audits (trail and records)
- [x] Review and acceptance boards exist in `docs/reviews/`.
- [x] Some acceptance records honestly state their limits (CSA-184).
- [ ] Bugs are tracked as GitHub Issues, not `finderror.md` (Audit-008).
- [ ] Governance document status is consistent (Audit-010).
- [ ] DONE states link to review evidence (Audit-013).
- [x] This audit is recorded in the repository (`AUDIT.md`).

### D. Comprehension gates
- [ ] PR template with required fields (Audit-007).
- [ ] PR size guideline enforced (Audit-007).
- [ ] Evidence, Gap, Criteria review recorded before merge (Audit-003).
- [ ] Owner "why this is safe" note for P0 areas (Audit-007).
- [ ] `CODEOWNERS` routes financial, auth and migration paths to the owner
      (Audit-007).

### E. Speed + quality + accountability
- [x] CI uses concurrency cancellation and timeouts, so feedback is fast.
- [x] One owner account is identifiable for every change.
- [ ] Protected `dev` with required checks (Audit-002).
- [ ] Deploy is decoupled from commit messages (Audit-001).
- [ ] One task, one branch, one PR, in practice (Audit-008).
- [ ] Workspace hygiene (Audit-011).

### F. AI security scanning + AI eval agents
- [x] Admin financial reads fail closed (`UnavailableAdminPaymentRepository`).
- [x] Admin enrollment grant fails closed in the client (`_unavailable()`).
- [x] No privileged keys in the Flutter client.
- [x] Dependabot is enabled with no auto-merge.
- [ ] HTTPS with security headers in production (Audit-004).
- [ ] GitHub secret scanning and push protection (Audit-005).
- [ ] gitleaks actually executed in CI (Audit-005).
- [ ] SAST (CodeQL) and a dependency-audit gate (Audit-009).
- [ ] A defined AI checker agent step on PRs (Audit-009, CLAUDE.md
      section 18).

### G. AI compliance audit (AGENTS.md and CLAUDE.md rules)
- [x] No fabricated test results found in the sampled PRs.
- [x] Payment and enrollment logic is not trusted to Flutter.
- [x] Supabase RLS is tested in CI with a real database.
- [ ] "Do not push directly to main/dev" (Audit-002).
- [ ] "Never merge your own PR unless instructed" plus authorized review
      for financial changes (Audit-003).
- [ ] "Never deploy without authorization" and green CI (Audit-001).
- [ ] PR fields from AGENTS.md section 42 (Audit-007).
- [ ] Definition of Done includes completed reviews (Audit-013).

---

## 5. Recommended fix order

1. Audit-001 and Audit-002: gate deploys and protect `dev`. This is
   repository settings plus one workflow change.
2. Audit-004: HTTPS and security headers on the server.
3. Audit-005: enable secret scanning (a settings toggle).
4. Audit-003 and Audit-007: PR template, plus the maker-checker mode from
   CLAUDE.md section 18.
5. Audit-006 and Audit-009: workflow hardening, CodeQL and audit gates.
6. Audit-008, 010, 011, 012, 013, 014: hygiene.

Each fix needs its own CSA task and owner. Workflow, repository-setting and
server changes are owner-authorized operations. This audit makes none of
them.
