# CSA-187/188 acceptance coordination

Owner: CODEX web security delegate; authorized by project owner parallel request 2026-10-13.
Status: IN_REVIEW (local assignment, not a GitHub claim).
Scope: tool/csa187*, tool/csa188*, this document only. No production changes.
Branch: codex/test/csa-187-188-acceptance
Worktree: C:/Users/ramis/Downloads/Acendra/csa-187-188-acceptance
Base: 8365d84; dependencies: merged CSA184-188 review, buildable Flutter web.
Root owns TASKS.md integration. Other delegates own CSA184-186 and CSA200-201.
Previous review worktree exists; no edits there. Root coordinates prior ownership.
Open PR/Issue check: default gh authentication cannot resolve private repository; root asked to complete authenticated overlap check.
Acceptance authority: project owner. Criteria: dedicated history and release asset secret scan; real browser payload evidence; effective deployed header evidence; runtime logging access/redaction/retention evidence.

## Executed evidence (2026-10-13)

Authenticated overlap check: root confirmed no open PRs; delegate listed open Issues using iamramishka auth without exposing token. No CSA-187/188 open issue or competing active claim was found. Existing review worktree retained untouched. Root's parallel board owns integration and shared registry.

### CSA-188 dedicated Git history scan

Official Gitleaks v8.30.1 Windows x64 release, verified against its release checksum:
`d29144deff3a68aa93ced33dddf84b7fdc26070add4aa0f4513094c8332afc4e`.

`gitleaks git . --redact=100 --no-banner --log-opts=--all --report-format json` exited 0; Gitleaks reports **394 commits scanned, approximately 4.22 MB, no leaks found**. This covers available local refs at execution, including task branches, rather than only current files. Merge/empty commits need not count as scanned patches. Unfetched/deleted remote refs, local ignored secrets, provider secret stores and detector unknown patterns are outside coverage. The report was fully redacted and never printed. No scanner binaries or reports are committed.

`tool/csa188_scan.ps1` repeats the all-ref or asset scan, emits finding metadata only, removes its temporary redacted report, and fails if the release JavaScript is absent. Its regression test checks missing assets, a randomly generated synthetic credential detected by Gitleaks, no credential value in output, and a clean synthetic bundle. The initial sequential synthetic token was allowlisted by Gitleaks; random credential shape resolves this detector test limitation. No actual credential was used.

### CSA-187 response policy verification tool

`node --test tool/csa187_headers.test.mjs`: **8 passed, 0 failed**. Evaluator reads actual target response headers and accepts enforced restrictive policy, rejects report-only CSP and inline scripts/object embedding gaps, rejects duplicate directive bypasses, wildcard/scheme-wide scripts, permissive base URI, malformed camera/microphone permissions and malformed HSTS, and distinguishes HTTPS from HTTP loopback. Empty script-src blocks scripts; this security-only result does not prove functionality. No header values or cookies are emitted. It follows no redirects, so a target redirect requires explicitly checking the final authorized URL.

This tool cannot prove policy compatibility with Flutter, prevent all XSS, or replace a running-browser stored/reflected payload test. There is no tracked hosting header configuration or supplied deployment URL. No deployed header result is asserted.

### Existing regression evidence

`node --test tool/auth_security.test.mjs tool/local_supabase.test.mjs supabase/functions/pdf-content/handler.test.mjs supabase/functions/_shared/pdf/authorization.test.mjs`: **86 passed, 0 failed, 0 skipped**. Coverage includes safe CLI diagnostic redaction, public environment export exclusions, PDF no-store/nosniff/CORS controls, and authorization failure sanitization. This verifies those exercised component boundaries, not managed runtime logs or hosting headers.

### Logging review

Fresh source search finds no current AppLogger call sites or direct application/Edge `print`, `debugPrint`, or `console.log/error/warn` calls outside the logger. AppLogger outputs are guarded by kDebugMode; arbitrary debug message/error/stack values are still accepted without redaction. No active source disclosure was demonstrated. Third-party SDK logging, provider log streams, access controls and retention require operational evidence. The root's delegated 30-day diagnostic log baseline in `CSA-200-RECOVERY-OPERATIONS-BASELINE.md` selects a policy, not proof that managed systems enforce it.

## Remaining acceptance evidence

- Effective approved hosted URL CSP, HSTS, nosniff, referrer, permissions and frame restrictions plus Flutter/integration compatibility.
- Running-browser stored/reflected malicious text payloads on actual course metadata/search/profile/rendering boundaries.
- Approved release configuration asset scan; a default local build does not attest to production build defines or upload contents.
- Synthetic managed log-content probes, log-reader authorization denial checks, and actual retention configuration evidence under the selected operations baseline.

Owner acceptance and final merge remain with the project owner. Source controls or policy selection alone must not change these tasks to DONE.


## Release bundle and limited browser evidence

The initial release attempt failed its WASM dry run because Windows could not create a Dart worker during memory pressure; its two exact owned Dart processes were stopped. After serialization, **one** `flutter build web --release --no-wasm-dry-run` attempt succeeded (157.4 seconds). Flutter warns about a missing CupertinoIcons font; no dependency or production code change was made. Source base: `8365d84`. Build uses default defines with no backend URL/key, rather than configured staging or production. This matters: a later build can embed different values and must be rescanned.

Fresh `tool/csa188_scan.ps1 -Mode assets` using Gitleaks v8.30.1 exited 0: **approximately 13.34 MB scanned, no leaks found**. `build/web/main.dart.js` SHA256:
`56c3ff825bc7debe1422db50601510558928e5f64c49341435d1032b18177d5a`.
The scan does not prove all privileged credential formats are detectable or attest to another build's inputs. Generated build and downloaded scanner are not committed.

The actual release was served over loopback `127.0.0.1:61210` with a minimal disposable static server. The normal login rendered. The browser navigated to an unknown route containing `<img src=x onerror=alert('CSA187')>`. The Flutter route-error display showed the encoded payload as text, no alert dialog was present, and DOM inspection found zero payload-injected images/onload SVG nodes. Screenshot: `tool/csa187_reflected_route.png`. This is a real browser reflected-route probe only; it does not cover persisted course metadata, search results, student profiles, or authenticated flows. No backend was configured and no student data was submitted.

Actual response policy probe on this bare loopback server returned HTTP200 and exit1, reporting missing CSP, nosniff, restrictive referrer and permissions headers. These are the deliberate bare local server's headers; **this is not evidence of absent deployed controls**. No headers were synthesized to manufacture a passing result. HSTS is not asserted over local HTTP.

The local server and temporary browser tab were shut down after verification. Release acceptance remains IN_REVIEW because the hosted target and managed log evidence are still absent. Follow-up commands after an authorized URL is available:

```text
node tool/csa187_headers.mjs <authorized-final-https-url>
powershell -NoProfile -File tool/csa188_scan.ps1 -GitleaksPath <verified-gitleaks-executable> -Mode assets
```

Tool verification: header evaluator8 passed; scanner regression1 passed; existing component regressions86 passed. Self review: only task-scoped tools/report/screenshot; no implementation, database, hosting, dependencies or task registry changes.
