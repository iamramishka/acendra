# CSA-274: course-details browser acceptance

Date: 2026-10-31, Asia/Colombo. Owner: CODEX. Status: IN_REVIEW.
Issue: [#211](https://github.com/iamramishka/acendra/issues/211).
Branch: `test/csa-274-browser-acceptance`; current base: `5fb7bb9` from dev.
Isolated workspace: `C:/Users/ramis/.codex/worktrees/csa274-browser-acceptance/acendra`.

## Problem and scope

The course-detail repair in [PR #212](https://github.com/iamramishka/acendra/pull/212)
is merged and present in current dev. Its issue still records failed historical
CI and missing browser acceptance. The later seven repository-driven acceptance
tests run in the native suite, but the required Chrome command omitted them and
the existing course-detail/navigation suites.

Add those three existing suites to the existing required Chrome step. Preserve
all test assertions, the existing browser suites, failure behavior and ten-minute
step deadline. Only the workflow, this record and a continuation link in the
original CSA-274 record change. No application, test fixture, backend, dependency,
authentication, payment or live data implementation changes are needed.

Issue #211 records temporary ownership of this Chrome command. PR #244's
separate Settings repair merged during verification; this branch synchronized
after the local browser attempt stopped. Its source and task ownership were
preserved. Original task worktrees remain untouched.

## Coverage

| Existing suite | Checks added to Chrome execution |
| --- | --- |
| `catalog_course_acceptance_test.dart` | Pending orders route using returned identity; created/pending-payment/pending-verification states block another purchase; unknown/error states fail closed and retry re-reads; re-entry refreshes order state; search/category/back and repository refresh/cold initialization. |
| `course_detail_navigation_test.dart` | Owned/unowned action identity, pending enrollment and failed enrollment with retry. |
| `presentation/course_detail_screen_test.dart` | Sticky price/action footer, curriculum locks/previews/durations, loading/error Back from Home/My Courses, safe errors and 390/768/1440 light/dark layout. |

The order suite uses existing synthetic repository injection and the real
production screen/providers. No hosted orders, payments, enrollments or course
fixtures are created. Its cold-reload test creates fresh router/provider state;
it does not simulate a physical F5 or establish hosting rewrites.

## Verification and evidence limits

- Locked dependency restoration passed.
- Native execution passed all 32 distinct tests, zero skips: seven repository
  acceptance cases, then 25 course-detail/navigation cases. No new failing
  runtime behavior was found, and no production widget was modified.
- The local Chrome attempt stalled at bundle loading before any assertions,
  matching the limitation recorded by CSA-284. The bounded attempt was stopped;
  it is not counted as a browser pass. Hosted Chrome is the remaining gate.
- `git diff --check` and relative task-link checks passed. Hosted full CI and
  independent review must pass before integration; final results are recorded
  against the immutable PR head in issue #211.

Separate deployed browser evidence is recorded in
[CSA-285](CSA-285-LIVE-NAVIGATION.md): actual course metadata, physical course
reload, fresh-tab direct entry, fallback Back and catalog search/category
behavior passed on the selected SSH deployment. This continuation relies on
that shared dated evidence rather than claiming a new private-session test.
Vercel is excluded from deployment testing.

Browser UI tests with synthetic order responses do not prove live settlement,
payment-provider behavior or entitlement authorization. Those remain governed
by the trusted backend and their separate acceptance requirements. No live
purchase or protected media acceptance is claimed here.
