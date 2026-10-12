# CSA-152: Unauthorized PDF request regression tests

Owner: CODEX PDF test worker. Assignment: [issue 101](https://github.com/iamramishka/acendra/issues/101).
Branch: `codex/test/csa-152-pdf-requests`.
Worktree: `C:/Users/ramis/.codex/worktrees/csa-152-pdf-requests/acendra`.
Scope: `tool/csa152_pdf_requests.test.mjs` and this handoff only.
Status: tests prepared; integrated acceptance BLOCKED by unmerged PDF dependencies.
Approval authority: project owner/designated maintainer. No merge or deployment performed.

## Requirements and dependencies

Approved CSA-010 requires current authorization on descriptors, bytes, HEAD,
ranges and conditional requests, immutable personalized derivatives, no original
fallback, and no private Storage references in student responses. Tests use the
published fixed v1 adapter contract in PDF implementation issue 95. Implementation
owners retain their files and migration 025; this task changes no production code.

The actual `createHandler` and `createAuthorizer` are composed. External Auth,
PostgREST and Storage responses are synthetic and explicitly stubbed. This is
adapter/transport regression evidence, not proof of JWT signature verification,
database entitlement enforcement, RLS, watermark bytes, or live Storage access.
Those require the full SQL and API integration suites owned by the root task.

## Coverage

- Missing/malformed bearer and Auth-rejected forged/revoked tokens.
- Verified Auth identity mismatch, invalid session/role/AAL, anonymous user.
- Rejected client user/course/path/signed-URL substitutions and duplicated IDs.
- Resolver responses with wrong lesson/resource, original bucket or original path.
- Denial before storage for GET/HEAD, valid/invalid/multi-range and conditional headers;
  no size, path, credential or redirect disclosure.
- Preparing descriptor and byte requests never open original storage.
- Positive range control binds verified actor/session and requested IDs to the RPC.
- A successful HEAD followed by current RPC denial on the same handler rechecks authorization.

## Verification on 2026-10-12

`node --test tool/csa152_pdf_requests.test.mjs` on the task branch based on
`origin/dev`: 34 tests skipped, 0 passed, 0 failed. Each skip states
`DEPENDENCY_PENDING` because both PDF target modules are absent. Missing modules
never become fake passing authorization implementations; other import errors fail.

An ignored temporary snapshot was exported using `git archive`, containing only
committed source:

- Handler: `b171c4116c05268760cc1a290a225b1648b9a80a`.
- Authorizer: `369da615c1ba30db5642b17628a29ea265baf51e`.

The same test file in that snapshot: **34 passed, 0 failed, 0 skipped**.
No pending source from the PDF owner's working tree was copied or modified.
`git diff --check` passed.

## Handoff

Root should cherry-pick this scoped commit, refresh verification against the full
immutable PDF integration head, and run the real resolver/revocation tests. Normal
`tool/*.test.mjs` discovery already includes this suite; no manifest edits needed.
Keep dependency skips visible in CI and keep CSA-152 short of DONE until integrated
SQL/API acceptance is verified. Production activation and PDF worker operational
gates remain with their implementation owners.
