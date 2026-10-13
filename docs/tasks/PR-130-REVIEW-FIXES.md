# PR130 review remediation
Owner: CODEX; user authorized fixing the findings on 2026-10-14.
Issue: #142. Status: IN_REVIEW. Approval authority: project owner.
Branch: codex/fix/csa-107-pr130. Worktree: C:/Users/ramis/Downloads/Acendra/pr130-fix.
Base: PR130 d061a25 merged with origin/dev 7689e5f in this isolated worktree.
Checked open issues, PRs and worktrees; other receipt/finance work is outside scope.
Scope: original PR130 screen, canonical bank instruction screen, checkout navigation,
app_router bank route (temporary ownership), focused tests, this record.
Dependencies: CSA098 trusted checkout response, CSA107/110 routes on dev.
No approved reload endpoint exists. Missing/mismatched/invalid checkout data must
show unavailable instructions and no transfer action. A reload service remains
follow-up backend work; no invented RPC, mock bank details or fake submission.
Receipt upload/review gates remain unchanged. No production or merge authorization.
Verification: RED/GREEN regression tests, formatting, analysis, full tests, web build.
Additional necessary scope: checkout repository and DTO contract fixes (header idempotency key, 201 creation response, branch_name/currency_code), discovered while tracing the transfer flow. No backend contract changes.

Changes: original PR entry point delegates to canonical provider-driven screen;
route extras no longer supply financial values; exact backend minor units and
configured destination are shown only for a matching pending bank order. Checkout
now has a Continue Bank Transfer action and transfer CTA navigates to receipt UI,
without claiming submission success. Original card/entity/tests formatting repaired.
RED: three instruction tests failed before correction; two real HTTP serialization
fixtures failed for missing Idempotency-Key and rejection of 201 before correction.
GREEN: initial 21 focused bank/repository tests passed. Final suite pending below.
Security: no entitlement/payment state changes; no privileged credentials or public
bank snapshot access. Tests use synthetic data and a local HTTP fixture.
Local analyzer: no issues. Formatting: 174 lib/test files, zero changes.
Initial concurrent full suite hit OS errno 112 (disk full); web build interrupted.
Automatic review blocked removal of generated worktree files. No deletion occurred.
Verification continues sequentially to reduce temporary disk use.
Final targeted check: 56 tests passed with --concurrency=1, including exact amount/destination, original entry point, checkout-to-receipt navigation, 200/201 HTTP contract and router guards.
Full suite retry: flutter test --no-pub --concurrency=1 passed all 374 tests on 2026-10-14. Disk error was environmental; sequential retry completed without deletion.

Final verification: release web build passed (including Wasm dry run); inherited
Cupertino icon-font warning remains. git diff --check passed. No database tests
were required: no SQL, backend handlers, policies or financial state changed.
Handoff: original CLAUDE history is preserved. CODEX fix branch is fast-forwarded
onto PR130 for CI and maintainer review, without merging dev or deploying.
Shared router ownership is released after this bounded remediation submission.
Remaining: approved backend reload service for durable URL recovery; hosted CI
and maintainer acceptance. The safe unavailable fallback does not claim reload.
