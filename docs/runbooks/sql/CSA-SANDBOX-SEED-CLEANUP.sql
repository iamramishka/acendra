-- CSA-SANDBOX-SEED-CLEANUP (finderror 005/022/023)
-- NOT a migration. NOT auto-applied. Never run without the approvals in
-- docs/runbooks/CSA-SANDBOX-SEED-CLEANUP.md. Requires psql (uses \if, \gset
-- and :'var' interpolation); it will not work in the Supabase SQL editor.
--
--   Part 1  DRY RUN : read-only; always runs first. Lists every row in scope.
--   Part 2  APPLY   : one transaction; fails closed unless fully confirmed;
--                     ROLLS BACK by default, commits only with do_commit=yes.
--
-- Design rules enforced here:
--   * No DELETE/TRUNCATE of any row. Financial, enrollment, audit and storage
--     evidence is never removed (orders, payment_attempts, enrollments and
--     bank submissions reference courses/profiles ON DELETE RESTRICT, and
--     app_private.audit_logs is append-only).
--   * The sandbox course is ARCHIVED (status = 'archived'), not deleted.
--   * @example.com accounts are REPORTED only. Removing auth users is an owner
--     decision done through the Supabase Auth Admin API/dashboard, and only for
--     accounts Part 1 shows have zero dependent rows.
--
-- Dry run:
--   psql "$TARGET_DB_URL" -v ON_ERROR_STOP=1 -v mode=dryrun \
--        -f docs/runbooks/sql/CSA-SANDBOX-SEED-CLEANUP.sql
-- Apply rehearsal (asserts everything, then rolls back):
--   psql "$TARGET_DB_URL" -v ON_ERROR_STOP=1 -v mode=apply \
--        -v sandbox_course_id=<uuid from dry run> \
--        -v confirm=ARCHIVE-SANDBOX-<same uuid> \
--        -v expected_db=<approved database name> \
--        -f docs/runbooks/sql/CSA-SANDBOX-SEED-CLEANUP.sql
-- Apply for real: add -v do_commit=yes to the rehearsal command.

\set ON_ERROR_STOP on
\if :{?mode}
\else
  \echo 'ERROR: pass -v mode=dryrun or -v mode=apply. Nothing was run.'
  \quit
\endif

-- ======================================================================
-- PART 1: DRY RUN (read-only). Runs in every mode.
-- ======================================================================
begin read only;

\echo '== 1.1 Sandbox course candidates (exact title, plus the ilike pattern the app filters on) =='
select id, slug, title, status, published_at, price_minor, created_at,
       (title = 'SANDBOX TEST ONLY - Checkout Verification') as exact_title_match
  from public.courses
 where title ilike 'SANDBOX TEST%'
 order by exact_title_match desc, created_at;

\echo '== 1.2 Rows referencing those courses (counts; ALL would be PRESERVED) =='
with c as (select id from public.courses where title ilike 'SANDBOX TEST%')
select 'orders' as tbl, count(*) as n from public.orders o join c on c.id = o.course_id
union all select 'payment_attempts', count(*) from public.payment_attempts pa
  join public.orders o on o.id = pa.order_id join c on c.id = o.course_id
union all select 'enrollments', count(*) from public.enrollments e join c on c.id = e.course_id
union all select 'enrollment_grants', count(*) from public.enrollment_grants g join c on c.id = g.course_id
union all select 'bank_transfer_submissions', count(*) from public.bank_transfer_submissions b
  join public.orders o on o.id = b.order_id join c on c.id = o.course_id
union all select 'course_sections', count(*) from public.course_sections s join c on c.id = s.course_id
union all select 'lessons', count(*) from public.lessons l
  join public.course_sections s on s.id = l.section_id join c on c.id = s.course_id
union all select 'course_staff', count(*) from public.course_staff st join c on c.id = st.course_id
union all select 'access_restrictions', count(*) from app_private.access_restrictions r join c on c.id = r.course_id
union all select 'audit_logs (resource_type=course)', count(*) from app_private.audit_logs a
  join c on c.id = a.resource_id where a.resource_type = 'course'
order by 1;

\echo '== 1.3 Sandbox orders / attempts / enrollments (detail; read-only evidence) =='
select o.id as order_id, o.order_number, o.status as order_status, o.amount_minor,
       o.payment_method, o.created_at, o.buyer_id
  from public.orders o join public.courses c on c.id = o.course_id
 where c.title ilike 'SANDBOX TEST%' order by o.created_at;

