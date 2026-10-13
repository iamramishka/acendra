# PR 134 review remediation

PR134 now includes My Courses, the learning workspace/curriculum, text/image
viewer components and continue-learning UI. The original route-only description
did not describe that implementation. Review found invalid database columns,
incompatible bank route constants and stale async lesson results.

The remediation uses explicitly granted lesson metadata columns and removes the
invented thumbnail URL query. Missing protected text/image delivery shows an
unavailable state with lesson navigation; thumbnail cards use their placeholder.
Existing bank status/resubmission URLs are preserved. A monotonically increasing
request identity prevents both old content and old errors overwriting a newer
lesson selection. Dev's temporary missing-feature routes now use the included
screens, with explicit loading/error/unauthenticated regression coverage.

Owner: CODEX, assigned by project owner in chat on 2026-10-13 to fix the review findings.
Status: IN_REVIEW; approval authority: project owner/maintainer.
Branch: codex/fix/csa-129-pr134-review
Worktree: C:/Users/ramis/Downloads/Acendra/review-pr134
Base: PR134 head 840286e plus dev 734413b. PR134 remains owned by CLAUDE;
this separate remediation branch contains the authorized bounded collaboration.
Open Issues, PRs and worktrees checked; no competing remediation task found.
Temporary scope: learning/my_courses repositories and DTOs, learning notifier and
unavailable-content UI, route_names.dart reconciliation, focused regression tests,
this record. Existing bank/finance implementations are preserved from dev.
Issue: https://github.com/iamramishka/acendra/issues/136
Additional integration scope: existing router guard tests updated for the real
screens using explicit unavailable repositories, and mechanical Dart formatting
in lib/test to unblock the inherited formatting failure. No behavior changes to
bank/checkout/shared UI from those formatting edits.
Temporary shared router ownership: connect the included My Courses/learning
screens in app_router.dart, replacing dev's missing-dependency placeholders.
Dependencies: CSA078/079 metadata schema, CSA095 own enrollment projection,
CSA165 publication contract. Protected text/image delivery does not exist yet;
no public content columns or storage URL access will be invented.
Verification: meaningful RED/GREEN query, route and out-of-order response tests;
format, analyzer, Flutter tests and release web build. Production configuration,
migrations, protected delivery implementation and merge remain outside scope.

Verification so far: five query/selection regression tests failed before the
correction and passed afterwards. All 52 focused router/learning/My Courses tests
pass, including metadata-only unavailable text/image display and login redirects.
Query tests exercise actual Supabase/PostgREST HTTP serialization against a
synthetic local HTTP fixture, not a live database or production content service.
Final local checks on 2026-10-13:
- `dart format --output=none --set-exit-if-changed lib test`: 164 files, zero changes.
- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: all 330 tests passed.
- `git diff --check`: passed.
- `flutter build web --release --no-pub`: passed, output `build/web`.

The owner-authorized bounded remediation is handed back through a fast-forward
update of PR134 after verification, preserving CLAUDE's commits. The separate
local fix branch/worktree remains the CODEX workspace. No merge into dev or
production deployment is authorized by this remediation. No backend/migration
changes require database replay; live protected text/image/thumbnail delivery
and real hosted database integration remain unverified and unavailable here.
