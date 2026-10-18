# CSA-SANDBOX-SEED-CLEANUP — Sandbox course and placeholder seed data

Status: PROPOSED — IN_REVIEW. Nothing in this package has been executed
against any database. Maker: CLAUDE. Checker: a human reviewer (a Claude
subagent is not an independent checker; AGENTS.md §43, CLAUDE.md §18).

Closes the data-level residue of `finderror.md` issues 005, 022 and 023
(see `docs/tasks/CSA-171-FINDERROR-RESIDUAL.md`, row 005).

## 1. Scope

| Finding | Residue | Action in this runbook |
| --- | --- | --- |
| 005 / 022 | Course `SANDBOX TEST ONLY - Checkout Verification` still exists in the hosted DB; the app only hides it (`lib/features/marketplace/data/repositories/supabase_course_repository.dart` filters `title not ilike 'SANDBOX TEST%'` for listing and detail). | **Archive** the course (`status = 'archived'`). Do not delete. |
| 023 | Placeholder `@example.com` students, orders and payments (`alice/bob/carol/david@example.com`, `student1-3@example.com`, orders like `ORD-2026-0001`). | **Report only** in SQL. Account removal is a separate owner decision, only for accounts with zero dependent rows. |

Out of scope: any change to `supabase/migrations`, app code, payment logic,
PayHere sandbox configuration, or the local seed `supabase/seed.sql` (its
fixtures use `08100000-…` ids and the title prefix `Synthetic`, and are
explicitly local-only).

## 2. Why archive instead of delete

* `orders.course_id`, `enrollments.course_id`, `enrollment_grants`, `course_staff`
  and `access_restrictions` reference `courses` with `ON DELETE RESTRICT`.
  A sandbox checkout created real pending orders and payment attempts
  (`docs/reviews/CSA-178-SANDBOX-STAGING-BOARD.md`), so a hard delete fails
  or, if forced by removing children first, destroys financial history.
* Orders, payment attempts, verified settlements, payment events and
  `app_private.audit_logs` are immutable by trigger; AGENTS.md §31/§34 forbid
  deleting financial audit history without approval. Order snapshots
  (`course_title_snapshot`) must stay joinable to a course row.
* Bank receipts and course media are in private storage; their objects are
  never touched.
* `status = 'archived'` is already permitted by `courses.status` check, is not
  matched by the app's `status = 'published'` filter and by publication RLS, and
  is reversible (set back to `draft`, then publish through the CSA-165 RPC).
* Archiving makes the app's title filter defence-in-depth rather than the only
  barrier. Keep the filter.

## 3. Roles, approvals and who may execute

| Gate | Who |
| --- | --- |
| Approve running on the hosted environment, and name the target (project ref / DB name) | Project owner (written, in the tracking GitHub Issue) |
| Independent review of this runbook, SQL and the dry-run output | A second reviewer who is not the maker (human; project owner or designated maintainer) |
| Execute (psql with privileged connection) | Authorized maintainer holding the DB credential. Agents must not hold or use it. |
| Decide per-account fate of `@example.com` users | Project owner |

Do not run against production without the approval above. Staging first if a
staging project exists; the approval must name which environment(s).

## 4. Preconditions (all must be true)

1. Written owner approval recorded in the GitHub Issue, naming environment.
2. Second reviewer has read this file and the SQL and approved in the Issue.
3. A fresh backup/restore point exists and is recorded: Supabase PITR or a
   `pg_dump` of at least `public`, `app_private` and `auth.users` ids
   (see `docs/operations/CSA-214-BACKUPS.md` and `CSA-216-RECOVERY-RUNBOOK.md`).
4. No payment/enrollment migration or release is in flight (AGENTS.md §16, §21).
5. `psql` is available, and the connection string comes from the maintainer's
   secret store, never from the repo or chat.
6. Executor confirms the app build in that environment already contains the
   sandbox filter (so archiving cannot expose anything).

## 5. Steps

1. **Backup.** Take and record the restore point (precondition 3).
2. **Dry run (read-only).**
   ```bash
   psql "$TARGET_DB_URL" -v ON_ERROR_STOP=1 -v mode=dryrun \
     -f docs/runbooks/sql/CSA-SANDBOX-SEED-CLEANUP.sql | tee dryrun-$(date +%F).txt
   ```
   It lists the sandbox course(s), every referencing order/attempt/enrollment/
   bank submission, storage objects, `@example.com` accounts and a full FK
   dependency sweep. Part 1 runs in a `READ ONLY` transaction.
3. **Review the output with the second reviewer.** Confirm: exactly one
   exact-title course; its id; every other row matched by `ilike 'SANDBOX TEST%'`
   is understood; the database name in 1.7 is the approved one.
