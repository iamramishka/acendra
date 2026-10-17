# CSA-DASH-001 Phase 6 verification

Owner CODEX; IN_REVIEW. Authorized by project owner on 2026-10-18.
Issue #173; PR #174; branch feat/csa-dash-001-student-home.
Worktree: C:/Users/ramis/.codex/worktrees/student-home-phase1/acendra.
Scope: final dashboard verification, confirmed related regressions/tests, local
offline QA harness, task-specific evidence and bounded TASKS.md reconciliation.
No conflicting owner found; no delegation, merge or production changes.

Acceptance: formatting, full analysis/test suite, standard release web build,
Chrome router/guard checks, theme/viewport inspection and interaction checklist.
Saved acceptance means its explicit coming-soon route works; saving itself is
not implemented. Live featured courses/filter identities remain future work.

The separate tool/dashboard_preview.dart entry point uses synthetic repositories
and test-only identity overrides for local visual review. It is not imported by
lib/main.dart or used by deployment workflows. Build it to build/dashboard-qa
and serve only on loopback; tool/dashboard_preview.html provides fixed-width
390/768/1440 iframe viewports and light/dark selection. It is not evidence of
live authentication, payment, entitlement or production acceptance.

Temporary CI ownership was recorded in issue #173 before editing the existing
Chrome step. It now includes receipt tests and the real student router tests.
The browser harness uses the production theme extension. Four previously
unexecuted legacy checks looked for `Sign in` while the current button says
`Sign In`; they now assert LoginScreen and the exact /login URL. No application
guard or authorization behavior was changed.

## Verification evidence

- Local baseline formatting: 291 lib/test files unchanged; full analysis passed.
  Preview entry-point analysis and Node server syntax check also passed.
- Hosted application head b95c38b: [run 39062578825](https://github.com/iamramishka/acendra/actions/runs/39062578825)
  passed all 783 Flutter tests with coverage, three receipt Chrome tests,
  standard release web build including Wasm dry run, and tooling checks.
- Local duplicate full-suite run and standard build were interrupted after the
  complete hosted success to release resources; neither is claimed as a local
  pass. The separate offline preview release build passed with no Wasm dry run.
- The first expanded browser gate executed all 17 checks: 13 passed, including
  new Home/Saved guard and real-tab tests; the four legacy copy checks above
  failed. Their corrected route/screen assertions remain enforced, not skipped.
  The final gated result is recorded in [PR #174 checks](https://github.com/iamramishka/acendra/pull/174/checks)
  and [issue #173](https://github.com/iamramishka/acendra/issues/173).
- Browser visual review: 390/768/1440 CSS-pixel iframe viewports in both themes;
  one/two/three-column course layouts, category scrolling, readable hero and
  prices, lower highlights, and fixed mobile navigation inspected. No visible
  overflow found. Wider screenshots are scaled to fit the review window; iframe
  layout widths remain the selected values. [Screenshot index](../reviews/CSA-DASH-001-PHASE6/README.md).
- Real-router offline browser interactions: Home, My Learning, Saved and Profile
  selected their correct routes; Saved explicitly reports coming soon. AppBar
  search opened /marketplace?search=true with focused input; entering Design
  filtered the synthetic catalog. Featured View All opened /marketplace.
- Existing dashboard tests cover loading/error/retry/empty states, 200% text,
  intermediate widths, keyboard activation, carousel three-second advance,
  selected dots, pause/reduced motion, background resume and timer disposal.
  Source review confirmed CourseSummary.formattedPrice and centralized copy;
  dashboard widgets introduce no raw priceMinor display or literal Color values.

The build retains the baseline missing Cupertino font-family warning; all icons
inspected here use the existing Material icon asset. No dependency change made.

## Reproduce the offline visual review

```powershell
flutter build web --release --no-pub --no-wasm-dry-run --target tool/dashboard_preview.dart --output build/dashboard-qa
Copy-Item tool/dashboard_preview.html build/dashboard-qa/qa.html
node tool/serve_dashboard_preview.mjs
```

Open the printed loopback URL; choose width/theme and Apply. The server reads
only build/dashboard-qa, uses no external packages, and is not a deployment.
The normal release command remains `flutter build web --release --no-pub`.

Implementation and verification handoff: no production or backend changes;
sample content/live-data limits remain explicit. Temporary shared ownership is
released for review. Owner retains final acceptance, merge and release authority.
