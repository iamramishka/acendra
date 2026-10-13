# CSA-184–188 security verification

Date: 2026-10-13 (Asia/Colombo). Agent: CODEX root with three parallel delegates.
Base: dev 4bdf4952831d859299c39cf23522083251a4d426.
Branch: test/csa-184-188-parallel-security.
Scope: existing tests and read-only security review; no application or policy changes.
Status: review artifacts merged in PR #120; all five acceptance tasks remain IN_REVIEW and unchecked.

Three isolated workspaces were used; no shared mutable database, storage bucket or fixtures were used. Open Issues, PRs and worktree ownership were checked before allocation. AGENTS.md section 8 permits this bounded documentation fallback where target Issues are absent; this record is not a GitHub implementation claim. No merge or release approval is implied.

| Task | Evidence | Acceptance gap |
|---|---|---|
| CSA-184 finance restrictions | 67 passing mocked handler tests; static least-privilege SQL and denial tests reviewed | Live database role tests, enabled bank review, finance UI verification |
| CSA-185 private file policies | Private/restrictive receipt and PDF policy source reviewed; protected delivery component tests | Actual SQL and Storage REST denial; complete asset groups |
| CSA-186 upload security | Upload format, size, ownership, inspection, digest and immutable path checks covered by existing component tests | Approved real inspector and enabled endpoint; admin media ingestion |
| CSA-187 XSS/security headers | See web review below | Deployed headers and browser payload verification |
| CSA-188 secrets/logging | See web review below | Built assets, history and production logging controls |

## Executed component tests

Finance delegate ran in C:/Users/ramis/Downloads/Acendra/review-csa184:

```text
node --test supabase/functions/admin-review-bank-transfer/handler.test.mjs supabase/functions/admin-assign-user-role/handler.test.mjs supabase/functions/admin-assign-user-role/unauthorized.test.mjs supabase/functions/admin-entitlements/handler.test.mjs
```

Exit 0; 67 passed, 0 failed, 0 skipped. Auth and SQL RPC are mocked; this verifies request boundaries rather than effective database roles.

Storage delegate ran in C:/Users/ramis/Downloads/Acendra/review-csa185-186:

```text
node --test supabase/functions/upload-bank-receipt/handler.test.mjs supabase/functions/pdf-content/handler.test.mjs supabase/functions/pdf-content/storage.test.mjs supabase/functions/_shared/pdf/authorization.test.mjs supabase/functions/authorize-video/handler.test.mjs
```

Exit 0; 132 passed, 0 failed, 0 skipped. Coverage includes spoofed MIME/extensions/signatures, oversized streams, unsafe paths, failed/timed-out inspection, cross-user denial, collisions, immutable replay, stored digest mismatch, original PDF/path rejection, entitlement denial, range authorization, upstream redirects and sanitized errors. These checks use injected/mocked dependencies.

## Finance restrictions

Static evidence:

- supabase/migrations/20261011001700_csa108_113_bank_workflow.sql:65 checks current account/session, AAL2 and finance/super role; :182 prohibits own-payment review; :229 restricts RPC execution to service role.
- supabase/migrations/20261011000900_csa089_course_creation.sql:46 requires content-manager/super authority, excluding finance alone. supabase/tests/database/csa089_course_creation.test.sql:38 contains finance denial.
- supabase/tests/database/csa108_113_bank_workflow.test.sql:44 covers self-review, student and non-MFA denial; :86 covers revoked-role replay.
- supabase/tests/database/csa061_trusted_roles.test.sql:58 and csa075_unauthorized_admin.test.sql:58 contain finance role-management denials.

No confirmed backend finance bypass was identified. SQL tests were not executed: Docker, psql and Supabase were unavailable on PATH. Run the repository database test workflow in an isolated disposable stack before acceptance.

admin-review-bank-transfer/index.ts:4 supplies no test enablement; handler.mjs:57 returns 503 by design. This preserves fail-closed behavior but prevents acceptance of the operational finance journey. lib/app/router/app_router.dart:63 and :167 allow authenticated users to the placeholder /admin route; finance-specific UI restrictions remain incomplete. This is not proof of a financial backend bypass.

