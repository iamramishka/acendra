-- Transactional TAP output, runnable by pg_prove / supabase test db or psql
-- with ON_ERROR_STOP=1. Helpers exist only for this test transaction.
begin;
create temporary sequence csa059_assertion;
grant usage, select on sequence csa059_assertion to anon, authenticated;
create function pg_temp.assert_ok(condition boolean, description text)
returns text language plpgsql as $$
begin
  if condition is distinct from true then
    raise exception 'Assertion failed: %', description;
  end if;
  return 'ok ' || nextval('pg_temp.csa059_assertion') || ' - ' || description;
end;
$$;
create function pg_temp.expect_error(command text, expected_state text, description text)
returns text language plpgsql as $$
declare actual_state text;
begin
  begin
    execute command;
  exception when others then
    actual_state := sqlstate;
  end;
  return pg_temp.assert_ok(actual_state = expected_state, description);
end;
$$;

select pg_temp.assert_ok(
  (select count(*) = 3 from pg_class where oid in
    ('public.profiles'::regclass, 'public.roles'::regclass, 'public.user_roles'::regclass)
    and relrowsecurity), 'RLS enabled on all identity tables');
select pg_temp.assert_ok(
  (select array_agg(code order by code) = array['content_manager','finance_admin','student','super_admin']
    from public.roles), 'exact approved role vocabulary seeded');
select pg_temp.assert_ok(
  (select count(*) = 6 from information_schema.columns where table_schema = 'public'
    and table_name = 'profiles'), 'minimal profile fields without credentials or roles');
select pg_temp.assert_ok(
  not has_function_privilege('authenticated','public.csa059_set_profile_updated_at()','EXECUTE')
  and not has_function_privilege('anon','public.csa059_set_profile_updated_at()','EXECUTE'),
  'clients cannot execute timestamp trigger function');

-- Synthetic Auth records only; no actual identities or tokens.
insert into auth.users (id) values
  ('05900000-0000-0000-0000-000000000001'),
  ('05900000-0000-0000-0000-000000000002');
insert into public.profiles (id, display_name, created_at, updated_at) values
  ('05900000-0000-0000-0000-000000000001', 'Student A', now() - interval '1 day', now() - interval '1 day'),
  ('05900000-0000-0000-0000-000000000002', 'Student B', now() - interval '1 day', now() - interval '1 day');
select pg_temp.assert_ok((select count(*) = 0 from public.user_roles), 'profiles do not auto-grant elevated roles');
select pg_temp.expect_error($q$insert into public.profiles (id,display_name) values
  ('05900000-0000-0000-0000-000000000099','Missing')$q$, '23503', 'profile requires Auth user');
select pg_temp.expect_error($q$insert into public.profiles (id,display_name) values
  ('05900000-0000-0000-0000-000000000001','Duplicate')$q$, '23505', 'one profile per Auth user');
select pg_temp.expect_error($q$update public.profiles set display_name = '   '$q$, '23514', 'blank name rejected');
select pg_temp.expect_error($q$update public.profiles set display_name = repeat('a',101)$q$, '23514', 'overlong name rejected');
select pg_temp.expect_error($q$update public.profiles set display_name = repeat(' ',100000) || 'A' || repeat(' ',100000)$q$,
  '23514', 'padded name cannot bypass stored length limit');
select pg_temp.expect_error($q$update public.profiles set display_name = chr(9) || chr(10) || chr(13)$q$,
  '23514', 'control whitespace-only name rejected');
select pg_temp.expect_error($q$update public.profiles set display_name = ' ' || chr(9) || ' '$q$,
  '23514', 'mixed whitespace-only name rejected');
select pg_temp.expect_error($q$update public.profiles set display_name = null$q$, '23502', 'null name rejected');
select pg_temp.expect_error($q$update public.profiles set avatar_path = ''$q$, '23514', 'empty avatar reference rejected');
select pg_temp.expect_error($q$update public.profiles set locale = ' '$q$, '23514', 'empty locale rejected');
select pg_temp.expect_error($q$update public.profiles set created_at = now() + interval '1 day'$q$, '23514', 'timestamp ordering enforced');
update public.profiles set display_name = repeat('名',100), updated_at = now() - interval '1 day'
  where id = '05900000-0000-0000-0000-000000000001';
