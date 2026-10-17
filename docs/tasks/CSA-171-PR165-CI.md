# PR #165 CI reconciliation

Owner: CODEX. Status: IN_REVIEW.
Authority: project owner requested review and merge into dev, then authorized
the proposed formatting/test corrections and explicitly selected the published
blue Horizon palette as the documentation/test baseline on 2026-10-17.
Coordination: issue #171; shared-file scope recorded in its follow-up comments.
Branch: `codex/fix/csa-171-pr165-ci`, pushed to PR #165's existing head without
rewriting history. Worktree: `C:/Users/ramis/Downloads/Acendra/pr165-review-20261017`.
Dependency: PR head `b888cde`; current published dev `f975598` integrated without
conflicts. No other open PR was present during the overlap check.

## Changes and independent expectations

- Five files failed the repository-wide formatter before analysis/tests could
  run. Commit `2df161f` contains only their formatting changes.
- The owner-approved Horizon primary/background values are documented in
  DESIGN_SYSTEM.md sections 6–8 and pinned as literal expectations in the four
  color tests. Runtime palette values are unchanged.
- Sign-in fixtures now supply the production theme extension and current labels.
  They scroll to the submit action before tapping at the default 800x600 test
  viewport. The password assertion checks the field's validation error, because
  its placeholder has the same text. Validation and auth-failure expectations
  remain intact.
- Malicious course metadata is expected in both title and description. Each
  text surface has its own exact assertion. Search and browser DOM checks remain.
- Four default-analyzer infos came from `_a`/`_b` callback parameters. Descriptive
  parameter names resolve them without changing callback behavior or lint rules.

## Verification

- Before correction: the three baseline files reproduced 13 failures.
- Initial corrected run: palette and malicious-text cases passed; sign-in tests
  exposed missed offscreen taps, then the duplicate hint/error-text match.
  These were diagnosed and corrected rather than suppressing test failures.
- `dart format --output=none --set-exit-if-changed lib test`: exit 0;
  271 files, zero changes.
- `flutter analyze --no-pub`: exit 0, no issues found.
- `npm run tool:test`: exit 0, 777 passed, 10 skipped.
- `flutter test --no-pub --coverage --reporter expanded`: exit 0, 727 passed.
- Hosted Flutter baseline on code revision `ee5ee18`:
  [run 39044799103](https://github.com/iamramishka/acendra/actions/runs/39044799103)
  passed locked restore, all-file formatting, default analysis, full Flutter
  coverage suite, Chrome receipt picker, release web build (including the normal
  Wasm dry run), locked npm restore, and tooling tests.
- Hosted Supabase foundations on the same revision:
  [run 39044799157](https://github.com/iamramishka/acendra/actions/runs/39044799157)
  passed migration replay, database authorization tests/lint, independent-stack
  isolation, and real MFA/role API smoke tests.
- Final documentation-head CI, supplemental Chrome checks and merge status are
  recorded in [PR #165](https://github.com/iamramishka/acendra/pull/165) and
  [issue #171](https://github.com/iamramishka/acendra/issues/171). This document
  records the completed code verification; it does not itself assert a merge.

No backend function, migration, authorization contract, financial state,
reporting activation, or deployment configuration was changed by this follow-up.
Earlier release limitations in CSA-171-FINDERROR-RESIDUAL.md remain applicable;
merging into dev does not establish production or hosted role acceptance.
