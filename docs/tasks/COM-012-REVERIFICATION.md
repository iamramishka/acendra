# COM-012 re-verification — 2026-11-03

Owner: CODEX. Status: IN_REVIEW. Owner requested verification, reference comparison and fixes in this chat.
Existing task: CSA-276 / issue #219; PR #220 merged on 2026-10-26. This follow-up does not reopen or claim completion of hosted acceptance.
Branch: fix/csa-276-com012-verification. Worktree: C:/Users/ramis/.codex/worktrees/com012-bank-receipt/acendra. Base: origin/dev e55e9ed.
Scope: existing bank-transfer instructions screen, focused receipt tests and this evidence record. No shared file locks required. Existing other-agent worktrees and unrelated local changes excluded; open PRs and worktrees checked before editing.
Dependencies: merged receipt flow; existing immutable instruction read and private upload contracts. Approval authority: owner/maintainer; deployment and receipt inspection activation remain separate.
Acceptance: artifact section order, clearly labelled backend reference and exact amount, four copy actions, JPEG/PNG/PDF transport, reload recovery, unauthorized requests denied and no private paths returned. Required checks: focused widget/handler tests, affected suites, analyzer and web build.

## Current reference and environment

Opened https://claude.ai/artifact/NDAfFDE3QHzxMNTRXqf4RJ in the browser and navigated its synthetic sample checkout to Bank Transfer. Observed heading/subtitle, course/order/amount summary, bank details with three copy controls, exact-reference guidance, receipt upload, verification notice and disabled sticky submission. The baseline implementation included an extra four-step list and combined reference/amount badge instead of the summary card.

This patch replaces those sections with the reference subtitle and labelled course/reference/total summary, adds the bank subtitle and upload card, and places the independent-bank-credit warning after upload. All values still come from the owner-scoped backend snapshot; four copy actions and sticky submission remain. No category is fabricated when the backend supplies none. This is section/layout alignment, not a claim of authenticated hosted pixel parity.

https://acendra.vercel.app redirects to /#/login in this session. Owner confirms no verified staging test account with receipt uploads enabled, Supabase staging project worrsweluwjmppwsygre, and unavailable 3.25.99.105 server. Source upload entry point supplies neither an approved inspector nor upload enablement; read entry point also retains its operational gate. No live upload or authenticated visual parity is claimed. Do not enable either gate to make tests pass.

## Evidence

- RED: the added 390px layout regression failed because the reference subtitle was missing.
- GREEN: `flutter test --no-pub test/features/bank_transfer/presentation/com012_upload_flow_test.dart test/features/checkout/com012_receipt_test.dart --concurrency=1 --reporter expanded`: 14 passed, exit 0 on final source. Covers 320/390/768/1440 light/dark, recovery with empty checkout memory, wrong-order/server-error denial, selection/removal/confirmed submission, JPEG/PNG/PDF MIME and 5 MiB boundaries.
- `node --test supabase/functions/bank-transfer-read/handler.test.mjs supabase/functions/upload-bank-receipt/handler.test.mjs`: 55 passed, exit 0. Added JPG/JPEG/PNG/PDF synthetic transport cases and missing/rejected Auth denial. Existing cross-user, spoofing, private-path, no-overwrite, inspection, retry and finalization checks remain green.
- `node --test tool/csa179_bank_read.test.mjs`: 13 passed, exit 0.
- Changed Dart files formatted; `git diff --check` passed.
- Broader affected Flutter suite attempted with concurrency 1, but the Dart runtime aborted with out-of-memory and DartWorker thread-start errors. An earlier focused attempt also exhausted memory; the subsequent focused retry above passed. No broader pass is claimed.
- `flutter analyze --no-pub`: no issues, exit 0.
- Added browser picker regressions for JPEG and PDF byte preservation alongside existing PNG/size/cancel checks. `flutter test --no-pub --platform chrome test/browser/receipt_file_picker.browser.dart --reporter expanded` remained at loading/compilation without test output and was interrupted after a bounded attempt; browser execution remains unverified.
- `flutter build web --release --no-pub`: failed, exit 1. Wasm dry run succeeded, then dart2js aborted with DartWorker thread-start failure (process exit -1073740791). No successful release build is claimed.

The handler fixtures use a synthetic inspector and mocked Auth/SQL/Storage. They prove boundary behavior, not actual malicious-file detection, hosted bucket privacy or hosted RLS. No fresh database/Supabase Storage integration result is claimed. Hosted JPEG/PNG/PDF upload, browser refresh against staging, anonymous/other-student direct object denial and authenticated visual comparison remain blocked on an approved inspector, operational activation and test accounts. No paid purchase, deployment, gate bypass or live database/storage mutation was performed. Earlier PR #220 evidence is historical, not a current hosted result.

Draft review: https://github.com/iamramishka/acendra/pull/259. Current-head CI and maintainer review remain required; task is not DONE. Existing saved owner credentials were used only in the publishing command; default account settings were not changed.