Requirements: SRS role matrix and NFR-SEC-001/004/011; SECURITY finance permissions; docs/TESTING TST-RLS-009 through TST-RLS-012.

## Private files and uploads

Static evidence:

- supabase/migrations/20261011001700_csa108_113_bank_workflow.sql:7 establishes restrictive direct-client receipt object denial; :85 checks session, 5 MiB bounds, format and owned bank order.
- supabase/migrations/20261011001800_csa108_receipt_deletion_guard.sql:9 prevents deletion/replacement and enforces reserved paths.
- supabase/migrations/20261012002400_csa139_pdf_storage.sql:3 establishes a private bounded PDF bucket; :25 guards bucket safety and immutable paths.
- supabase/functions/upload-bank-receipt/validation.mjs:3, :32 and :52 bound reads, validate formats and require digest-bound inspection. handler.mjs:67 and :108 generate server paths and verify stored bytes.

No confirmed exploitable storage/upload defect was found. csa139_pdf_storage.test.sql, csa140_pdf_entitlement.test.sql, csa108_113_bank_workflow.test.sql and real Storage REST checks were not executed. upload-bank-receipt/index.ts:4 deliberately provides neither inspector nor enablement; successful real content inspection remains unverified. Admin media upload implementation is absent from this base (CSA-164 at TASKS.md:1735); thumbnail/lesson-image/PDF ingestion acceptance is incomplete. Existing receipt/PDF policies do not cover all intended media. PDF/video deployment gates remain in effect.

Requirements: SRS FR-BANK-005 through FR-BANK-008, FR-BANK-018 and NFR-SEC-007/011; SECURITY private content/upload boundaries; docs/TESTING file-upload threat scenarios.

## XSS and browser headers (CSA-187)

Read-only review of lib/, web/, Edge handlers and tool sources found no unsafe HTML/eval sink in examined current code; marketplace titles use Flutter Text. This static search does not demonstrate stored/reflected payload safety in a running browser. No tracked hosting header configuration or deployed URL evidence was available. Therefore CSP, HSTS, frame restrictions, nosniff, referrer and permissions headers remain unverified, rather than asserted absent from a deployment.

web/index.html:34 imports a third-party Google Fonts stylesheet; :48 loads Flutter bootstrap. Hosting CSP must be tested against these resources and approved integrations. PDF responses already include nosniff/private no-store and origin allowlisting; API headers do not establish application hosting headers. No dedicated XSS payload regression tests were found in the current test directory. SECURITY.md:1375 lists header expectations and :492 requires stored/reflected payload coverage.

## Secrets and logging (CSA-188)

The web delegate scanned 371 tracked paths / 366 text files with conservative credential patterns. One PEM marker match at supabase/functions/authorize-video/signer.mjs:7 was manually triaged as delimiter-removal code, not embedded key material. No credential-shaped findings remained after triage. Secret values were not emitted. This is a limited working-tree heuristic scan: gitleaks/trufflehog were unavailable; Git history, ignored/local files, compiled browser assets and managed production secrets were not scanned. It cannot certify absence of secrets.

lib/core/utils/logger.dart:4 accepts arbitrary message/error/stack data for debug output and has no redaction enforcement. No current caller was found, so this is a future misuse risk, not evidence of a present disclosure. Production log access, retention and synthetic log-content checks remain unverified. Requirements: NFR-SEC-003/008/012, SECURITY threat 008/012 and docs/TESTING.md:2644 browser bundle checks.

The web delegate ran in C:/Users/ramis/Downloads/Acendra/review-csa187-188:

```text
node --test tool/auth_security.test.mjs tool/local_supabase.test.mjs supabase/functions/pdf-content/handler.test.mjs supabase/functions/_shared/pdf/authorization.test.mjs
```

Exit 0: 86 passed, 0 failed, 0 skipped. This includes existing public environment export exclusions and safe lint redaction tests. It overlaps the storage stream's PDF tests: the three Node invocations total 285 successful executions, not 285 distinct tests.

