-- Synthetic transactional schema checks. Helpers never leave this transaction.
begin;
create temporary sequence csa089_assertion;
grant usage, select on sequence csa089_assertion to anon, authenticated, service_role;
create function pg_temp.assert_ok(condition boolean, description text)
returns text language plpgsql as $$
begin
  if condition is distinct from true then raise exception 'Assertion failed: %', description; end if;
  return 'ok ' || nextval('pg_temp.csa089_assertion') || ' - ' || description;
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

insert into auth.users(id) values('08900000-0000-0000-0000-000000000001'),('08900000-0000-0000-0000-000000000002'),('08900000-0000-0000-0000-000000000003'),('08900000-0000-0000-0000-000000000004');
insert into public.profiles(id,display_name) select id,'Synthetic author' from auth.users where id::text like '089%' on conflict(id) do nothing;
insert into auth.sessions(id,user_id,aal,not_after) values
 ('08900000-0000-0000-0000-000000000011','08900000-0000-0000-0000-000000000001','aal1',now()+interval '1 day'),
 ('08900000-0000-0000-0000-000000000012','08900000-0000-0000-0000-000000000002','aal2',now()+interval '1 day'),
 ('08900000-0000-0000-0000-000000000013','08900000-0000-0000-0000-000000000003','aal1',now()+interval '1 day'),
 ('08900000-0000-0000-0000-000000000014','08900000-0000-0000-0000-000000000004','aal1',now()+interval '1 day');
