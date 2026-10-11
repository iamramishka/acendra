-- Transactional TAP; psql ON_ERROR_STOP or Supabase pg_prove.
begin;
create temporary sequence csa061_assertion;
grant usage,select on sequence csa061_assertion to authenticated,anon,service_role;
create function pg_temp.assert_ok(condition boolean,description text) returns text language plpgsql as $$
begin
  if condition is distinct from true then raise exception 'Assertion failed: %',description; end if;
  return 'ok ' || nextval('pg_temp.csa061_assertion') || ' - ' || description;
end; $$;
create function pg_temp.expect_error(command text,expected text,description text) returns text language plpgsql as $$
declare actual text;
begin
  begin execute command; exception when others then actual:=sqlstate; end;
  return pg_temp.assert_ok(actual=expected,description);
end; $$;

select pg_temp.assert_ok(not has_function_privilege('authenticated','public.csa061_change_role(uuid,text,uuid,text,text,text,uuid)','EXECUTE'), 'browser cannot invoke service role mutation RPC');
select pg_temp.assert_ok(has_function_privilege('service_role','public.csa061_change_role(uuid,text,uuid,text,text,text,uuid)','EXECUTE'), 'trusted service can invoke guarded operation');
select pg_temp.assert_ok(not has_function_privilege('service_role','public.csa061_bootstrap_super_admin(uuid,text,uuid)','EXECUTE'), 'service cannot bootstrap first admin');
select pg_temp.assert_ok(not has_function_privilege('anon','public.csa061_bootstrap_super_admin(uuid,text,uuid)','EXECUTE'), 'anonymous cannot bootstrap');
select pg_temp.assert_ok(not has_table_privilege('service_role','public.csa061_role_audit','INSERT'), 'service cannot write audit directly');
select pg_temp.assert_ok(not has_table_privilege('authenticated','public.user_roles','INSERT'), 'browser cannot assign roles directly');
select pg_temp.assert_ok(not has_table_privilege('authenticated','public.user_roles','UPDATE'), 'browser cannot revoke roles directly');

insert into auth.users(id,raw_user_meta_data) values
 ('06100000-0000-0000-0000-000000000001','{}'),
 ('06100000-0000-0000-0000-000000000002','{"role":"super_admin","is_admin":true}'),
 ('06100000-0000-0000-0000-000000000003','{}'),
 ('06100000-0000-0000-0000-000000000004','{}');
insert into public.profiles(id,display_name) values
 ('06100000-0000-0000-0000-000000000001','Admin A'),
 ('06100000-0000-0000-0000-000000000002','Student B'),
 ('06100000-0000-0000-0000-000000000003','Student C'),
 ('06100000-0000-0000-0000-000000000004','Admin D')
on conflict(id) do update set display_name=excluded.display_name;
select pg_temp.assert_ok((select count(*)=0 from public.user_roles where user_id='06100000-0000-0000-0000-000000000002'),'signup metadata does not assign trusted role');
select public.csa061_bootstrap_super_admin('06100000-0000-0000-0000-000000000001','Controlled synthetic bootstrap','06100000-0000-0000-0000-000000000010');
select pg_temp.assert_ok((select count(*)=1 from public.csa061_role_audit),'bootstrap records immutable audit');
select public.csa061_bootstrap_super_admin('06100000-0000-0000-0000-000000000001','Controlled synthetic bootstrap','06100000-0000-0000-0000-000000000010');
select pg_temp.assert_ok((select count(*)=1 from public.csa061_role_audit),'bootstrap replay does not duplicate audit');
select pg_temp.expect_error($q$select public.csa061_bootstrap_super_admin(null,'Controlled synthetic bootstrap','06100000-0000-0000-0000-000000000010')$q$,'22023','null target cannot bypass bootstrap replay comparison');
select pg_temp.expect_error($q$select public.csa061_bootstrap_super_admin('06100000-0000-0000-0000-000000000004','Second bootstrap','06100000-0000-0000-0000-000000000011')$q$,'42501','second bootstrap prohibited');

select pg_temp.expect_error($q$select public.csa061_change_role('06100000-0000-0000-0000-000000000002','aal2','06100000-0000-0000-0000-000000000003','super_admin','grant','Forged metadata','06100000-0000-0000-0000-000000000012')$q$,'42501','student with forged metadata cannot grant roles');
select pg_temp.expect_error($q$select public.csa061_change_role('06100000-0000-0000-0000-000000000001','aal1','06100000-0000-0000-0000-000000000002','finance_admin','grant','Insufficient MFA','06100000-0000-0000-0000-000000000013')$q$,'42501','admin without MFA denied');
select pg_temp.expect_error($q$select public.csa061_change_role('06100000-0000-0000-0000-000000000001','aal2','06100000-0000-0000-0000-000000000001','super_admin','revoke','Self revoke','06100000-0000-0000-0000-000000000014')$q$,'42501','self change and removal of only active admin denied');
select pg_temp.assert_ok((select count(*)=1 from public.user_roles ur join public.roles r on r.id=ur.role_id where r.code='super_admin' and ur.revoked_at is null),'last admin remains active');
select pg_temp.expect_error($q$select public.csa061_change_role('06100000-0000-0000-0000-000000000001','aal2','06100000-0000-0000-0000-000000000002','finance_admin','grant',' ','06100000-0000-0000-0000-000000000015')$q$,'22023','blank reason denied');
select pg_temp.expect_error($q$select public.csa061_change_role('06100000-0000-0000-0000-000000000001','aal2','06100000-0000-0000-0000-000000000002','owner','grant','Bad role','06100000-0000-0000-0000-000000000016')$q$,'22023','unknown role denied');

