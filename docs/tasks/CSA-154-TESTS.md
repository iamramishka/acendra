# CSA-154 unauthorized video request tests

Owner: CODEX video_request_tests. Coordination: issue #101 (worker assignment), prerequisite implementation issue #94 and integration issue #93.
Branch: `codex/test/csa-154-video-denials`.
Isolated workspace: `C:/Users/ramis/.codex/worktrees/csa-154-video-denials/acendra`.
Writable scope: this record and `tool/csa154_video_requests.test.mjs` only.

## Verification contract

The suite calls the real committed CSA-136 `createHandler` when available, with synthetic Auth, RPC and signer collaborators. It checks missing/invalid bearer, rejected Auth credentials, anonymous identity, mismatched subject, invalid session and role, expired token, caller-supplied authority fields, RPC denial/failure, invalid lesson/provider/expiry bindings, and expiry during the round trip. Every denial requires no signer invocation, a safe fixed response and `Cache-Control: no-store`. Provider diagnostics and backend credentials must never appear in responses.

The RPC denial test proves the handler propagates a trusted denial without signing. It does **not** establish that PostgreSQL correctly detects foreign-owner, unpublished, revoked or expired entitlements. Those criteria require the real CSA-136 SQL suite against the committed entitlement verifier. Already-issued token expiry, real Mux privacy/renewal, and operational provisioning remain separate acceptance gates.

## Dependency and evidence

Baseline `origin/dev`: `9cd6c39164742b8cb7dfda9cb9e092556f064fa9`. CSA-136 handler was untracked in its owner's isolated worktree during contract inspection; no implementation source was copied or modified. If the committed handler is absent, each test explicitly skips with the CSA-136 dependency reason. This represents test preparation, not verified playback protection or DONE status. Integration must execute these tests with the reviewed committed implementation and preserve any failures.

Command: `node --test tool/csa154_video_requests.test.mjs`. Expected initial dependency result: 23 skipped, 0 executed; final observed result recorded by integration owner. No production configuration, signing secret, Mux request or deployment is involved.
