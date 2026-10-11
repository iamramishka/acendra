-- Synthetic transactional schema checks. Helpers never leave this transaction.
begin;
create temporary sequence csa077_assertion;
grant usage, select on sequence csa077_assertion to anon, authenticated, service_role;
create function pg_temp.assert_ok(condition boolean, description text)
returns text language plpgsql as $$
begin
  if condition is distinct from true then raise exception 'Assertion failed: %', description; end if;
  return 'ok ' || nextval('pg_temp.csa077_assertion') || ' - ' || description;
end;
$$;
create function pg_temp.expect_error(command text, expected_state text, description text)
returns text language plpgsql as $$
declare actual_state text;
begin
  begin execute command; exception when others then actual_state := sqlstate; end;
  return pg_temp.assert_ok(actual_state = expected_state, description);
end;
$$;
-- App roles have no effective CRUD privileges, including BYPASSRLS service_role.
select pg_temp.assert_ok(not has_table_privilege(r,'public.'||t,p),r||' lacks '||p||' on '||t)
from unnest(array['anon','authenticated','service_role']) as roles(r)
cross join unnest(array['categories','courses']) as tables(t)
cross join unnest(array['SELECT','INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER']) as privileges(p);
select pg_temp.assert_ok((select count(*)=0 from pg_policy where polrelid in ('public.categories'::regclass,'public.courses'::regclass)), 'no premature policies');
set local role anon;
select pg_temp.expect_error('select * from public.courses','42501','guest cannot read drafts');
reset role;
set local role authenticated;
select pg_temp.expect_error('delete from public.categories','42501','authenticated cannot manage categories');
reset role;
set local role service_role;
select pg_temp.expect_error('select * from public.courses','42501','service role has no implicit catalogue capability');
reset role;
select '1..' || last_value from pg_temp.csa077_assertion;
rollback;
