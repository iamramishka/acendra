# Issue 171 — finderror residual repairs and integration

Owner: CODEX. Status: IN_REVIEW. Authorization: project owner requested fixes
and explicitly authorized taking over and integrating PR #165 on 2026-10-17.
Coordination: GitHub issue #171; previous owners/scopes recorded in #164 and #166.
Final branch: `fix/csa-171-pr165-final`, pinned published base `ec23fd2`.
Final worktree: `C:/Users/ramis/.codex/worktrees/finderror-pr165/acendra`.
Initial verification snapshot: `fix/csa-166-finderror-residual` at local dev
`ba0b9df`, worktree `C:/Users/ramis/.codex/worktrees/finderror-residual/acendra`.
Scope: integrate reviewed PR #165; dashboard/payment presentation and reporting
availability, marketplace enrollment/back navigation, regression tests, sanitized
bug report, responsive sign-in rows and this evidence record. No production activation or data changes.

## Integration

Applied PR #165 commits `212f0c2`, `cc089f5`, `6f000af`, `bd760cb`, `942b187`,
`378ddf9`, and `99ea281` to the task worktree. Reviewed navigation conflicts:
use the authenticated StudentShell and current-role account menu, retain the
bounded viewport used by routed screens, retain guest public navigation.
No blanket conflict resolution or edits to the original worktrees.

Initial integration from PR165 `99ea281` and published dev `80be734` excluded
the then-unpublished local theme changes. Published dev subsequently advanced to
`ec23fd2`, including those owner changes. The final integration pins and merges
that published revision, preserving the theme and auth-state provider unchanged.
Reviewed three conflicts: authenticated public navigation delegates to the
StudentShell; Admin navigation uses current role grants rather than metadata;
dashboard uses the corrected shared counts and unavailable financial state.
The incoming theme, router and marketplace changes are retained. Two bank-transfer
test fixtures supply the theme extension's new required accent fields.

The intermediate `80be734` analyzer exposed a sign-in reference to the missing
`deepNavy` token. The final published base supplies that token, so the sign-in
theme token is retained. Production-theme tests exposed horizontal overflows in
the remember/forgot, account-link and legal-link rows at mobile width. These
three rows now wrap while retaining their controls, callbacks and styling.
Tests cover 320/390/768/1440 widths in both themes; typography is instantiated
inside widget tests after binding initialization. No original worker or primary
checkout was modified.

## Corrections

- Live authorized directories replace default seeded course/student records.
- Shared title-based thumbnail covers handle missing/private artwork without
  claiming uploaded media delivery is available.
- Avatar provides Profile, Sign out and authorized Admin navigation.
- Dashboard watches current repository providers and the shared payment-count
  snapshot. Queue entries retain payment IDs, matching the Payments records.
- Removed the truncated 100-row, mixed-source payment sum. The approved
  CSA-158/172 contract requires verified settlement facts, not approved list rows
  or administrative grants. Financial totals remain unavailable pending release.
- Default payment repository fails explicitly as unavailable; synthetic fixtures
  require explicit test overrides. Missing reporting is never represented as
  zero payments or an empty financial queue. Directory counts remain available
  when only payment reporting is unavailable.
- Expected directory permission/service failures leave that metric unavailable
  without suppressing other authorized metrics or finance navigation. Unexpected
  exceptions still use the dashboard error/retry state. Reporting providers do
  not automatically retry known unavailable services behind a loading spinner.
- Payment loading skeleton scrolls within the viewport rather than overflowing.
- Dashboard errors expose a fixed public message, not raw backend diagnostics.
- Enrollment failures disable the CTA and offer retry; resolved enrollment
  continues to route using the actual course ID. Accessible back button returns
  directly to the catalog, including direct links.
- The known sandbox-fixture exclusion now applies to direct detail requests as
  well as catalog queries. This is application visibility, not a database
  publication change or authorization boundary.
- Removed plaintext login credentials from the task branch's bug report and
  corrected its unsupported inference about predictable IDs.

## Finding status

These are implementation statuses, not production acceptance or DONE claims.

| Issue | Status and remaining condition |
| --- | --- |
| 001 | Existing dashboard redirect to My Courses retained; runtime acceptance pending. |
| 002 | Authenticated marketplace uses StudentShell; account/session regressions cover navigation. |
| 003 | Directory aggregates use live authorized repositories; unsupported financial totals are unavailable. |
| 004 | Fabricated payment default removed; approved live payment-list adapter remains unavailable. |
| 005 | Known sandbox fixture excluded from both listing and detail requests; actual stored fixture/publication and deployment require environment verification. |
| 006 | Current-role Admin navigation and account menu integrated. |
| 007 | Real course title and removal of fabricated instructor retained. |
| 008 | Checkout/learning navigation retained; enrollment failure now disables CTA with retry. No payment success is inferred. |
| 009 | Declarative course navigation updates route information. |
| 010 | Accessible back control returns to marketplace for direct links. |
| 011 | Dashboard and course list use the same authorized directory repository. |
| 012 | Dashboard and student list use the same authorized directory repository. |
| 013 | Dashboard/Payments share count provider when reporting exists; default is explicitly unavailable. |
| 014 | Existing Processing tile and complete status total retained. Fixture tests opt in explicitly. |
| 015 | Fabricated default payment course names removed; live payment list is unavailable. |
| 016 | Existing payment navigation callback retained and protected by queue availability. |
| 017 | Existing Cancel callback retained and covered by editor tests. |
| 018 | Finance role/MFA requirements retained; ineligible shortcut remains hidden. No authorization bypass. |
| 019 | Marketplace header navigation retained. |
| 020 | Resilient title-based cover integrated; actual thumbnail upload/delivery remains a separate requirement. |
| 021 | Shared cover integrated in admin list/grid. |
| 022 | Admin directory queries actual authorized records; backend deployment and role-scoped visibility require hosted acceptance. |
| 023 | Seeded directory defaults and demo payment default removed; unavailable reporting does not fabricate users. |
| 024 | Profile and Sign out actions integrated with failure handling. |
| 025 | Same Admin-navigation correction as 006; duplicate report entry retained for traceability. |

