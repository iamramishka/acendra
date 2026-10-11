begin;
create temporary sequence csa073_assertion;
grant usage,select on sequence csa073_assertion to authenticated,anon,service_role;
create function pg_temp.assert_ok(condition boolean,description text) returns text language plpgsql as $$
begin
 if condition is distinct from true then raise exception 'Assertion failed: %',description; end if;
 return 'ok ' || nextval('pg_temp.csa073_assertion') || ' - ' || description;
end; $$;
create function pg_temp.expect_error(command text,expected text,description text) returns text language plpgsql as $$
declare actual text;
begin
 begin execute command; exception when others then actual:=sqlstate; end;
 return pg_temp.assert_ok(actual=expected,description);
end; $$;
select pg_temp.assert_ok(has_function_privilege('service_role','public.csa073_change_role(uuid,uuid,text,uuid,text,text,text,uuid)','EXECUTE'),'service can invoke current-session operation');
select pg_temp.assert_ok(not has_function_privilege('service_role','public.csa061_change_role(uuid,text,uuid,text,text,text,uuid)','EXECUTE'),'legacy RPC cannot bypass session checks');
select pg_temp.assert_ok(not has_function_privilege('authenticated','public.csa073_change_role(uuid,uuid,text,uuid,text,text,text,uuid)','EXECUTE'),'browser cannot assert a verified session');
select pg_temp.assert_ok(not has_function_privilege('anon','public.csa073_change_role(uuid,uuid,text,uuid,text,text,text,uuid)','EXECUTE'),'guest cannot invoke privileged operation');
insert into auth.users(id,raw_user_meta_data) values
 ('07300000-0000-0000-0000-000000000001','{}'),
 ('07300000-0000-0000-0000-000000000002','{}');
insert into public.profiles(id,display_name) values
 ('07300000-0000-0000-0000-000000000001','Synthetic admin'),
 ('07300000-0000-0000-0000-000000000002','Synthetic student') on conflict(id) do nothing;
insert into public.user_roles(user_id,role_id) select '07300000-0000-0000-0000-000000000001',id from public.roles where code='super_admin';
insert into auth.sessions(id,user_id,aal,not_after) values
 ('07300000-0000-0000-0000-000000000011','07300000-0000-0000-0000-000000000001','aal2',null),
 ('07300000-0000-0000-0000-000000000012','07300000-0000-0000-0000-000000000002','aal2',null),
 ('07300000-0000-0000-0000-000000000013','07300000-0000-0000-0000-000000000001','aal1',null),
 ('07300000-0000-0000-0000-000000000014','07300000-0000-0000-0000-000000000001','aal2',clock_timestamp()-interval '1 second');
create function pg_temp.change_role(session_id uuid,assurance text default 'aal2') returns jsonb language sql as $$
 select public.csa073_change_role('07300000-0000-0000-0000-000000000001',session_id,assurance,
 '07300000-0000-0000-0000-000000000002','finance_admin','grant','Synthetic permission test','07300000-0000-0000-0000-000000000021');
$$;
set local role service_role;
select pg_temp.expect_error($q$select pg_temp.change_role(null)$q$,'42501','missing verified session denied');
select pg_temp.expect_error($q$select pg_temp.change_role('07300000-0000-0000-0000-000000000099')$q$,'42501','nonexistent session denied');
select pg_temp.expect_error($q$select pg_temp.change_role('07300000-0000-0000-0000-000000000012')$q$,'42501','foreign session denied');
select pg_temp.expect_error($q$select pg_temp.change_role('07300000-0000-0000-0000-000000000013')$q$,'42501','current low-assurance session denied despite old aal2 claim');
select pg_temp.expect_error($q$select pg_temp.change_role('07300000-0000-0000-0000-000000000014')$q$,'42501','expired session denied');
select pg_temp.expect_error($q$select pg_temp.change_role('07300000-0000-0000-0000-000000000011','aal1')$q$,'42501','verified token must also have aal2');
reset role;
select pg_temp.assert_ok((select count(*)=0 from public.user_roles ur join public.roles r on r.id=ur.role_id where ur.user_id='07300000-0000-0000-0000-000000000002' and r.code='finance_admin'),'denials leave grants untouched');
select pg_temp.assert_ok((select count(*)=0 from public.csa061_role_audit where actor_id='07300000-0000-0000-0000-000000000001'),'denials leave audit untouched');
set local role service_role;
select pg_temp.assert_ok((pg_temp.change_role('07300000-0000-0000-0000-000000000011')->>'status')='active','eligible verified current MFA session can mutate');
reset role;
select pg_temp.assert_ok((select count(*)=1 from public.csa061_role_audit where request_id='07300000-0000-0000-0000-000000000021'),'current-session mutation creates immutable audit');
update auth.sessions set aal='aal1' where id='07300000-0000-0000-0000-000000000011';
set local role service_role;
select pg_temp.expect_error($q$select pg_temp.change_role('07300000-0000-0000-0000-000000000011')$q$,'42501','MFA downgrade denies prior idempotent request replay');
reset role;
select '1..' || last_value from pg_temp.csa073_assertion;
rollback;
