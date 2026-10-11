-- Transactional TAP, synthetic fixtures only. CSA-077 must be applied first.
begin;
create temporary sequence csa078_assertion;
grant usage, select on sequence csa078_assertion to anon, authenticated, service_role;
create function pg_temp.assert_ok(condition boolean, description text)
returns text language plpgsql as $$
begin
  if condition is distinct from true then raise exception 'Assertion failed: %', description; end if;
  return 'ok ' || nextval('pg_temp.csa078_assertion') || ' - ' || description;
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

select pg_temp.assert_ok((select count(*)=0 from pg_policies where schemaname='public' and tablename in ('course_sections','lessons')),'no permissive policy before CSA-079');
select pg_temp.assert_ok(not has_table_privilege(r,t,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),r||' has no grants on '||t)
 from unnest(array['anon','authenticated','service_role']) r cross join unnest(array['public.course_sections','public.lessons']) t;
select pg_temp.assert_ok(not has_function_privilege(r,'public.csa078_set_metadata_updated_at()','EXECUTE'),r||' cannot execute timestamp helper')
 from unnest(array['anon','authenticated','service_role']) r;
set local role anon;
select pg_temp.expect_error('select * from public.lessons','42501','anonymous caller cannot read lessons');
reset role;
set local role authenticated;
select pg_temp.expect_error('select * from public.course_sections','42501','authenticated caller cannot read sections');
select pg_temp.expect_error('update public.lessons set is_published=true','42501','authenticated caller cannot publish lessons');
reset role;
set local role service_role;
select pg_temp.expect_error('select * from public.lessons','42501','service role cannot bypass withheld grants');
reset role;
select '1..'||last_value from pg_temp.csa078_assertion;
rollback;
