# CSA-121–126 financial regression ownership and evidence

Owner CODEX. Issue87; isolated branch codex/test/csa-121-126-financial-security
and managed csa-121-126-financial-tests worktree. Base merged dev a19fd04891ec196c6b08a90bb65e28a12839020d (includes PR84).
Allowed scope new financial SQL regression file, this handoff, TASKS.md these six
IDs only. One test owner; production RPCs/migrations/package/runner unchanged.
Active issue85/PR86 entitlement and notification scope remains independent.

| Task | Evidence surface |
| --- | --- |
| CSA121 | New underpayment/zero/canonical-currency SQL; existing bank and online amount/currency mismatch and adapter exact-money tests |
| CSA122 | New recovered bank review replay/one-grant-one-outbox checks; existing online duplicate event/body-conflict tests and actual concurrent callback races |
| CSA123 | Existing real independent-session bank same-key/opposing decision/credit-reuse races run by db:test, observing actual blocked PostgreSQL backends |
| CSA124 | New pending/rejected no-grant/no-projection, authenticated private lesson/media path denial; existing restrictive private Storage transport tests |
| CSA125 | New expired/banned/nonfinance rejection/direct-browser-RPC checks; existing self-review/MFA/revoked-role and live Auth/MFA denial |
| CSA126 | New fault injection at bank review record/final approval audit/outbox; rollback settlement/attempt/order/submission/grant/projection/key, then successful same-key recovery/replay; existing online rollback/recovery |

Acceptance is fresh local tests plus full Supabase migration replay, regression
SQL, actual independent-session races, strict lint and live private Storage/Auth
checks on the final PR commit. No production calls or acceptance fabrication.
CSA124 proves current merged backend boundaries only; full protected lesson delivery
integration with proposed PR86 verifier remains a downstream release check.
Tasks remain IN_REVIEW until authorized review/merge. Approver project owner.
Local npm run tool:test:266 passed,3 database concurrency suites intentionally skipped in local mode. Full real database suite/concurrency runs in CI. Draft PR88; status IN_REVIEW.