insert into public.user_roles(user_id,role_id) select '08900000-0000-0000-0000-000000000001',id from public.roles where code='content_manager';
insert into public.user_roles(user_id,role_id) select '08900000-0000-0000-0000-000000000002',id from public.roles where code='super_admin';
insert into public.user_roles(user_id,role_id) select '08900000-0000-0000-0000-000000000003',id from public.roles where code='finance_admin';
select pg_temp.assert_ok((public.csa089_create_course('08900000-0000-0000-0000-000000000001','08900000-0000-0000-0000-000000000011','aal1','08900000-0000-0000-0000-000000000021','{"slug":"csa089-draft","title":"Synthetic"}') ->> 'status')='draft','content manager draft allowed');
select pg_temp.assert_ok((select price_minor=0 and currency_code='LKR' and status='draft' and created_by='08900000-0000-0000-0000-000000000001' from public.courses where slug='csa089-draft'),'trusted fixed draft fields');
select pg_temp.assert_ok((select count(*)=1 from public.course_staff s join public.courses c on c.id=s.course_id where c.slug='csa089-draft' and s.staff_role='owner' and s.user_id=c.created_by),'creator scope assigned atomically');
select pg_temp.assert_ok((select count(*)=1 from app_private.csa089_course_creation_audit where actor_id='08900000-0000-0000-0000-000000000001'),'creation audit present');
select pg_temp.assert_ok((public.csa089_create_course('08900000-0000-0000-0000-000000000001','08900000-0000-0000-0000-000000000011','aal1','08900000-0000-0000-0000-000000000021','{"title":"Synthetic","slug":"csa089-draft"}')->>'course_id')=(select id::text from public.courses where slug='csa089-draft'),'replay returns same course');
select pg_temp.assert_ok((select count(*)=1 from public.courses where slug='csa089-draft'),'identical reordered replay creates no duplicate');
select pg_temp.expect_error($q$select public.csa089_create_course('08900000-0000-0000-0000-000000000001','08900000-0000-0000-0000-000000000011','aal1','08900000-0000-0000-0000-000000000021','{"title":"Changed","slug":"csa089-draft"}')$q$,'22023','changed replay conflicts');
select pg_temp.expect_error($q$select public.csa089_create_course('08900000-0000-0000-0000-000000000003','08900000-0000-0000-0000-000000000013','aal1','08900000-0000-0000-0000-000000000025','{"title":"Synthetic","slug":"finance-draft"}')$q$,'42501','finance cannot create');
select pg_temp.expect_error($q$select public.csa089_create_course('08900000-0000-0000-0000-000000000004','08900000-0000-0000-0000-000000000014','aal1','08900000-0000-0000-0000-000000000025','{"title":"Synthetic","slug":"student-draft"}')$q$,'42501','student cannot create');
select pg_temp.expect_error($q$select public.csa089_create_course('08900000-0000-0000-0000-000000000001','08900000-0000-0000-0000-000000000013','aal1','08900000-0000-0000-0000-000000000025','{"title":"Synthetic","slug":"forged-session"}')$q$,'42501','foreign session denied');
select pg_temp.expect_error(format($q$select public.csa089_create_course('08900000-0000-0000-0000-000000000001','08900000-0000-0000-0000-000000000011','aal1','08900000-0000-0000-0000-000000000025',%L::jsonb)$q$,jsonb_build_object('title','Synthetic','slug','forged-field',field,'forged')::text),'22023','forbidden field '||field) from unnest(array['price_minor','currency_code','status','created_by','staff_role','actor']) fields(field);
select pg_temp.assert_ok((public.csa089_create_course('08900000-0000-0000-0000-000000000002','08900000-0000-0000-0000-000000000012','aal2','08900000-0000-0000-0000-000000000022','{"title":"Admin","slug":"admin-draft"}') ->> 'status')='draft','MFA superadmin allowed');
update auth.sessions set aal='aal1' where id='08900000-0000-0000-0000-000000000012';
select pg_temp.expect_error($q$select public.csa089_create_course('08900000-0000-0000-0000-000000000002','08900000-0000-0000-0000-000000000012','aal1','08900000-0000-0000-0000-000000000025','{"title":"Admin","slug":"weak-admin"}')$q$,'42501','superadmin MFA downgrade denied');
update auth.sessions set not_after=now()-interval '1 second' where id='08900000-0000-0000-0000-000000000011';
select pg_temp.expect_error($q$select public.csa089_create_course('08900000-0000-0000-0000-000000000001','08900000-0000-0000-0000-000000000011','aal1','08900000-0000-0000-0000-000000000021','{"title":"Synthetic","slug":"csa089-draft"}')$q$,'42501','expired session cannot replay');
update auth.sessions set not_after=now()+interval '1 day' where id='08900000-0000-0000-0000-000000000011';
update public.user_roles set revoked_at=now() where user_id='08900000-0000-0000-0000-000000000001';
select pg_temp.expect_error($q$select public.csa089_create_course('08900000-0000-0000-0000-000000000001','08900000-0000-0000-0000-000000000011','aal1','08900000-0000-0000-0000-000000000021','{"title":"Synthetic","slug":"csa089-draft"}')$q$,'42501','revoked global role denies replay despite owner assignment');
update public.user_roles set revoked_at=null where user_id='08900000-0000-0000-0000-000000000001';
create function pg_temp.fail_audit() returns trigger language plpgsql as $$begin raise exception 'injected failure'; end;$$;
create trigger csa089_test_audit_failure before insert on app_private.csa089_course_creation_audit for each row execute function pg_temp.fail_audit();
select pg_temp.expect_error($q$select public.csa089_create_course('08900000-0000-0000-0000-000000000001','08900000-0000-0000-0000-000000000011','aal1','08900000-0000-0000-0000-000000000026','{"title":"Rollback","slug":"rollback-draft"}')$q$,'P0001','injected audit failure propagates');
select pg_temp.assert_ok(not exists(select 1 from public.courses where slug='rollback-draft'),'audit failure rolls back course and staff');
drop trigger csa089_test_audit_failure on app_private.csa089_course_creation_audit;
select pg_temp.expect_error('update app_private.csa089_course_creation_audit set payload=''{}''','42501','audit immutable update');
select pg_temp.expect_error('truncate app_private.csa089_course_creation_audit','42501','audit immutable truncate');
select pg_temp.assert_ok(not has_function_privilege(r,'public.csa089_create_course(uuid,uuid,text,uuid,jsonb)','EXECUTE'),'client denied RPC '||r) from unnest(array['anon','authenticated']) roles(r);
select pg_temp.assert_ok(not has_table_privilege(r,'public.course_staff','SELECT'),'staff private '||r) from unnest(array['anon','authenticated','service_role']) roles(r);
select pg_temp.expect_error($q$select public.csa089_create_course('08900000-0000-0000-0000-000000000001','08900000-0000-0000-0000-000000000011','aal1','08900000-0000-0000-0000-000000000028','{"title":"Bad","slug":"bad-category","category_id":"08900000-0000-0000-0000-000000000099"}')$q$,'23503','unknown category has no partial course');
select pg_temp.expect_error($q$select public.csa089_create_course('08900000-0000-0000-0000-000000000001','08900000-0000-0000-0000-000000000011','aal1','08900000-0000-0000-0000-000000000028','{"title":"Bad","slug":"Bad Slug"}')$q$,'22023','invalid slug fails before writes');
select pg_temp.expect_error($q$select public.csa089_create_course('08900000-0000-0000-0000-000000000001','08900000-0000-0000-0000-000000000011','aal1','08900000-0000-0000-0000-000000000028','{"title":"Duplicate","slug":"csa089-draft"}')$q$,'23505','different request cannot duplicate slug');
update auth.users set banned_until=now()+interval '1 day' where id='08900000-0000-0000-0000-000000000001';
select pg_temp.expect_error($q$select public.csa089_create_course('08900000-0000-0000-0000-000000000001','08900000-0000-0000-0000-000000000011','aal1','08900000-0000-0000-0000-000000000021','{"title":"Synthetic","slug":"csa089-draft"}')$q$,'42501','banned account cannot replay');
update auth.users set banned_until=null where id='08900000-0000-0000-0000-000000000001';
select pg_temp.expect_error('delete from app_private.csa089_course_creation_audit','42501','audit immutable delete');
select pg_temp.assert_ok(not exists(select 1 from public.courses where slug='bad-category'),'FK failure rolls back');
set local role service_role;
select pg_temp.assert_ok((public.csa089_create_course('08900000-0000-0000-0000-000000000001','08900000-0000-0000-0000-000000000011','aal1','08900000-0000-0000-0000-000000000029','{"title":"Service verified","slug":"service-verified"}')->>'status')='draft','service RPC allowed after verified actor checks');
reset role;
select '1..'||last_value from pg_temp.csa089_assertion;
rollback;
