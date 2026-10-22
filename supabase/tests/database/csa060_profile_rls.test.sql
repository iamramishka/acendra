begin;
create temporary sequence csa060_assertion;
grant usage, select on sequence csa060_assertion to anon, authenticated, service_role;
create function pg_temp.assert_ok(condition boolean, description text)
returns text language plpgsql as $$
begin
  if condition is distinct from true then raise exception 'Assertion failed: %', description; end if;
  return 'ok ' || nextval('pg_temp.csa060_assertion') || ' - ' || description;
end; $$;
create function pg_temp.expect_error(command text, expected_state text, description text)
returns text language plpgsql as $$
declare actual_state text;
begin
  begin execute command; exception when others then actual_state := sqlstate; end;
  return pg_temp.assert_ok(actual_state = expected_state, description);
end; $$;

insert into auth.users(id,raw_user_meta_data) values
 ('06000000-0000-0000-0000-000000000001','{"full_name":"Student A","role":"super_admin"}'),
 ('06000000-0000-0000-0000-000000000002','{"full_name":"Student B"}'),
 ('06000000-0000-0000-0000-000000000003','{"full_name":[]}'),
 ('06000000-0000-0000-0000-000000000004','{"full_name":"   "}'),
 ('06000000-0000-0000-0000-000000000005',jsonb_build_object('full_name',repeat('名',101))),
 ('06000000-0000-0000-0000-000000000006',jsonb_build_object('full_name',repeat('名',100)));
select pg_temp.assert_ok((select count(*)=6 from public.profiles where id::text like '06000000-%'),'signup creates every profile');
select pg_temp.assert_ok((select display_name='Student A' from public.profiles where id='06000000-0000-0000-0000-000000000001'),'safe signup name copied');
select pg_temp.assert_ok((select count(*)=3 from public.profiles where id::text like '06000000-%' and display_name='Student'),'malformed blank overlong metadata falls back');
select pg_temp.assert_ok((select char_length(display_name)=100 from public.profiles where id='06000000-0000-0000-0000-000000000006'),'Unicode boundary preserved');
select pg_temp.assert_ok((select count(*)=0 from public.user_roles where user_id::text like '06000000-%'),'signup metadata grants no roles');
select pg_temp.assert_ok(not has_function_privilege('anon','public.csa060_account_eligible()','EXECUTE'),'anonymous cannot query eligibility');
select pg_temp.assert_ok(not has_function_privilege('authenticated','public.csa060_create_profile()','EXECUTE'),'trigger is not a client RPC');
set local role anon;
select pg_temp.expect_error('select * from public.profiles','42501','anonymous profile select denied');
reset role;
select set_config('request.jwt.claim.sub','06000000-0000-0000-0000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"06000000-0000-0000-0000-000000000001","role":"authenticated","is_anonymous":false}',true);
set local role authenticated;
select pg_temp.assert_ok((select count(*)=1 from public.profiles),'student reads exactly own profile');
select pg_temp.assert_ok((select count(*)=0 from public.profiles where id='06000000-0000-0000-0000-000000000002'),'foreign profile not visible');
update public.profiles set display_name='Changed',locale='si-LK' where id='06000000-0000-0000-0000-000000000001';
select pg_temp.assert_ok((select display_name='Changed' and locale='si-LK' from public.profiles),'safe fields writable');
update public.profiles set display_name='Intrusion' where id='06000000-0000-0000-0000-000000000002';
select pg_temp.expect_error('update public.profiles set avatar_path=''forged''','23514','avatar reference outside own folder rejected');
select pg_temp.expect_error('update public.profiles set avatar_path=''06000000-0000-0000-0000-000000000002/avatar.png''','23514','foreign avatar folder rejected');
update public.profiles set avatar_path=id::text||'/avatar.png',email_notifications_enabled=false;
select pg_temp.assert_ok((select avatar_path=id::text||'/avatar.png' and not email_notifications_enabled from public.profiles),'own avatar and notification preference writable');
select pg_temp.expect_error('update public.profiles set id=gen_random_uuid()','42501','identity write denied');
select pg_temp.expect_error('update public.profiles set created_at=now()','42501','created timestamp write denied');
select pg_temp.expect_error('update public.profiles set updated_at=now()','42501','updated timestamp write denied');
select pg_temp.expect_error('delete from public.profiles','42501','profile delete denied');
select pg_temp.expect_error($q$insert into public.profiles(id,display_name) values ('06000000-0000-0000-0000-000000000001','Forgery')$q$,'42501','profile insert denied');
select pg_temp.expect_error('select * from auth.users','42501','eligibility does not grant Auth row access');
reset role;
select pg_temp.assert_ok((select display_name='Student B' from public.profiles where id='06000000-0000-0000-0000-000000000002'),'foreign update changed nothing');
select pg_temp.assert_ok((select avatar_path is null and email_notifications_enabled from public.profiles where id='06000000-0000-0000-0000-000000000002'),'foreign avatar and notification preference unchanged');
update auth.users set banned_until=now()+interval '1 hour' where id='06000000-0000-0000-0000-000000000001';
set local role authenticated;
select pg_temp.assert_ok((select count(*)=0 from public.profiles),'ban denies old session immediately');
update public.profiles set display_name='Banned write';
reset role;
select pg_temp.assert_ok((select display_name='Changed' from public.profiles where id='06000000-0000-0000-0000-000000000001'),'banned write changed nothing');
update auth.users set banned_until=now()-interval '1 second' where id='06000000-0000-0000-0000-000000000001';
set local role authenticated;
select pg_temp.assert_ok((select count(*)=1 from public.profiles),'expired ban permits own access');
reset role;
update auth.users set deleted_at=now() where id='06000000-0000-0000-0000-000000000001';
set local role authenticated;
select pg_temp.assert_ok((select count(*)=0 from public.profiles),'soft deletion denies old session');
reset role;
update auth.users set deleted_at=null,is_anonymous=true where id='06000000-0000-0000-0000-000000000001';
set local role authenticated;
select pg_temp.assert_ok((select count(*)=0 from public.profiles),'anonymous Auth user denied despite false token flag');
reset role;
select set_config('request.jwt.claim.sub','06000000-0000-0000-0000-000000000099',true);
set local role authenticated;
select pg_temp.assert_ok((select count(*)=0 from public.profiles),'missing Auth identity denied');
reset role;
set local role service_role;
select pg_temp.expect_error('select * from public.profiles','42501','service role has no broad profile grant');
reset role;
select '1..' || last_value from pg_temp.csa060_assertion;
rollback;