select pa.id as attempt_id, pa.order_id, pa.method, pa.provider, pa.status, pa.created_at
  from public.payment_attempts pa
  join public.orders o on o.id = pa.order_id
  join public.courses c on c.id = o.course_id
 where c.title ilike 'SANDBOX TEST%' order by pa.created_at;

select e.id as enrollment_id, e.user_id, e.status, e.granted_at, e.expires_at
  from public.enrollments e join public.courses c on c.id = e.course_id
 where c.title ilike 'SANDBOX TEST%';

\echo '== 1.4 Storage objects tied to the sandbox course (PRESERVED) =='
-- course-media keys start with <course_id>/ ; course-pdfs and bank-receipts are
-- keyed by asset/submission, so they are reached through media_assets below.
select o.bucket_id, o.name, o.created_at
  from storage.objects o
  join public.courses c on o.bucket_id = 'course-media' and o.name like c.id::text || '/%'
 where c.title ilike 'SANDBOX TEST%' order by o.name;

select m.id as media_asset_id, m.asset_type, m.bucket_name, m.object_path
  from app_private.media_assets m
  join app_private.lesson_assets la on la.media_asset_id = m.id
  join public.lessons l on l.id = la.lesson_id
  join public.course_sections s on s.id = l.section_id
  join public.courses c on c.id = s.course_id
 where c.title ilike 'SANDBOX TEST%';

select b.id as submission_id, u.object_path, u.finalized_at
  from public.bank_transfer_submissions b
  join public.orders o on o.id = b.order_id
  join public.courses c on c.id = o.course_id
  left join app_private.bank_receipt_uploads u on u.submission_id = b.id
 where c.title ilike 'SANDBOX TEST%';   -- receipts are private; never delete

\echo '== 1.5 Placeholder @example.com accounts (REPORT ONLY; this script never deletes them) =='
select u.id as user_id, u.email, p.display_name, u.created_at, u.last_sign_in_at,
       (select count(*) from public.orders o where o.buyer_id = u.id)          as orders,
       (select count(*) from public.enrollments e where e.user_id = u.id)      as enrollments,
       (select count(*) from public.bank_transfer_submissions b where b.submitted_by = u.id) as bank_submissions,
       (select count(*) from public.user_roles r where r.user_id = u.id)       as role_rows
  from auth.users u left join public.profiles p on p.id = u.id
 where lower(u.email) like '%@example.com'
 order by u.created_at;

\echo '== 1.6 Dependency sweep: every single-column FK into profiles, counted for @example.com users =='
-- Catches any referencing table the hand-written queries above miss.
with fks as (
  select conrelid::regclass::text as child_table,
         (select attname from pg_attribute where attrelid = conrelid and attnum = conkey[1]) as child_col
    from pg_constraint
   where contype = 'f' and confrelid = 'public.profiles'::regclass
     and array_length(conkey, 1) = 1
)
select child_table, child_col,
       (xpath('/row/n/text()', query_to_xml(format(
         'select count(*) as n from %s where %I in (select id from auth.users where lower(email) like %L)',
         child_table, child_col, '%@example.com'), false, true, '')))[1]::text::int as example_com_rows
  from fks order by 1, 2;

\echo '== 1.7 Target fingerprint (confirm this is the approved environment) =='
select current_database() as db, current_user as db_user, now() as ran_at;

rollback;  -- Part 1 never writes.

select (:'mode' = 'apply') as is_apply \gset
\if :is_apply
\else
  \echo 'mode is not apply: dry run complete. Nothing was changed.'
  \quit
\endif

-- ======================================================================
-- PART 2: APPLY. Reached only with -v mode=apply.
-- Archives exactly one course; everything else is asserted unchanged.
-- ======================================================================
\if :{?sandbox_course_id}
\else
  \echo 'ERROR: apply requires -v sandbox_course_id=<uuid>. Aborted.'
  \quit
\endif
\if :{?confirm}
\else
  \echo 'ERROR: apply requires -v confirm=ARCHIVE-SANDBOX-<uuid>. Aborted.'
  \quit
\endif
\if :{?expected_db}
\else
  \echo 'ERROR: apply requires -v expected_db=<approved database name>. Aborted.'
  \quit
