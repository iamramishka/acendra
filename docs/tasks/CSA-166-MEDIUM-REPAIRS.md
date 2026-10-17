# Reported medium UI repairs

Owner: CODEX. Status: IN_REVIEW. Authority: project owner request on
2026-10-17 to fix the eight listed defects in parallel. Coordination: GitHub
issue #166. Base: dev ae27232. Integration branch:
`fix/csa-166-medium-integration`, isolated sibling worktree
`acendra-medium-integration`.

## Exclusive assignments

- Marketplace worker: `lib/features/marketplace/**`, `lib/app/router/**`,
  and corresponding new tests; branch `fix/csa-083-marketplace-navigation`.
- Payment worker: admin payment repository/providers/widgets/screen,
  dashboard provider and queue widget, and corresponding new tests;
  branch `fix/csa-166-payment-counts`.
- Access worker: admin dashboard screen, finance navigation eligibility,
  course editor navigation and corresponding new tests; branch
  `fix/csa-111-finance-navigation`.
- Root: integration, this evidence record and fresh combined verification.

Each writer uses its own sibling worktree. Dashboard provider and dashboard
screen have separate owners. PR #165 remains a separate directory, thumbnail
and account-navigation change; this repair must preserve compatibility with it.
No database migrations, financial state transitions, production changes,
authorization relaxations or release are in scope.

## Acceptance and verification

Course cards display the actual title; Enroll reaches the appropriate route;
course details update browser route information; detail back and Courses
navigation work, including direct detail entry; dashboard and payments agree
on pending counts; every payment status is accounted for; Cancel returns to
the course list; Finance Review navigation is unavailable to users without
the required trusted finance role and MFA.

Required evidence: focused widget/provider/router regressions, analyzer,
combined Flutter suite, self-review. Synthetic payment data must not be
represented as verified live financial records. Keep status IN_REVIEW until
required external CI/review acceptance.

## Implementation and evidence — 2026-10-17

PR: https://github.com/iamramishka/acendra/pull/169 (base dev).

| Reported behavior | Result |
| --- | --- |
| App name shown on course card | Actual course title retained; fabricated Acedra instructor text removed. |
| Enroll Now inactive | Existing callback verified through the public shell to the correct course checkout route. |
| Course detail URL unchanged | Declarative `go` replaces imperative catalog `push`; route information updates. |
| Detail back / Courses links inactive | Declarative navigation removes the pushed overlay; explicit back handles direct detail links. |
| Three pending counts disagree | Dashboard and payments share status counts and the same repository; preview badge shows total pending. |
| Status tiles omit records | Processing tile included; total and filtered loaded counts clearly distinguished. |
| Course editor Cancel inactive | Existing callback verified for new and existing drafts, including unsaved changes. No production Cancel change was necessary. |
| Finance Review blocks generic admin | Shortcut hidden unless actual current role grants include finance_admin/super_admin and JWT MFA is aal2; backend checks preserved. |

Fresh integrated verification:

- `flutter analyze --no-pub`: exit 0, no issues.
- Targeted integrated tests (marketplace navigation, payment counts, finance
  access, admin course publishing journey): exit 0, **41 passed**.
- `flutter build web --release --no-pub`: built `build/web`; Wasm dry run
  succeeded. Existing Cupertino icon-font warning remains.
- Broad Flutter run: **652 passed, 1 failed**. The sole failure was a pending
  timer from an unrelated payment dependency in the new finance visibility
  test. Isolating that dependency fixed it; all 13 finance cases and the
  complete 41-test affected set then passed. The broad suite was not rerun
  after this test-only correction; do not describe that invocation as green.
- `git diff dev --check`: clean.

The payment repository is still the pre-existing synthetic implementation,
explicitly labelled demo data. Live financial reporting, live bank review,
real browser acceptance and production deployment are not claimed. External
PR checks currently show Vercel preview success and Supabase preview skipped;
those are not substitutes for Flutter CI or authorized release review.

Handoff: all worker commits integrated, implementation scopes released to root
for PR review. No main/dev merge or production deployment performed.
