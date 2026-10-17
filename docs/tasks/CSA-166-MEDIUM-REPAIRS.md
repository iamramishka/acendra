# Reported medium UI repairs

Owner: CODEX. Status: IN_PROGRESS. Authority: project owner request on
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
