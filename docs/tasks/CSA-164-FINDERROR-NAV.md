# CSA-164 account navigation remediation

Owner: CODEX navigation worker. Issue: https://github.com/iamramishka/acendra/issues/164.
Status: IN_REVIEW. Base: dev ae272329.
Branch: fix/csa-024-025-account-navigation.
Worktree: C:/Users/ramis/.codex/worktrees/account-navigation/acendra.
Scope: navigation shells/account menu, new read-only navigation role provider, focused tests.
Temporary shared ownership: lib/core/widgets/navigation/**, assigned by integration owner.
Dependencies: existing CSA-061 current-role projection, auth/profile/logout providers.
Approval authority: project owner; root worker integrates completed commits for review.
Acceptance: avatar opens accessible profile/logout menu, privileged staff have Admin navigation,
regular/anonymous users do not; authenticated marketplace retains account navigation.
Verification: role-provider fail-closed tests, navigation interactions at desktop/mobile widths,
light/dark themes, focused navigation regression tests and static analysis.
Backend authorization, MFA and RLS remain authoritative and unchanged.

Completion evidence (2026-10-17):
- Avatar opens Profile, role-gated Admin and Sign out actions; logout errors retain the route and show a retry message.
- Authenticated public pages retain account navigation; anonymous navigation remains available.
- Current-user RLS role lookup controls visibility only; metadata roles are ignored.
- flutter test test/core/widgets/navigation test/features/authentication/presentation/providers/navigation_access_provider_test.dart: PASS, 38 tests.
- Scoped flutter analyze over navigation code, role provider and added tests: PASS, no issues.
- dart format --output=none --set-exit-if-changed over all six Dart changes: PASS, no changes.
- Pending: root integration, combined checks and PR review. No deployment or merge performed.


Scope addendum (root assignment, 2026-10-17): CODEX navigation owns session-bound invalidation for admin course/student repository and list/detail/curriculum/lesson providers plus focused account-switch/in-flight regression tests. Dependency: d5ac8d6f directory implementation, cherry-picked locally as 040f639. Root integrates only new follow-up commit. Status: IN_PROGRESS. Required: clear prior-session directory data and prevent old asynchronous search results restoring PII after auth changes. No backend contract, deployment or financial changes.

Session-bound directory follow-up evidence: 30 focused tests passed (session regression, directory repository and course publishing journey suites). New regressions cover logout/account switch for cached students/details/courses and late initial-load/search/refresh completion after account switch. Scoped analysis passed, no issues. Status: IN_REVIEW; root integration pending.
