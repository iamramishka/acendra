# Issue 164 admin directory handoff

Owner CODEX; resumed 2026-10-17 under the project owner's parallel fixes request.
Branch `fix/csa-160-166-live-admin-data`, isolated worktree
`C:/Users/ramis/.codex/worktrees/admin-live-data/acendra`.
Scope: admin course/student repositories, safe errors in their consuming screens,
student total nullability, directory Edge adapter, additive directory migration
and regression tests. Root owns single PR integration and shared config changes.
Approval authority: project owner; status IN_REVIEW, no merge or deployment.

Existing mock directories hid the real sandbox course and replaced registered
students with generated example.com identities. Both directories now read the
current database through verified JWT/session, role and assignment checks.
Students require current super-admin and MFA; content managers see assigned
courses only. Searches and cursor pages are bounded, private thumbnail paths and
unverified financial totals are omitted. Missing totals display unavailable.
Empty results remain empty; rejected reads never fall back to seeded records.

Existing fake course/enrollment/account writes now fail with safe unavailable
messages rather than claiming success. Curriculum/enrollment detail adapters
remain unwired. Dashboard/payment mock providers are outside this bounded task.
Deploy migration and directory function together through authorized release;
the read-only directory has no additional default-off feature gate. Existing
Issue 106 release gates are unchanged. No live writes/deployment were performed.

Verification on 2026-10-17:
- Node directory handler tests: 15 passed, including verified actor forwarding,
  malformed requests, MFA/session denial, current SQL denial and private errors.
- PostgreSQL 17 disposable cluster, loopback port 58464: native Auth/Storage
  bootstrap and every sorted repository migration applied successfully; directory
  SQL regression passed. Tests cover sandbox inclusion, stored student identity,
  assignment filtering, cursor exclusion, student/manager/finance denial,
  MFA/session/revoked-role denial, and client RPC privilege denial.
- Native bootstrap models Auth/Storage tables; hosted Supabase runtime behavior
  and real deployment remain unverified.
- Initial analyzer failed because host Dart perf witness path was inaccessible;
  isolated LOCALAPPDATA retry succeeded with two formatting infos, then fixed.
- Final scoped `dart analyze lib/features/admin
  test/features/admin/admin_directory_repository_test.dart`: no issues found.
- `flutter test --no-pub
  test/features/admin/admin_directory_repository_test.dart`: four passed,
  exercising actual HTTP Supabase function requests, empty directories, stored
  student mapping, sandbox mapping, and permission/mutation failure behavior.

Root performs final integrated Flutter/Node verification and records PR evidence.