\endif

begin;

select set_config('csa.course_id', :'sandbox_course_id', true) as _c,
       set_config('csa.confirm',   :'confirm',           true) as _f,
       set_config('csa.expected_db', :'expected_db',     true) as _d \gset

do $apply$
declare
  v_id      uuid := current_setting('csa.course_id')::uuid;
  v_confirm text := current_setting('csa.confirm');
  v_title   constant text := 'SANDBOX TEST ONLY - Checkout Verification';
  v_course  public.courses%rowtype;
  v_updated integer;
  v_before  jsonb;
  v_after   jsonb;
begin
  if v_confirm is distinct from 'ARCHIVE-SANDBOX-' || v_id::text then
    raise exception 'Confirmation string does not match sandbox_course_id; aborting.';
  end if;
  if current_database() is distinct from current_setting('csa.expected_db') then
    raise exception 'Connected to database %, approved database is %; aborting.',
      current_database(), current_setting('csa.expected_db');
  end if;

  select * into v_course from public.courses where id = v_id for update;
  if not found then
    raise exception 'No course with id %; aborting.', v_id;
  end if;
  if v_course.title is distinct from v_title then
    raise exception 'Course % has title %, expected the exact sandbox title; aborting.', v_id, v_course.title;
  end if;
  if (select count(*) from public.courses where title = v_title) <> 1 then
    raise exception 'Expected exactly one course with the sandbox title; aborting.';
  end if;

  v_before := jsonb_build_object(
    'courses',          (select count(*) from public.courses),
    'orders',           (select count(*) from public.orders),
    'payment_attempts', (select count(*) from public.payment_attempts),
    'enrollments',      (select count(*) from public.enrollments),
    'enrollment_grants',(select count(*) from public.enrollment_grants),
    'bank_submissions', (select count(*) from public.bank_transfer_submissions),
    'profiles',         (select count(*) from public.profiles),
    'audit_logs',       (select count(*) from app_private.audit_logs),
    'storage_objects',  (select count(*) from storage.objects));

  -- Idempotent: an already archived course is a no-op, not an error.
  update public.courses set status = 'archived'
   where id = v_id and title = v_title and status <> 'archived';
  get diagnostics v_updated = row_count;
  if v_updated > 1 then
    raise exception 'Updated % course rows; expected at most 1; aborting.', v_updated;
  end if;
  if (select status from public.courses where id = v_id) <> 'archived' then
    raise exception 'Post-condition failed: course is not archived.';
  end if;

  -- Append-only record of the operator action (audit_logs is immutable).
  if v_updated = 1 then
    insert into app_private.audit_logs(action, resource_type, resource_id, outcome, safe_metadata)
    values ('runbook.sandbox_course_archived', 'course', v_id, 'success',
            jsonb_build_object('runbook', 'CSA-SANDBOX-SEED-CLEANUP', 'previous_status', v_course.status));
  end if;

  v_after := jsonb_build_object(
    'courses',          (select count(*) from public.courses),
    'orders',           (select count(*) from public.orders),
    'payment_attempts', (select count(*) from public.payment_attempts),
    'enrollments',      (select count(*) from public.enrollments),
    'enrollment_grants',(select count(*) from public.enrollment_grants),
    'bank_submissions', (select count(*) from public.bank_transfer_submissions),
    'profiles',         (select count(*) from public.profiles),
    'audit_logs',       (select count(*) from app_private.audit_logs) - v_updated,
    'storage_objects',  (select count(*) from storage.objects));
  if v_before is distinct from v_after then
    raise exception 'Row counts changed unexpectedly: before % after %', v_before, v_after;
  end if;
  raise notice 'Sandbox course % archived (rows updated: %). Counts unchanged: %', v_id, v_updated, v_after;
end
$apply$;

\echo 'Post-state of the sandbox course:'
select id, title, status, updated_at from public.courses where id = :'sandbox_course_id';

-- Commit only on explicit request; otherwise this is a rehearsal.
\if :{?do_commit}
  select (:'do_commit' = 'yes') as _commit \gset
\else
  \set _commit false
\endif
\if :_commit
  commit;
  \echo 'COMMITTED.'
\else
  rollback;
  \echo 'ROLLED BACK (rehearsal). Re-run with -v do_commit=yes to persist.'
\endif
