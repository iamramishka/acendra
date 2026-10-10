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

-- Manual CSA-059 access snapshot, before CSA-060/061 add reviewed policies.
-- Kept outside supabase/tests so later legitimate access does not fail schema tests.
select pg_temp.assert_ok(
  not exists (select from pg_policies where schemaname = 'public'
    and tablename in ('profiles', 'roles', 'user_roles')), 'no policies at CSA-059 stage');
insert into auth.users (id) values
 ('05900000-0000-0000-0000-000000000001'), ('05900000-0000-0000-0000-000000000002');
insert into public.profiles (id, display_name) values
 ('05900000-0000-0000-0000-000000000001', 'Student A'),
 ('05900000-0000-0000-0000-000000000002', 'Student B');
insert into public.user_roles (user_id, role_id, revoked_at)
 select '05900000-0000-0000-0000-000000000001', id, now()
 from public.roles where code = 'content_manager';
insert into public.user_roles (user_id, role_id)
 select '05900000-0000-0000-0000-000000000001', id
 from public.roles where code in ('content_manager', 'finance_admin');
-- Check effective privileges, including inherited/PUBLIC grants.
select pg_temp.assert_ok(not has_table_privilege(r,t,p), r || ' denied ' || p || ' on ' || t)
from unnest(array['anon','authenticated','service_role']) r
cross join unnest(array['public.profiles','public.roles','public.user_roles']) t
cross join unnest(array['SELECT','INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER']) p;

set local role anon;
select pg_temp.expect_error('select * from public.profiles','42501','anonymous cannot read profiles');
select pg_temp.expect_error('select * from public.roles','42501','anonymous cannot read roles');
reset role;
set local role authenticated;
select pg_temp.expect_error('select * from public.profiles','42501','authenticated cannot read any profiles before CSA-060');
select pg_temp.expect_error('select * from public.user_roles','42501','authenticated cannot read role history');
select pg_temp.expect_error($q$insert into public.user_roles(user_id,role_id)
  select '05900000-0000-0000-0000-000000000001',id from public.roles where code = 'super_admin'$q$,
  '42501','student cannot assign super admin');
select pg_temp.expect_error($q$update public.roles set code = 'super_admin'$q$,
  '42501','student cannot mutate role definitions');
select pg_temp.expect_error('delete from public.user_roles','42501','student cannot erase role history');
reset role;

-- Even an accidental later table grant does not bypass deny-by-default RLS.
grant select, insert, update, delete on public.profiles, public.roles, public.user_roles to authenticated;
set local role authenticated;
select pg_temp.assert_ok((select count(*) = 0 from public.profiles), 'RLS hides both profiles even with SELECT grant');
select pg_temp.assert_ok((select count(*) = 0 from public.user_roles), 'RLS hides role history even with SELECT grant');
select pg_temp.expect_error($q$insert into public.user_roles(user_id,role_id) values
  ('05900000-0000-0000-0000-000000000002','05900000-0000-0000-0000-000000000099')$q$,
  '42501','RLS blocks role insertion even with INSERT grant');
update public.profiles set display_name = 'Attacker';
delete from public.user_roles;
reset role;
select pg_temp.assert_ok((select count(*) = 3 from public.user_roles)
  and not exists(select from public.profiles where display_name = 'Attacker'), 'RLS prevents update and delete mutations');
select '1..' || last_value from pg_temp.csa059_assertion;
rollback;
