# CSA-187/188 hosted acceptance assignment

Owner: CODEX web acceptance delegate; integration owner: root CODEX.
Authorization: project owner parallel Phase 8 request, 2026-10-14.
Status: IN_REVIEW; local coordination assignment, not a GitHub claim.
Branch: codex/test/csa-187-188-hosted-security.
Worktree: C:/Users/ramis/.codex/worktrees/phase8-web-acceptance/acendra.
Base: origin/dev e7a1cdc.
Scope: new tool/csa188_hosted_scan.mjs and this board only.
Restricted: shared workflows, registry, dependencies, existing agent files.
Dependencies: existing browser acceptance suite; hosted release build; actual Gitleaks binary provisioned by root workflow.
Overlap: root reports no open PRs; prior review worktrees retained untouched; root board assigns this bounded scope.
Authority: project owner accepts operational controls; root integrates and opens PR.
Criteria: hosted scan fails on missing release bundle/scanner and scanner findings; all scanner output suppressed to avoid disclosure; no local tests by user instruction.

## Prepared hosted gate

`tool/csa188_hosted_scan.mjs` runs on Node 22/Linux and Windows without PowerShell. It checks that the scanner exists and that asset mode has a real `build/web/main.dart.js`, runs Gitleaks with full redaction, suppresses all scanner streams, and fails on scanner startup errors, interruption, timeout or nonzero exit. Successful asset output records the JavaScript SHA256 without exposing bundle contents. No scanner report is created or uploaded.

Root workflow wiring (root owns shared workflow changes): provision an official checksum-verified Gitleaks executable; fetch full Git history (`fetch-depth: 0`) for the history stage; run after release build:

```text
node tool/csa188_hosted_scan.mjs history /absolute/path/to/verified/gitleaks
node tool/csa188_hosted_scan.mjs assets /absolute/path/to/verified/gitleaks
```

Existing hosted `npm run tool:test` already invokes the six Chrome malicious course/profile cases through `tool/csa187_browser.test.mjs`; do not add a duplicate browser runner. These use synthetic providers and do not prove authenticated persistence.

Once an authorized staging URL exists, run `node tool/csa187_headers.mjs <authorized-final-https-url>` against its actual response. No dummy response or optional skipped test was added to imply deployed acceptance. No hosting provider/header configuration exists in scope.

## Verification limits and remaining acceptance

No local tests or browser/build execution occurred, respecting the user request. `git diff --check` is the only local change hygiene check. New scanner execution is pending hosted CI; no passing scanner result is claimed for this commit. Root must record actual CI URL/results after integration.

CSA-187 remains IN_REVIEW pending actual deployed response policy, authenticated stored payload journeys and policy compatibility. CSA-188 remains IN_REVIEW pending approved configured release bundle scan plus real managed log redaction probes, denied unauthorized log access and retention configuration evidence. A clean default hosted build does not establish these operational controls. No managed logging provider or credentials were supplied, so no policy JSON or synthetic service was presented as actual control evidence.