select pg_temp.assert_ok((select char_length(display_name) = 100 and updated_at > created_at
  from public.profiles where id = '05900000-0000-0000-0000-000000000001'),
  'Unicode name boundary and automatic updated_at supported');
select pg_temp.expect_error($q$insert into public.roles(code,name) values ('guest','Guest')$q$,
  '23514', 'guest is not a stored role');
select pg_temp.expect_error($q$insert into public.roles(code,name) values ('super_admin','Duplicate')$q$,
  '23505', 'role codes unique');
select pg_temp.expect_error($q$update public.roles set name = ' '$q$, '23514', 'blank role name rejected');

insert into public.user_roles (user_id,role_id,granted_by,granted_at)
  select '05900000-0000-0000-0000-000000000001',id,
    '05900000-0000-0000-0000-000000000002', now() - interval '1 hour'
  from public.roles where code = 'content_manager';
select pg_temp.assert_ok((select count(*) = 1 from public.user_roles), 'valid grant accepted');
select pg_temp.expect_error($q$insert into public.user_roles(user_id,role_id)
  select '05900000-0000-0000-0000-000000000001',id from public.roles where code = 'content_manager'$q$,
  '23505', 'duplicate active grant rejected');
select pg_temp.expect_error($q$insert into public.user_roles(user_id,role_id)
  select '05900000-0000-0000-0000-000000000099',id from public.roles where code = 'student'$q$,
  '23503', 'unknown beneficiary rejected');
select pg_temp.expect_error($q$insert into public.user_roles(user_id,role_id) values
  ('05900000-0000-0000-0000-000000000001','05900000-0000-0000-0000-000000000099')$q$,
  '23503', 'unknown role rejected');
select pg_temp.expect_error($q$update public.user_roles set granted_by = '05900000-0000-0000-0000-000000000099'$q$,
  '23503', 'unknown grant actor rejected');
select pg_temp.expect_error($q$update public.user_roles set revoked_by = '05900000-0000-0000-0000-000000000002'$q$,
  '23514', 'revocation actor requires revocation timestamp');
select pg_temp.expect_error($q$update public.user_roles set revoked_at = granted_at - interval '1 second'$q$,
  '23514', 'revocation before grant rejected');
select pg_temp.expect_error($q$update public.user_roles set revoked_at = now(),
  revoked_by = '05900000-0000-0000-0000-000000000099'$q$, '23503', 'unknown revocation actor rejected');
select pg_temp.expect_error($q$delete from public.profiles where id = '05900000-0000-0000-0000-000000000002'$q$,
  '23503', 'grant actor history prevents cascading deletion');
select pg_temp.expect_error($q$delete from public.roles where code = 'content_manager'$q$,
  '23503', 'referenced role cannot be deleted');
select pg_temp.expect_error($q$delete from auth.users where id = '05900000-0000-0000-0000-000000000001'$q$,
  '23503', 'Auth deletion cannot silently erase profile');
update public.user_roles set revoked_at = now(), revoked_by = '05900000-0000-0000-0000-000000000002';
insert into public.user_roles (user_id,role_id)
  select '05900000-0000-0000-0000-000000000001',id from public.roles where code = 'content_manager';
insert into public.user_roles (user_id,role_id)
  select '05900000-0000-0000-0000-000000000001',id from public.roles where code = 'finance_admin';
select pg_temp.assert_ok((select count(*) = 3 from public.user_roles), 'regrant preserves revoked history and multiple roles');
select pg_temp.expect_error($q$update public.user_roles set revoked_at = null, revoked_by = null
  where revoked_at is not null$q$, '23505', 'history cannot be reactivated over an active grant');
select pg_temp.expect_error($q$delete from public.profiles where id = '05900000-0000-0000-0000-000000000001'$q$,
  '23503', 'beneficiary history prevents cascading deletion');

-- Access snapshots belong to stage_checks; CSA-060/061 own lasting policy tests.
select '1..' || last_value from pg_temp.csa059_assertion;
rollback;