4. **Rehearsal (no commit).** Re-run with `mode=apply`, the course id,
   `confirm=ARCHIVE-SANDBOX-<id>` and `expected_db=<name>` but **without**
   `do_commit`. The script asserts, then rolls back:
   ```bash
   psql "$TARGET_DB_URL" -v ON_ERROR_STOP=1 -v mode=apply \
     -v sandbox_course_id=<uuid> -v confirm=ARCHIVE-SANDBOX-<uuid> \
     -v expected_db=<db name> -f docs/runbooks/sql/CSA-SANDBOX-SEED-CLEANUP.sql
   ```
5. **Apply.** Same command plus `-v do_commit=yes`. Idempotent: if the course
   is already archived it changes nothing and writes no audit row.
6. **Verify** (section 6) and record evidence (section 8).
7. **`@example.com` accounts (finding 023), owner decision per account.**
   Use dry-run sections 1.5/1.6.
   * Any account with orders, enrollments, bank submissions, role rows or any
     non-zero row in 1.6 **stays**. Do not delete financial or audit history. If
     it must not be usable, the owner may disable sign-in via the Auth Admin API
     (ban) and rotate nothing else.
   * Accounts with zero dependents in 1.6 may be removed by the owner through
     the Supabase Auth Admin API or dashboard (not by SQL against `auth.users`).
     `profiles.id → auth.users` is `ON DELETE RESTRICT`, so remove the profile
     only via the supported admin flow; if that fails with an FK error, the
     account has dependents — stop and keep it.
   * This script deliberately contains no statement for this step.
8. **Close out.** Update the Issue and, via the TASKS.md owner, finding status.

## 6. Verification queries (read-only)

```sql
-- Sandbox course is archived, exactly one, and still referenced by its orders.
select id, title, status from public.courses where title ilike 'SANDBOX TEST%';
select count(*) from public.orders o join public.courses c on c.id=o.course_id
 where c.title='SANDBOX TEST ONLY - Checkout Verification';  -- unchanged vs dry run

-- Nothing public: anon-visible published courses contain no sandbox title.
select count(*) from public.courses
 where status='published' and title ilike 'SANDBOX TEST%';   -- expect 0

-- Audit trail of the action (append-only).
select created_at, action, resource_id, outcome from app_private.audit_logs
 where action='runbook.sandbox_course_archived';              -- expect 1 row
```

App check on the deployed site: sandbox course absent from the marketplace and
direct `/courses/<id>` returns not-found (as an anonymous and a student user);
an authorized admin can still see it in the admin directory (CSA-164) as
archived. Counts of orders, attempts, enrollments, bank submissions and
storage objects equal the dry-run counts.

## 7. Rollback / recovery

* Before commit: omit `do_commit` (rollback is the default), or any failed
  assertion rolls the whole transaction back.
* After commit: the only data change is one `courses.status` value plus one
  append-only audit row. Revert with
  `update public.courses set status='draft' where id='<uuid>' and status='archived';`
  (then publish via the CSA-165 RPC if ever needed). The audit row stays by
  design; record the revert in the Issue.
* Catastrophic or unexpected state: restore from the recorded restore point per
  `CSA-216-RECOVERY-RUNBOOK.md`. Never reset production data.
* Account removals (step 7) are not reversible by this runbook; hence the
  zero-dependents rule and the pre-change backup.

## 8. Evidence to record in the GitHub Issue

* Owner approval link and second-reviewer approval (names, timestamps).
* Environment name and DB name; backup/restore-point identifier.
* Dry-run output file (redact user emails if the Issue is public).
* Rehearsal output and final apply output (including the `NOTICE` line with
  unchanged counts) and `COMMITTED.` line.
* Results of the section 6 queries and the app check.
* Per-account decisions for step 7 and who executed them.
* Never paste connection strings, tokens or full emails of real users.

## 9. Known limitations / open items

* The sandbox course id is not recorded anywhere in the repo; the SQL finds it
  by exact title and requires the executor to supply and confirm the id.
* The SQL was reviewed statically against `supabase/migrations`; it has **not**
  been executed on any database (no hosted access by design). The checker
  should rehearse it on a throwaway local Supabase database first.
* If the hosted DB is missing a table referenced in dry-run section 1 (schema
  drift), `ON_ERROR_STOP` aborts before any write; Part 1 is read-only.
* Archiving does not remove the course from admin views by design.
* App-side sandbox exclusion is covered by
  `test/features/marketplace/data/sandbox_course_visibility_test.dart` (direct
  detail) and `sandbox_course_listing_test.dart` (catalog query filter). These
  prove the client request shape only; the filter is not an authorization
  boundary, which is why the course is also archived in the database.