## Handoff and acceptance

No source fixes, new tests, migration edits or deployed checks were performed. All task checkboxes remain unchanged. No confirmed exploitable bypass was identified within this bounded review; the unexecuted runtime checks remain P0 acceptance gaps.

Next owner actions: establish target GitHub task claims and exact writable scopes; make required foundation implementations available on the approved integration base; run effective-role SQL and direct Storage REST negative tests in a disposable isolated environment; enable receipt/review/delivery only after their approved prerequisites; test XSS payloads and effective hosting headers; scan history and release browser assets with dedicated tooling; verify redacted runtime logs and log access/retention. Submit security fixes separately with TDD and authorized review. Project owner controls acceptance and merge.

Root verification: git diff --check. Flutter analyze/build/full-suite were not run for this documentation-only change. Delegate environment-test result is recorded separately below.


Web delegate also invoked `flutter test test/core/config/env_config_test.dart`. Dependency resolution and test loading were observed, but no final result was captured. Root could not resume the delegate session (unknown process ID). This check is unverified and is not counted as passed.

## PR #120 integration review — 2026-10-13

The owner requested review and merge into dev. The report above is historical evidence against 4bdf495, not a current security clearance. Current dev includes the admin media-upload foundation and newer security tests; the old absence statement applies only to the recorded base. Runtime and operational acceptance gaps still require separate verification.

The branch inherited unrelated task-status and accessibility/marketplace changes from its local base. During integration, those paths were compared with current origin/dev and restored to the reviewed dev versions; the price-format helper belonging to that unrelated refactor was removed. Final PR scope is only this report and its coordination board. No production code, policies or task checkboxes change relative to dev. This is deliberate scoped reconciliation, not blanket conflict resolution. The user authorizes merging these review artifacts; CSA-184 through CSA-188 remain incomplete pending their documented acceptance evidence.

## Verified merge outcome — 2026-10-13

[PR #120](https://github.com/iamramishka/acendra/pull/120) merged into `dev` at `b0f3dd61592d6fc8623dde28233910dec6833736`. The reviewed head was `ca6cc04413c6571525e23e21fed5a29073ffc218`. Full-diff review found no blocking findings for the documentation artifacts; integration with the then-current remote `dev` was conflict-free and `git diff --check` passed.

The reviewer reran the eleven distinct Node test files listed in the three historical commands above in one invocation: 213 tests passed, zero failed or skipped. This removes repeated PDF test executions from the historical total of 285; the historical evidence remains unchanged. These component tests retain their mocked/injected dependencies and do not establish live SQL, Storage or deployment acceptance.

[CI run 38350062116](https://github.com/iamramishka/acendra/actions/runs/38350062116) passed formatting, analysis, all Flutter tests, release web build and tooling regression checks. The previously unverified delegate Flutter invocation remains unverified as a historical execution; the successful CI run is separate evidence. All five task checkboxes remain unchecked. No deployment or security-policy approval is inferred from the merge.

## Current security acceptance status

| Task | Current status | Remaining acceptance |
|---|---|---|
| CSA-184 | IN_REVIEW, unchecked; evidence PR merged | Effective finance-role SQL denials and operational finance workflow |
| CSA-185 | IN_REVIEW, unchecked; evidence PR merged | Current SQL/Storage REST private-file policy matrix |
| CSA-186 | IN_REVIEW, unchecked; evidence PR merged | Approved actual inspection and integrated receipt/admin media uploads |
| CSA-187 | IN_REVIEW, unchecked; evidence PR merged | Effective deployed headers and browser XSS payload checks |
| CSA-188 | IN_REVIEW, unchecked; evidence PR merged | Dedicated history/build scans and runtime log privacy/access/retention |

PR #125 reconciliation preserves PR #126's evidence and the original historical base. Review artifacts are accepted; production readiness and P0 security acceptance remain unverified. Documentation reconciliation ownership ends after this update is reviewed and merged.
