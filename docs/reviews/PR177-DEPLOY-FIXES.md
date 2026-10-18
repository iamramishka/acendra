# PR #177 deployment review fixes

Task: Audit-004 / PR #177. Owner: CODEX for the bounded review corrections,
authorized by the project owner's request to fix the findings and merge into
`dev`. Original implementation owner: CLAUDE. Dependencies: PR #176 and
existing production provisioning. Scope: `server/nginx.conf`, the deployment
workflow smoke test, its tooling regression tests, and this review record.
Worktree: `C:/Users/ramis/.codex/worktrees/pr177-deploy-fixes/acendra`.
Target branch: `fix/csa-audit-004-https-headers`. Approval authority: project owner.

## Changes

- Give Nginx one CSP argument so the configuration passes `nginx -t`.
- Allow the default Flutter loader's CanvasKit CDN for scripts and WASM
  fetches, plus font fetches from Google Fonts. The existing generated
  `flutter_bootstrap.js` confirms the CanvasKit CDN dependency.
- Replace header-count pipelines with explicit conditional checks, allowing
  a healthy response to pass under `bash -e -o pipefail` and preserving
  diagnostics for missing headers and exposed server versions.
- Revalidate Flutter code and assets instead of caching reused filenames
  as immutable for one year. Security headers now inherit on asset responses.

## Evidence

- RED: the new workflow-script tests reproduced six failures against the
  original implementation, including the healthy-response failure.
- GREEN: `node --test tool/deployment_smoke.test.mjs`: 7 passed. Covers
  healthy headers, each missing required header, version disclosure,
  missing HTTP redirect, and unavailable HTTPS. Network calls are mocked.
- `npm run tool:test`: 794 tests, 784 passed, 0 failed, 10 skipped.
  The existing skipped tests require a database or hosted target.
- Real Nginx 1.28.0 with a temporary local self-signed certificate:
  original config fails with `invalid number of arguments in add_header`;
  corrected config passes. Only certificate paths, site root and local
  listen addresses were substituted for this check.
- Local HTTP/HTTPS requests verify HTTP redirect, `Cache-Control: no-cache`
  and CSP on `main.dart.js`, `flutter_bootstrap.js`, and
  `flutter_service_worker.js`; replacing `main.dart.js` serves the new bytes.
- `git diff --check`: passed.

## Gap

Docker is not running locally. Production certificate provisioning and
end-to-end HTTPS smoke testing remain owner-run operations; no production
server or GitHub environment approval was changed. The local certificate
is synthetic and does not verify the production certificate or hostname.
Flutter checks are delegated to the required PR CI, because application
source and dependencies are unchanged. This record is implementation and
self-review evidence, not an independent human approval.

## Criteria

- [x] CSP parses with real Nginx.
- [x] Healthy responses pass and negative responses fail with diagnostics.
- [x] Unversioned Flutter assets revalidate across releases.
- [ ] Required current-head CI and merge review gates pass.
- [ ] Production owner provisions and verifies HTTPS before approving deployment.

Status: IN_REVIEW until required GitHub gates and merge complete.
