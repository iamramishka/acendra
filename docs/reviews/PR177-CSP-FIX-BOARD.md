# PR #177 protected playback CSP correction

Date: 2026-10-18. Status: IN_REVIEW.

- Coordination context: existing PR #177 / Audit-004. This is a local bounded
  correction assignment, not a GitHub Issue claim.
- Original implementation owner: CLAUDE. Temporary correction owner: CODEX,
  explicitly authorized by the project owner's request to fix the review
  findings in parallel and prepare the PRs for merge into `dev`.
- Branch: `fix/csa-audit-004-pr177-playback-csp`.
- Worktree: `C:/Users/ramis/Downloads/Acendra/review-pr177-20261018`.
- Reviewed starting head: `73cda476e1e3a53a0f3b7cead0ce95b31c7b787f`.
- Integration base: `origin/dev`; dependencies: PR #176 and the existing
  protected video authorization contract returning signed Mux playback URLs.
- Allowed file scope: `server/nginx.conf`, `tool/deployment_csp.test.mjs`,
  this board, and (only if evidence needs updating)
  `docs/reviews/PR177-DEPLOY-FIXES.md`.
- Temporary ownership: only this correction agent edits those files in this
  worktree. PR #179 and #180 correction agents own disjoint files/worktrees.
  Shared workflow/task/architecture files remain outside this assignment.
- Approval authority: project owner. Root agent reviews the local correction
  and performs any authorized push or merge after required GitHub gates.

Verification criteria: demonstrate RED against the reviewed policy, allow Mux
playback media and fetches while denying unrelated hosts, preserve other CSP
restrictions, run focused deployment tests and the applicable tooling suite,
check the diff, and commit locally for review. A local Chrome test uses only
synthetic URLs and maps external hosts to loopback; no live media or account is
needed. Production configuration, provisioning and deployment remain separate
owner-authorized operations. Release temporary correction ownership after the
root accepts the handoff; keep this proposal IN_REVIEW until acceptance.

## Playback source decision

[Mux's official CSP guide](https://www.mux.com/docs/core/content-security-policy)
documents HTTPS Mux subdomains for manifests and segments, with blob media and
workers for playback. Add `https://*.mux.com` only to media/fetch directives and
`blob:` to media; retain the existing worker permission. Analytics, direct
uploads, third-party scripts and scheme-wide HTTPS permissions are outside this
playback correction.

## Evidence

- RED: `node --test tool/deployment_csp.test.mjs` against the reviewed
  configuration failed both tests. Real headless Chrome emitted `media-src`
  violations for Mux and blob media and `connect-src` violations for Mux fetches.
- GREEN: the same command passes both tests. Chrome allows the Mux media/fetch
  boundary and blob media while rejecting unrelated hosts, a suffix lookalike
  (`stream.mux.com.evil.invalid`) and `evilmux.com` for media and fetches.
- The browser regression automatically runs with an installed Chrome/Chromium;
  otherwise it explicitly skips with instructions to set `ACENDRA_CSP_CHROME`.
  Static policy coverage still runs. External test hosts resolve to loopback,
  so the browser never accesses real Mux content or credentials.
- Integrated `origin/dev` at `875c8bd1da53e879a59408d3da597262b32a64bf` using
  a normal merge, without conflicts. Merge commit:
  `45b81042ff9309c40f34fb0d169446c83da1a4ad`.
- `npm run tool:test` after base integration: 801 tests, 791 passed, 10 skipped,
  0 failed. This includes all 12 deployment smoke/rollout tests and the two
  new CSP tests, including real Chrome. Existing skips require database,
  hosted, or Linux-specific verification. Local log:
  `C:/Users/ramis/AppData/Local/Temp/pr177-csp-tooling-green.log`.
- Real Nginx 1.28.0 configuration syntax verification uses the updated site
  inside a temporary HTTP context with synthetic certificate paths and local
  listen/root paths. No server is started. Test configuration:
  `C:/Users/ramis/AppData/Local/Temp/pr177-csp-nginx-LpdWCu/nginx.conf`.

Limits: these checks verify policy enforcement and configuration syntax,
not media decoding, HLS browser compatibility, live signed URL playback,
production provisioning or production deployment. No Flutter sources or
dependencies changed; required current-head Flutter CI remains a merge gate.
Root review, any remote push, required CI/review approval, merge and production
approval remain pending. The local correction is not production acceptance.
