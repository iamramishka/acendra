# CSA-160: server security policy and deployment verification

Date: 2026-10-31, Asia/Colombo. Owner: CODEX. Status: IN_REVIEW.
Coordination: [issue #160](https://github.com/iamramishka/acendra/issues/160).
Branch: `fix/csa-160-server-security`. Base: `c4119b3` from `origin/dev`.
Isolated workspace: `C:/Users/ramis/.codex/worktrees/csa160-server-security/acendra`.

## Scope and behavior

The owner selected the existing server at `http://3.25.99.105/` for deployment
testing and removed Vercel from that scope. The server redirects HTTP requests
to its existing certificate hostname, `https://3-25-99-105.sslip.io/`.
Vercel's Git connection was disconnected separately; this patch adds no Vercel
checks, account changes or hosted services.

The existing live Nginx policy failed the repository header checker: it omitted
`object-src` and `base-uri`, and allowed inline JavaScript and general JavaScript
eval. This patch sets `object-src 'none'`, restricts base URLs to the same origin,
and removes those two script execution permissions. WASM compilation, same-origin
modules, the existing CanvasKit path, scoped Mux media and blob workers remain
allowed. Inline CSS support is retained for Flutter layout.

The deployment workflow now runs the existing full header checker against the
same SSH server after rollout. Its HTTP redirect smoke check starts from the
owner's IP address. Existing release approval, Nginx validation/rollback, SSH key
handling, artifact scanning and required Flutter CI remain in place.

Writable scope is limited to `server/nginx.conf`, the deployment workflow,
`tool/deployment_csp.test.mjs`, and this record. The issue records temporary
workflow ownership. No dependencies, application code, backend settings,
financial contracts, credentials or production data changed.

## Verification

- RED: a new test applied the real header checker to Nginx source headers and
  failed with the same five findings as the live response.
- GREEN: 25 focused tests passed with no skips across `deployment_csp`,
  `csa187_headers`, and `deployment_smoke`. A real Chrome fixture verified that
  external scripts and WASM compilation work, inline scripts and JavaScript eval
  are blocked, Mux/blob media remain permitted, and unrelated media/fetches fail.
  Mux destinations resolve to loopback in the fixture; it tests browser policy
  enforcement without fetching private media or proving real HLS playback.
- Locked dependency restoration and `flutter build web --release --no-pub`
  succeeded, including the WASM dry run. The existing Cupertino font warning was
  reported; no dependency change was made.
- The generated release was served on an automatically assigned loopback port
  with the exact candidate Nginx CSP. A fresh real browser rendered the Acedra
  sign-in screen, with no captured warning/error logs. This development build
  contained no hosted backend configuration. No credentials were entered; real
  sign-in, payment, protected PDF/video and backend acceptance are not claimed.
- `git diff --check` passed. Required hosted PR checks and review remain gates;
  their final results belong in the linked PR and issue.

## Integration and operational limits

The live server was not changed during local verification. After approval and
merge, the existing deployment environment approval must permit the reviewed
release. Re-run the header checker against the server and verify startup after
that rollout. A workflow failure must remain visible; do not relax the checker
or bypass review to obtain a pass. The real server performs `nginx -t` before
switching releases; no local Nginx configuration-parser result is claimed.

This fixes the reproducible CSP source defect. Production backend isolation,
live finance/notifications, complete encrypted backups, independent key recovery,
managed restoration, responders and release acceptance remain separate issue
#160 prerequisites. A successful source merge or deployment smoke test cannot
establish those capabilities.