set local role service_role;
select public.csa061_change_role('06100000-0000-0000-0000-000000000001','aal2','06100000-0000-0000-0000-000000000002','finance_admin','grant','Approved synthetic reviewer','06100000-0000-0000-0000-000000000020');
reset role;
select pg_temp.assert_ok((select count(*)=1 from public.user_roles ur join public.roles r on r.id=ur.role_id where ur.user_id='06100000-0000-0000-0000-000000000002' and r.code='finance_admin' and ur.granted_by='06100000-0000-0000-0000-000000000001' and ur.revoked_at is null),'grant actor derived from verified operation');
select public.csa061_change_role('06100000-0000-0000-0000-000000000001','aal2','06100000-0000-0000-0000-000000000002','finance_admin','grant','Approved synthetic reviewer','06100000-0000-0000-0000-000000000020');
select pg_temp.assert_ok((select count(*)=2 from public.csa061_role_audit),'role replay creates no duplicate audit');
select pg_temp.expect_error($q$select public.csa061_change_role('06100000-0000-0000-0000-000000000001','aal2','06100000-0000-0000-0000-000000000003','finance_admin','grant','Approved synthetic reviewer','06100000-0000-0000-0000-000000000020')$q$,'22023','request UUID cannot be reused with changed payload');
select pg_temp.expect_error($q$select public.csa061_change_role('06100000-0000-0000-0000-000000000002','aal2','06100000-0000-0000-0000-000000000003','content_manager','grant','Finance role is not super admin','06100000-0000-0000-0000-000000000021')$q$,'42501','finance role cannot assign other roles');

select set_config('request.jwt.claims','{"sub":"06100000-0000-0000-0000-000000000002","role":"authenticated","aal":"aal2"}',true);
set local role authenticated;
select pg_temp.assert_ok((select count(*)=1 from public.user_roles),'own current grant projection visible');
select pg_temp.assert_ok((select count(*)=0 from public.user_roles where user_id='06100000-0000-0000-0000-000000000001'),'foreign grants hidden');
select pg_temp.expect_error('select granted_by from public.user_roles','42501','actor provenance not exposed in browser projection');
select pg_temp.expect_error('select * from public.csa061_role_audit','42501','audit hidden from ordinary browser');
reset role;

select public.csa061_change_role('06100000-0000-0000-0000-000000000001','aal2','06100000-0000-0000-0000-000000000002','finance_admin','revoke','Reviewer handoff','06100000-0000-0000-0000-000000000022');
select pg_temp.assert_ok((select count(*)=1 from public.user_roles where user_id='06100000-0000-0000-0000-000000000002' and revoked_by='06100000-0000-0000-0000-000000000001' and revoked_at is not null),'revoke preserves actor and grant history');
select pg_temp.assert_ok((public.csa061_change_role('06100000-0000-0000-0000-000000000001','aal2','06100000-0000-0000-0000-000000000002','finance_admin','grant','Approved synthetic reviewer','06100000-0000-0000-0000-000000000020')->>'status')='revoked','grant replay after revocation reports current revoked status');
set local role authenticated;
select pg_temp.assert_ok((select count(*)=0 from public.user_roles),'revocation takes effect with unchanged old session claims');
reset role;
select pg_temp.expect_error('update public.csa061_role_audit set reason=''rewritten''','42501','audit updates denied even to owner');
select pg_temp.expect_error('delete from public.csa061_role_audit','42501','audit deletion denied');
select pg_temp.expect_error('truncate public.csa061_role_audit','42501','audit truncate denied');

create function pg_temp.reject_audit() returns trigger language plpgsql as $$ begin raise exception 'Injected audit failure'; end; $$;
create trigger csa061_test_audit_failure before insert on public.csa061_role_audit for each row execute function pg_temp.reject_audit();
select pg_temp.expect_error($q$select public.csa061_change_role('06100000-0000-0000-0000-000000000001','aal2','06100000-0000-0000-0000-000000000003','content_manager','grant','Rollback test','06100000-0000-0000-0000-000000000023')$q$,'P0001','injected audit failure rolls operation back');
select pg_temp.assert_ok((select count(*)=0 from public.user_roles where user_id='06100000-0000-0000-0000-000000000003'),'no partial grant after audit failure');
drop trigger csa061_test_audit_failure on public.csa061_role_audit;

select public.csa061_change_role('06100000-0000-0000-0000-000000000001','aal2','06100000-0000-0000-0000-000000000004','super_admin','grant','Admin handoff','06100000-0000-0000-0000-000000000024');
select public.csa061_change_role('06100000-0000-0000-0000-000000000004','aal2','06100000-0000-0000-0000-000000000001','super_admin','revoke','Revoke prior admin','06100000-0000-0000-0000-000000000025');
select pg_temp.expect_error($q$select public.csa061_change_role('06100000-0000-0000-0000-000000000001','aal2','06100000-0000-0000-0000-000000000003','content_manager','grant','Old token attempt','06100000-0000-0000-0000-000000000026')$q$,'42501','revoked admin old session cannot mutate roles');
update auth.users set banned_until=now()+interval '1 day' where id='06100000-0000-0000-0000-000000000004';
select pg_temp.expect_error($q$select public.csa061_change_role('06100000-0000-0000-0000-000000000004','aal2','06100000-0000-0000-0000-000000000003','content_manager','grant','Banned attempt','06100000-0000-0000-0000-000000000027')$q$,'42501','current account ban blocks existing admin session');
select '1..' || last_value from pg_temp.csa061_assertion;
rollback;
