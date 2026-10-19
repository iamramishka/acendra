# CSA-268 Flutter handoff

Date: 2026-10-20 (Asia/Colombo)
Status: IN_REVIEW
Task owner: CODEX; delegated Flutter scope for GitHub issue #199.
Branch: fix/csa-268-course-flutter
Base: d46ae1c
Worktree: C:/Users/ramis/Downloads/Acendra/acendra-csa268-flutter

Implemented trusted course metadata create/update and explicit publication transitions; exact LKR minor-unit input/output through the signed bigint range; curriculum and lesson CRUD metadata controls; atomic section/lesson reordering; section-targeted lesson creation; preserved lesson section/position/publication metadata; image lesson type; safe errors and explicit retry states. Course category editing retains unavailable/inactive current categories until the user explicitly clears or changes them. Course lists and editor controls fit the tested mobile/tablet/desktop widths.

Mutations carry UUID request IDs and original raw PostgreSQL revisions. Publication, deletion and reorder commands pin the revision represented by the visible view, including across independent background reads. The editor advances a revision only after its own acknowledged write; partial-save/publication failures can be retried without recreating the course or silently accepting another author's revision. Repository lifetime follows user ID, JWT session_id and AAL; normal token refresh preserves form/retry state. True session/account changes discard prior forms and suppress stale in-flight or pre-confirmation actions.

## Fresh verification

- `flutter test --no-pub --concurrency=1 test/features/admin/admin_course_management_repository_test.dart test/features/admin/admin_course_publishing_journey_test.dart test/features/admin/admin_directory_session_test.dart test/features/admin/admin_directory_repository_test.dart`: PASS, 75 tests.
- `flutter analyze --no-pub`: PASS, no issues found.
- `dart format --output=none --set-exit-if-changed lib/features/admin lib/app/router/app_router.dart test/features/admin/admin_course_management_repository_test.dart test/features/admin/admin_course_publishing_journey_test.dart`: PASS.
- `git diff --check`: PASS.

Regression evidence includes exact fractional and bigint-boundary prices; trusted endpoint request contracts; duplicate in-flight prevention; idempotency-preserving ambiguous retries; stale original/visible revisions despite newer reads; publication failure followed by metadata edit; same-session token refresh; account switches during save and open delete confirmation; inactive/missing categories; immediate error/Retry rendering; correct section/position when creating or editing lessons; six editor layout cases (390/768/1440, light/dark), and mobile/desktop list price rendering.

## Integration and remaining gates

The coordinated backend implementation belongs to the root CODEX task and is not copied into this branch. The only shared routing change passes the `section_id` query parameter into LessonEditorScreen. Publication always uses the existing admin-publish-course endpoint. No direct table mutation, secret, deployment, push or production operation is included.

Course deletion remains unavailable pending the project owner's retention/deletion decision. This branch does not invent physical deletion or archival policy. Protected lesson body/media delivery remains outside this metadata change. Root integration owns the final combined Flutter suite, release web build, backend checks, review and PR. Hosted acceptance and release approval have not been performed in this child worktree.