## Verification

Final pinned `ec23fd2` integration: **160 existing affected cases passed** in the
combined invocation. The two new production-theme cases initially failed (test
initialization, then real mobile overflow); after fixing the test setup and the
three overflowing rows, the expanded **8-case** responsive sign-in file passed,
exit 0. These are **168 distinct passing affected cases across incremental runs**,
not a claim that the earlier failed combined invocation was green.

Final full local analyzer was stopped after over five minutes without diagnostics.
It is **incomplete**, not passed. Earlier snapshot analyzer results below are
historical evidence only. The final release build and hosted CI remain separate
checks. No analyzer result is fabricated from compiler/test success.

Final pinned release build: `flutter build web --release --no-pub
--no-wasm-dry-run`, exit 0, built `build/web` (335.6s). The existing missing
Cupertino icon-font warning remains. This is a JavaScript release build; a final
Wasm build is not claimed. Final changed-Dart formatting: **43 files**, exit 0;
whitespace checks are clean.

Final pinned tooling rerun: `npm run tool:test`, exit 0, **777 passed, 10 skipped**.
Final baseline rerun of `test/app/theme/app_theme_test.dart`,
`test/features/authentication/presentation/screens/login_screen_test.dart`, and
`test/security/csa187_malicious_text_test.dart` confirmed **13 failures**: four
old-palette assertions, six plain-theme/old-label sign-in fixture tests, three
single-text-count assertions for duplicate title/description payloads. These
existing assertions were retained. The new production-theme sign-in cases pass;
this does not turn the broader suite green. Status remains IN_REVIEW.

Intermediate `80be734` integration: the same affected command plus `test/app/theme`
passed **223 tests**, exit 0. The four palette assertions that failed in the
unpublished-theme snapshot pass on this base. `npm run tool:test` was rerun here:
**777 passed, 10 skipped**, exit 0. PR-only Dart formatting checked **40 files**
without changes, exit 0; whitespace checks are clean. Locked dependencies were
restored with `flutter pub get --enforce-lockfile`, exit 0.

Before correction, focused regressions reproduced fabricated revenue, divergent
pending counts, mismatched queue IDs, demo records as the default and enrollment
error behavior. Native BackButton test also exposed the icon-only back control;
the repaired control uses explicit catalog navigation.

Initial-snapshot affected command: `flutter test --no-pub test/features/admin
test/core/widgets/navigation/account_navigation_test.dart
test/core/widgets/cards/course_thumbnail_test.dart test/features/marketplace
test/features/authentication/presentation/providers/navigation_access_provider_test.dart
test/features/bank_transfer/presentation/bank_transfer_widget_test.dart
test/features/bank_transfer/presentation/pr132_receipt_status_integration_test.dart`:
exit 0, **160 passed**, including the loading overflow and restricted-metric
regressions on the corrected implementation. Changed Dart files: `dart format
--output=none --set-exit-if-changed` checked **41 files**, exit 0.

Initial-snapshot `flutter analyze --no-pub --no-fatal-infos`: exit 0, no errors/warnings and four
existing informational lints for local `_a`/`_b` names in untouched auth shell
and sign-in code. The flag is disclosed; this is not a claim of a clean default
analyzer invocation.

Broad verification before the final loading/directory corrections:
`flutter test --no-pub --reporter expanded`: exit 1, **704 passed, 14 failed**.
One failure exposed loading overflow in the new Payments availability regression;
the resulting viewport correction is covered by the final affected rerun.
The other failures are four palette assertions, six plain-theme sign-in tests
(the baseline LoginScreen requires a theme extension), and three literal-text
count assertions (course title and short description are the same payload).
The palette, sign-in files, course-grid description mapping and these test files
are unchanged from `ba0b9df`. No assertions were removed or weakened to hide them.

`npm run tool:test`: exit 0, **777 passed, 10 skipped**. Separate directory and
dashboard/financial-report Edge tests: exit 0, **37 passed**. Neither `psql` nor
Docker was found on PATH for a fresh database replay; imported SQL
regressions and historical PR165 evidence are not represented as fresh execution.

## Release limitations

No reporting activation, database deployment, live fixture deletion/unpublishing,
credential rotation, paid purchase or production integration is authorized by
this task. Existing reporting release gates remain binding. The original checkout
has an untracked historical report containing credentials; this task supplies a
sanitized tracked replacement in its isolated worktree. No credential validity
or production readiness is claimed.
