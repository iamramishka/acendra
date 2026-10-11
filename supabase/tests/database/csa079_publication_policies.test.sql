-- Synthetic transactional schema checks. Helpers never leave this transaction.
begin;
create temporary sequence csa079_assertion;
grant usage, select on sequence csa079_assertion to anon, authenticated, service_role;
create function pg_temp.assert_ok(condition boolean, description text)
returns text language plpgsql as $$
begin
  if condition is distinct from true then raise exception 'Assertion failed: %', description; end if;
  return 'ok ' || nextval('pg_temp.csa079_assertion') || ' - ' || description;
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

insert into public.categories(id,name,slug,is_active) values('07900000-0000-0000-0000-000000000001','Active','csa079-active',true),('07900000-0000-0000-0000-000000000002','Inactive','csa079-inactive',false);
insert into public.courses(id,slug,title,price_minor,status,published_at) values('07900000-0000-0000-0000-000000000011','csa079-published','Public',0,'published',now()),('07900000-0000-0000-0000-000000000012','csa079-draft','Private',0,'draft',null);
insert into public.course_sections(id,course_id,title,position,is_published) values
('07900000-0000-0000-0000-000000000021','07900000-0000-0000-0000-000000000011','Public',0,true),
('07900000-0000-0000-0000-000000000022','07900000-0000-0000-0000-000000000012','Hidden parent',0,true),
('07900000-0000-0000-0000-000000000023','07900000-0000-0000-0000-000000000011','Hidden section',1,false);
insert into public.lessons(id,section_id,title,lesson_type,position,is_published) values
('07900000-0000-0000-0000-000000000031','07900000-0000-0000-0000-000000000021','Public','pdf',0,true),
('07900000-0000-0000-0000-000000000032','07900000-0000-0000-0000-000000000022','Draft parent','pdf',0,true),
('07900000-0000-0000-0000-000000000033','07900000-0000-0000-0000-000000000023','Draft section','text',0,true),
('07900000-0000-0000-0000-000000000034','07900000-0000-0000-0000-000000000021','Draft lesson','text',1,false);
set local role anon;
select pg_temp.assert_ok((select count(*)=1 from public.categories where id::text like '079%'),'guest active categories only');
select pg_temp.assert_ok((select count(*)=1 from public.courses where id::text like '079%'),'guest published courses only');
select pg_temp.assert_ok((select count(*)=1 from public.course_sections where id::text like '079%'),'guest sections require published parent');
select pg_temp.assert_ok((select count(*)=1 from public.lessons where id::text like '079%'),'guest lessons require whole publication chain');
select pg_temp.expect_error('select created_by from public.courses','42501','author identity column excluded');
select pg_temp.expect_error('update public.courses set status=''published''','42501','guest cannot publish');
reset role;
set local role authenticated;
select pg_temp.assert_ok((select count(*)=1 from public.courses where id::text like '079%'),'student draft isolation');
select pg_temp.assert_ok((select count(*)=1 from public.lessons where id::text like '079%'),'student curriculum isolation');
select pg_temp.expect_error('delete from public.lessons','42501','authenticated cannot delete');
reset role;
update public.courses set status='archived' where id='07900000-0000-0000-0000-000000000011';
set local role anon;
select pg_temp.assert_ok((select count(*)=0 from public.lessons where id::text like '079%'),'archive immediately hides descendants');
reset role;
select '1..'||last_value from pg_temp.csa079_assertion;
rollback;
