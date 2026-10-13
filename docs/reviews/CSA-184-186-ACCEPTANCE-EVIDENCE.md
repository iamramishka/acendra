# CSA-184–186 acceptance continuation evidence

Date: 2026-10-13 (Asia/Colombo). Owner: CODEX security runtime delegate.
Base: `8365d844dc717cb2dc572205635639ba148c003f`; isolated branch `codex/test/csa-184-186-acceptance`.

## Fresh component verification

Executed in the task-owned worktree:

```text
node --test supabase/functions/admin-review-bank-transfer/handler.test.mjs supabase/functions/admin-assign-user-role/handler.test.mjs supabase/functions/admin-assign-user-role/unauthorized.test.mjs supabase/functions/admin-entitlements/handler.test.mjs supabase/functions/upload-bank-receipt/handler.test.mjs supabase/functions/admin-create-media-upload/handler.test.mjs supabase/functions/pdf-content/handler.test.mjs supabase/functions/pdf-content/storage.test.mjs supabase/functions/_shared/pdf/authorization.test.mjs supabase/functions/authorize-video/handler.test.mjs
```

Exit 0: **224 passed, zero failed, zero skipped**, duration 3700 ms. Injected/mocked dependencies verify component boundaries; they do not prove effective deployed roles or an approved content inspector.

## Current foundations and remaining acceptance

The current base includes `csa164_media_uploads.test.sql` and the admin media handler, unlike the historical review base. The SQL suite exercises private pending reservations, student metadata denial, revoked assignment/session/role denial, atomic audit failure rollback, replay immutability, PDF ambiguity prevention, size limits and private bucket configuration. Execution remains distinct from this source inspection.

The existing Supabase foundations workflow replays migrations, runs database and concurrency tests, then executes real transport smoke tests against its isolated disposable stack. `tool/supabase_smoke.mjs` invokes receipt and PDF Storage smoke tests. Receipt transport uses **synthetic inspection evidence**, not a production inspector. Its success cannot close approved inspection or operational banking gates. Current transport smoke coverage does not establish a complete thumbnail/lesson-image/admin ingestion matrix.

`supabase/functions/upload-bank-receipt/index.ts`, `admin-review-bank-transfer/index.ts` and `admin-create-media-upload/index.ts` intentionally supply neither enablement nor an approved policy/inspector. Operational receipt upload, bank review and admin ingestion acceptance remains dependent on separately approved foundation readiness. No endpoint was enabled and no production configuration or migration was changed.

## Handoff

CSA-184: fresh finance/role component checks pass; effective SQL execution and operational finance workflow evidence still required.

CSA-185: current receipt/PDF transport harness available; current exact-base CI evidence and complete asset policy matrix still required.

CSA-186: current receipt/admin media component checks pass; approved actual inspection and operational integration remain required.

Local Docker/Supabase CLI are unavailable on PATH. Native PostgreSQL alone cannot establish Storage REST acceptance. The host temporarily rejected PowerShell startup with paging-file exhaustion/OutOfMemoryException during dispatch; a later retry succeeded.

## Fresh real database and Storage evidence

[Supabase foundations run 38353113078](https://github.com/iamramishka/acendra/actions/runs/38353113078) completed successfully against `8dd83ca5fc19f88e9ea7d113cba2484e60a13631`, which changes only this claim board relative to the base. Migration replay, all real database tests, serialized financial concurrency checks and database lint passed. Logs explicitly record real private receipt upload/readback, duplicate/direct denial/finalized preservation; PDF readback, direct/signed/public denial, immutable versions and cleanup; real MFA/role API denials, revocation, expiry, logout and concurrent handoff. Both task-owned stacks stopped successfully. This closes the previously unexecuted current-base database and receipt/PDF transport checks; operational acceptance is still separate.

Added `tool/csa185_admin_storage_smoke.mjs` and a minimal import/call in the existing runner under root-authorized temporary ownership. The new transport check covers both private thumbnail and lesson-image path forms: trusted synthetic byte upload/readback, anonymous/student direct/public/signed/list/write/delete denial, preservation after denied mutation and exact UUID cleanup. Two local safeguard tests passed and syntax validation passed. Hosted execution of this new test is pending; do not count its transport assertions as passed until the refreshed run finishes.

Status: **IN_REVIEW**, no DONE claim. Root owns consolidated task registry and final review/PR. No shared contract or production source changes; Flutter checks are not applicable to this documentation-only change. Required independent review and owner acceptance remain separate.
