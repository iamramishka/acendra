# CSA-178–183 verification evidence

Date: 2026-10-13. Target revision: 4bdf4952831d859299c39cf23522083251a4d426 (dev).
Parallel local verification was requested by the project owner. See CSA-178-183-PARALLEL-BOARD.md for scope and coordination.

| Task | Executed evidence | Acceptance status |
| --- | --- | --- |
| CSA-178 | 163 online/common-checkout Node tests passed | BLOCKED: full browser/provider sandbox journey unavailable |
| CSA-179 | 81 receipt-upload/bank-review Node tests passed | BLOCKED: integrated approval/storage/operations unavailable |
| CSA-180 | 99 entitlement/video/PDF Node tests passed | BLOCKED: purchase-to-learning UI and delivery integration unavailable |
| CSA-182 | Static migrations and SQL-test audit | BLOCKED: effective runtime RLS/grants audit not executed |
| CSA-183 | Static inspection of isolation SQL scenarios | BLOCKED: SQL/API isolation tests not executed; coverage gaps |

All 343 component tests passed with zero failures/skips. This does not establish E2E acceptance. No task marked DONE. No production calls, real payments, policy changes or database mutations performed.

## Executed commands

Combined CSA-178/179 run (244 pass, exit 0):

```powershell
node --test supabase/functions/create-checkout-order/*.test.mjs supabase/functions/_shared/payments/*.test.mjs supabase/functions/initialize-checkout/*.test.mjs supabase/functions/payment-provider-webhook/*.test.mjs supabase/functions/upload-bank-receipt/*.test.mjs supabase/functions/admin-review-bank-transfer/*.test.mjs
```

CSA-180 run (99 pass, exit 0):

```powershell
node --test supabase/functions/admin-entitlements/handler.test.mjs supabase/functions/authorize-video/handler.test.mjs supabase/functions/_shared/pdf/authorization.test.mjs supabase/functions/pdf-content/handler.test.mjs
```

Bank subset was also rerun: 81 pass; online/common subset rerun exited 0 (163). Repeat counts are not added to the total. Tests use synthetic injected collaborators.

## Journey blockers

Checkout, My Courses and learning workspace are placeholders: lib/app/router/app_router.dart:133,137,157. No integration_test directory exists.

Provider gates: docs/contracts/CSA-101-105-INTEGRATION.md:42–45. Receipt inspection/limits gates: docs/contracts/CSA-108-109-RECEIPTS.md:20–24. Bank operational gates: docs/contracts/CSA-112-BANK-REVIEW.md:96–100.

PDF entry point explicitly disabled: supabase/functions/pdf-content/index.ts:6. Video handler defaults disabled: supabase/functions/authorize-video/handler.mjs:4. These gates were preserved.

Docker CLI exists at C:/Program Files/Docker/Docker/resources/bin/docker.exe, but `info --format '{{.ServerVersion}}'` failed because the local docker_engine named pipe was absent. No disposable database suite was run. No Flutter/browser test was run; component evidence does not verify UI journeys. Provider sandbox and banking acceptance are previously unverified dependencies, not newly approved policies.

## RLS and isolation source review

No demonstrated exploitable defect found in this bounded static review; this is not a security clearance.

Ownership policies reviewed: profiles (20261011000200_csa060_profile_rls.sql:53), orders (20261011001000_csa092_orders_payment_attempts.sql:62), enrollments (20261011001300_csa095_enrollments.sql:97). Progress RPCs derive caller ownership and check session/entitlement (20261012002200_csa133_progress.sql:3,55,62). Reviewed private tables enable RLS and revoke direct application grants; privileged RPCs use explicit execution grants and empty search_path.

Existing SQL coverage: symmetric profiles (csa074_profile_isolation.test.sql:25,43), orders (csa092_orders_payment_attempts.test.sql:59,71), enrollment/source denial (csa096_financial_integrity.test.sql:96), and PDF cross-student reuse with both students entitled (csa140_pdf_entitlement.test.sql:57). All paths are under supabase/tests/database; these were inspected, not executed.

Coverage gaps:

1. csa133_progress.test.sql:41 denies a foreign unentitled student, but does not establish two entitled students with independent progress reads/writes for the same course.
2. csa116_119_entitlements.test.sql:52 largely tests an owner-role DO block with JWT claims; add actual authenticated-role execution of the entitlement RPC.
3. Add a comprehensive effective catalog/ACL matrix covering every application table and RPC, column privileges and direct API requests. Per-feature checks do not prove complete current grants. See docs/TESTING.md:1456,1549.

## Next authorized work

Establish target Issues and detailed acceptance/ownership, complete dependent UI and approved sandbox/banking/media readiness, start an isolated disposable Docker/Supabase stack, add missing effective-role/isolation scenarios in separately claimed test scopes, then run full database/API and browser journeys A/B/C/E/F. Keep financial implementation and deployment changes separately owned and reviewed.

This report is documentation preparation for review. TASKS.md remains unchanged; no full task acceptance or independent security approval is claimed.

## Review against current dev (2026-10-13)

The report above is historical evidence for revision 4bdf495, not an assertion about the latest dev. During PR #115 review, the source snapshot was integrated with current dev and inherited marketplace/accessibility/task-status changes were excluded from this documentation PR. Their original commits remain available for separate review. Current dev application code, migrations and master task coordination were preserved exactly.

Subsequent dev work now includes csa155_progress.test.sql and effective authenticated-role entitlement coverage in csa116_119_entitlements.test.sql; the earlier coverage gaps must be reassessed against these implementations. Existing successful Supabase CI from newer PRs is separate evidence and does not retrospectively mean this historical SQL/browser run occurred. Full journey/provider/browser acceptance still requires its own current evidence.

Project owner authorized the review and dev merge. Acceptance of these documentation artifacts does not mark CSA-178/179/180/182/183 DONE or waive P0 gates.
