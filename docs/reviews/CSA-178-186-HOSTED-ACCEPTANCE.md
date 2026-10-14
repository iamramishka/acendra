# CSA-178–186 hosted acceptance execution and implementation gaps

Reviewed revision: `e7a1cdc5bf4ea8b02864b3094be3c129876dc562`, 2026-10-14.
Owner: CODEX backend_acceptance delegate; see the adjacent ownership board.
No local tests executed, respecting the user's hosted-only instruction.
This report adds no passing result and does not replace historical CI evidence.

## Existing hosted verification

The `Supabase foundations` workflow supports `workflow_dispatch` on a pushed
branch. A documentation-only PR does not match its path filter, so root must
dispatch it explicitly if the integrated change has no `tool/**` or `supabase/**`
changes. Verify the run's head SHA equals the integrated commit before attaching
its result; a green run on an earlier head is historical evidence.

The workflow already executes:

```text
npm ci --no-audit --no-fund
npm run tool:test
npm run db:test
npm run db:lint
npm run db:start
npm run client:env
node tool/supabase_smoke.mjs
node tool/role_api_smoke.mjs
```

Its final cleanup always stops both task-owned stacks. These disposable services
run on the GitHub runner, not the user's machine. `supabase_smoke.mjs` imports
`runJourneySmoke`, receipt/PDF/private-media Storage checks and the Auth checks.
The journey uses actual disposable Auth/MFA/PostgREST/Storage with explicitly
synthetic provider responses, bank credits and PNG inspection. A successful run
establishes those integration boundaries, not actual provider/bank/scanner
acceptance or a Flutter purchase-to-content browser journey.

Root can dispatch and inspect the existing workflow, without adding workflows:

```text
gh workflow run supabase-foundations.yml --ref <pushed-integration-branch>
gh run list --workflow supabase-foundations.yml --branch <pushed-integration-branch>
gh run view <run-id> --json headSha,status,conclusion,url,jobs
```

## Concrete blockers to task completion

| Task | Current implementation boundary | Work required before final acceptance |
| --- | --- | --- |
| CSA-178 | Checkout `_onPayNow` displays `Online payment coming soon`; deployed `initialize-checkout/index.ts` supplies no provider adapter. | Separately coordinated checkout/provider integration, approved sandbox configuration, verified settlement and browser enrollment/content journey. Merely setting environment variables cannot enable the current deployed entry point. |
| CSA-179 | ReceiptUploadNotifier and finance review notifier throw feature-unavailable errors; routed admin finance screen displays synthetic preview records and does not record decisions. Deployed review/upload handlers have no enabled operational dependencies. | Approved inspection and independent bank-credit verification, real upload/review UI wiring, then pending denial, approval, rejection and resubmission browser evidence. Synthetic receipt or credit fixtures cannot close this gate. |
| CSA-180 | Learning repository fetches only public lesson metadata; DTO does not parse lesson bodies. LearningNotifier selects lessons but has no progress-save integration. PDF/video views remain unavailable. | Approved authorized lesson delivery contract and implementation, UI progress persistence, then paid access after settlement, denied access before settlement/after revocation and isolated student progress across logout/login. Public lesson metadata must never be expanded to expose paid bodies. |
| CSA-184 | Backend role/MFA checks have component and disposable-stack coverage; router authentication alone is not finance authorization. Current finance screen contains labelled synthetic records. | Operational finance data/actions guarded by trusted role/MFA checks, browser verification for finance/non-finance users and AAL1/AAL2 sessions, current backend denial evidence. The preview itself does not establish a real-data leak. |
| CSA-185 | Existing actual private Storage tests cover direct/public/signed denial for protected objects. User-facing delivery is not implemented by those fixtures. | Enable only approved authorized delivery implementations and verify authorized receipt/content delivery, cross-user denial, entitlement revocation, direct private-object denial and no private reference disclosure in UI/errors. |
| CSA-186 | Upload entry points supply no real inspection/resource policy; fixtureInspector validates only its synthetic exact-PNG fixture. | Approved actual inspector/scanner and resource limits, coordinated ingestion implementation, hosted safe/malicious/mismatched/oversize upload cases, isolation and quarantine failure evidence. No flag or passing fixture test satisfies the missing dependency. |

Sources inspected: checkout screen, bank_transfer providers, admin finance screen,
learning repository/DTO/notifier, initialize-checkout/upload-bank-receipt/
admin-review-bank-transfer/admin-create-media-upload entry points, the hosted
workflow, journey safeguards and TASKS.md Phase 8 acceptance requirements.

## Evidence needed for closure

For each task retain its implementation PR, accepted contract, hosted run URL
and exact SHA, actual scenario outcomes, and approved operational dependencies.
Use synthetic student/course/receipt data and retain sanitized evidence only;
never commit credentials, real bank receipts or private response bodies.
Record browser outcomes for both approval and denial; do not substitute a mock
collaborator for actual bank/provider verification. Existing code remains closed
while those dependencies are missing. These six tasks remain IN_REVIEW.

No duplicate injected-component tests were added: existing tests already cover
the component boundaries, and more synthetic passes would not fix the identified
missing implementation or operational acceptance. Root coordinates the fresh
hosted run; this delegate did not dispatch or execute a test.
