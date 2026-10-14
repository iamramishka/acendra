# CSA-178/179/180/184/185 sample acceptance continuation

Date: 2026-10-14, Asia/Colombo. Owner: CODEX.
Authority: owner requested completion of five tasks and authorized sample data.
Existing coordination: issue #129 retains CODEX ownership; open PR inventory was empty at allocation. No reassignment or new issue claim.
Base: origin/dev e7a1cdc5bf4ea8b02864b3094be3c129876dc562.
Branch: codex/test/csa-129-sample-acceptance.
Worktree: C:/Users/ramis/.codex/worktrees/csa-178-185-sample-acceptance/acendra.
Allowed scope: this record and docs/reviews/CSA-178-185-SAMPLE-DATA.json only. No shared files or implementation changes.
Dependencies: merged handlers, task-local Docker/Supabase for integrated runs, approved staging/provider/finance/inspection environment for operational acceptance.
Approval authority: project owner/security/finance. Sample evidence cannot establish independent bank credit or real provider acceptance.
Verification criteria: latest-base component tests, valid sample JSON, documentation diff check, explicit unexecuted boundaries.
Status: IN_REVIEW; full task acceptance remains pending.

## Results

On the exact base above, Node component tests for create-checkout-order, shared payments, initialize-checkout, payment-provider-webhook, upload-bank-receipt, admin-review-bank-transfer, admin-entitlements, PDF authorization, journey safeguards and admin Storage safeguards: 301 passed, 0 failed, 0 skipped. Command: node --test supabase/functions/create-checkout-order/*.test.mjs supabase/functions/_shared/payments/*.test.mjs supabase/functions/initialize-checkout/*.test.mjs supabase/functions/payment-provider-webhook/*.test.mjs supabase/functions/upload-bank-receipt/*.test.mjs supabase/functions/admin-review-bank-transfer/*.test.mjs supabase/functions/admin-entitlements/*.test.mjs supabase/functions/_shared/pdf/authorization.test.mjs tool/csa178_186_journey_smoke.test.mjs tool/csa185_admin_storage_smoke.test.mjs

The existing integrated sample harness is tool/csa178_186_journey_smoke.mjs. It already generates isolated synthetic accounts, bank account/version, course/order/payment and an exact synthetic PNG inspector against disposable Auth/RPC/Storage. Sample provider and bank evidence are explicitly injected. No duplicate harness or persistent seed mutation was introduced.

Docker CLI at C:/Program Files/Docker/Docker/resources/bin/docker.exe could not connect to docker_engine (named pipe absent). Real local SQL/Auth/Storage and full browser journeys were not executed. No staging URL, provider sandbox credentials, finance MFA access or independent bank-credit evidence was provided. Only .env key names were inspected; it contains GitHub configuration, not staging/payment configuration. No secrets were printed or added to sample data.

## Task conclusions

| Task | Current verification | Remaining acceptance |
|---|---|---|
| CSA-178 | Sample checkout/provider component checks passed | Actual sandbox and complete browser journey; initialize-checkout entry point remains gated |
| CSA-179 | Sample receipt/bank decision component checks passed | Actual independent credit and operational receipt/finance workflow; upload/review entry points remain gated |
| CSA-180 | Sample entitlement/PDF authorization component checks passed | Post-merge browser purchase/My Courses/learning/protected delivery journey; PDF entry point remains disabled |
| CSA-184 | Sample finance authorization/MFA component checks passed | Effective operational finance workflow with real Auth/SQL environment |
| CSA-185 | Storage guard and authorization component checks passed | Actual enabled receipt/PDF/media transport; no local Storage run completed |

Sample data in CSA-178-185-SAMPLE-DATA.json is an acceptance planning fixture, not an API payload, provider proof, bank statement, seeded database or operational credential. IDs and emails are synthetic. Expected outcomes describe checks to execute, not observed browser results. Existing tests use their own isolated fixtures.

No task was marked DONE. Next step: make the isolated Linux Docker/Supabase runtime available for integrated sample execution, then supply approved operational staging/provider/inspection and test finance access for remaining acceptance. Production activation and independent-credit claims cannot be inferred from the sample-data authorization.

Runtime follow-up: requested Docker Desktop startup with a hidden window and installed the pinned tooling using npm ci --no-audit --no-fund (8 packages installed). A subsequent Docker probe still failed on the absent docker_engine pipe; no Docker process was observed. No task-owned database was started or mutated. This runtime remains unavailable after the startup attempt.
