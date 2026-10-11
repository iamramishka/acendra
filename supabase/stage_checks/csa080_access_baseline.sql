-- Synthetic transactional TAP; full CSA077/078 schema dependency replay required.
begin;
create temporary sequence csa080_assertion;
grant usage,select on sequence csa080_assertion to anon,authenticated,service_role;
create function pg_temp.assert_ok(condition boolean,description text)
returns text language plpgsql as $$
begin
 if condition is distinct from true then raise exception 'Assertion failed: %',description; end if;
 return 'ok '||nextval('pg_temp.csa080_assertion')||' - '||description;
end;
$$;
create function pg_temp.expect_error(command text,expected_state text,description text)
returns text language plpgsql as $$
declare actual_state text;
begin
 begin execute command; exception when others then actual_state:=sqlstate; end;
 return pg_temp.assert_ok(actual_state=expected_state,description);
end;
$$;
select pg_temp.assert_ok(not has_table_privilege(r,t,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),r||' cannot access '||t)
 from unnest(array['anon','authenticated','service_role']) r cross join unnest(array['app_private.media_assets','app_private.lesson_assets']) t;
set local role anon;
select pg_temp.expect_error('select * from app_private.media_assets','42501','anonymous private reference read denied');
reset role;
set local role authenticated;
select pg_temp.expect_error('select * from app_private.lesson_assets','42501','student private association read denied');
reset role;
set local role service_role;
select pg_temp.expect_error('select * from app_private.media_assets','42501','service role must use future trusted operations');
reset role;
select '1..'||last_value from pg_temp.csa080_assertion;
rollback;
