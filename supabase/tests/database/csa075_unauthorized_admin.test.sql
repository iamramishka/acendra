-- CSA-075: actual denied operations preserve grants and immutable audit.
begin;
create temporary sequence csa075_assertion;
grant usage,select on sequence csa075_assertion to anon,authenticated,service_role;
create function pg_temp.assert_ok(condition boolean,description text) returns text language plpgsql as $$
begin
 if condition is distinct from true then raise exception 'Assertion failed: %',description; end if;
 return 'ok ' || nextval('pg_temp.csa075_assertion') || ' - ' || description;
end; $$;
create function pg_temp.denied(command text,description text) returns text language plpgsql as $$
declare actual text;
begin
 begin execute command; exception when others then actual:=sqlstate; end;
 return pg_temp.assert_ok(actual='42501',description);
end; $$;
insert into auth.users(id,raw_user_meta_data) values
 ('07500000-0000-0000-0000-000000000001','{}'),
 ('07500000-0000-0000-0000-000000000002','{"role":"super_admin","is_admin":true}'),
 ('07500000-0000-0000-0000-000000000003','{}'),
 ('07500000-0000-0000-0000-000000000004','{}');
insert into public.profiles(id,display_name)
select id,'Synthetic CSA075 account' from auth.users where id::text like '07500000-%'
on conflict(id) do nothing;
insert into public.user_roles(user_id,role_id)
select fixture.user_id::uuid,r.id from (values
 ('07500000-0000-0000-0000-000000000001','super_admin'),
 ('07500000-0000-0000-0000-000000000003','content_manager'),
 ('07500000-0000-0000-0000-000000000004','finance_admin')
) as fixture(user_id,code) join public.roles r on r.code=fixture.code;
create temporary table csa075_before as
select (select jsonb_agg(to_jsonb(ur) order by ur.id) from public.user_roles ur) as grants,
 (select jsonb_agg(to_jsonb(a) order by a.id) from public.csa061_role_audit a) as audit;
select set_config('request.jwt.claims','{"sub":"07500000-0000-0000-0000-000000000002","role":"authenticated","aal":"aal2","user_role":"super_admin","app_metadata":{"role":"super_admin"}}',true);
set local role authenticated;
select pg_temp.denied($q$select public.csa061_change_role('07500000-0000-0000-0000-000000000001','aal2','07500000-0000-0000-0000-000000000002','super_admin','grant','Forged actor','07500000-0000-0000-0000-000000000010')$q$,'authenticated cannot invoke internal role RPC with forged admin actor');
select pg_temp.denied($q$select public.csa061_bootstrap_super_admin('07500000-0000-0000-0000-000000000002','Public bootstrap','07500000-0000-0000-0000-000000000011')$q$,'authenticated cannot bootstrap');
select pg_temp.denied($q$insert into public.user_roles(user_id,role_id) values ('07500000-0000-0000-0000-000000000002',null)$q$,'authenticated cannot insert role grants');
select pg_temp.denied($q$update public.user_roles set revoked_at=now()$q$,'authenticated cannot revoke grants directly');
select pg_temp.denied($q$delete from public.user_roles$q$,'authenticated cannot delete grant history');
select pg_temp.denied($q$update public.roles set code='super_admin'$q$,'authenticated cannot rewrite role definitions');
select pg_temp.denied($q$update public.csa061_role_audit set reason='forged'$q$,'authenticated cannot rewrite audit');
select pg_temp.denied($q$delete from public.csa061_role_audit$q$,'authenticated cannot delete audit');
reset role;
set local role anon;
select pg_temp.denied($q$select public.csa061_change_role('07500000-0000-0000-0000-000000000001','aal2','07500000-0000-0000-0000-000000000002','super_admin','grant','Forged actor','07500000-0000-0000-0000-000000000010')$q$,'anon cannot invoke internal role RPC with forged admin actor');
select pg_temp.denied($q$select public.csa061_bootstrap_super_admin('07500000-0000-0000-0000-000000000002','Public bootstrap','07500000-0000-0000-0000-000000000011')$q$,'anon cannot bootstrap');
select pg_temp.denied($q$insert into public.user_roles(user_id,role_id) values ('07500000-0000-0000-0000-000000000002',null)$q$,'anon cannot insert role grants');
select pg_temp.denied($q$update public.user_roles set revoked_at=now()$q$,'anon cannot revoke grants directly');
select pg_temp.denied($q$delete from public.user_roles$q$,'anon cannot delete grant history');
select pg_temp.denied($q$update public.roles set code='super_admin'$q$,'anon cannot rewrite role definitions');
select pg_temp.denied($q$update public.csa061_role_audit set reason='forged'$q$,'anon cannot rewrite audit');
select pg_temp.denied($q$delete from public.csa061_role_audit$q$,'anon cannot delete audit');
reset role;
-- Operator calls verify internal authority independently of EXECUTE, which
-- CSA-073 revokes for service_role on the old core.
select pg_temp.denied($q$select public.csa061_change_role('07500000-0000-0000-0000-000000000002','aal2','07500000-0000-0000-0000-000000000001','super_admin','revoke','Student revoke','07500000-0000-0000-0000-000000000014')$q$,'forged student metadata cannot revoke administrator');
select pg_temp.denied($q$select public.csa061_change_role('07500000-0000-0000-0000-000000000003','aal2','07500000-0000-0000-0000-000000000002','super_admin','grant','Content escalation','07500000-0000-0000-0000-000000000015')$q$,'content manager cannot grant administrator authority');
select pg_temp.denied($q$select public.csa061_change_role('07500000-0000-0000-0000-000000000004','aal2','07500000-0000-0000-0000-000000000001','super_admin','revoke','Finance revoke','07500000-0000-0000-0000-000000000016')$q$,'finance administrator cannot revoke administrator authority');
update auth.users set deleted_at=now() where id='07500000-0000-0000-0000-000000000001';
select pg_temp.denied($q$select public.csa061_change_role('07500000-0000-0000-0000-000000000001','aal2','07500000-0000-0000-0000-000000000002','super_admin','grant','Deleted actor','07500000-0000-0000-0000-000000000017')$q$,'soft-deleted admin cannot grant roles');
update auth.users set deleted_at=null,is_anonymous=true where id='07500000-0000-0000-0000-000000000001';
select pg_temp.denied($q$select public.csa061_change_role('07500000-0000-0000-0000-000000000001','aal2','07500000-0000-0000-0000-000000000002','super_admin','grant','Anonymous actor','07500000-0000-0000-0000-000000000018')$q$,'anonymous account with existing role cannot grant roles');
select pg_temp.assert_ok((select grants from csa075_before) is not distinct from (select jsonb_agg(to_jsonb(ur) order by ur.id) from public.user_roles ur),'all denied operations preserve every role grant');
select pg_temp.assert_ok((select audit from csa075_before) is not distinct from (select jsonb_agg(to_jsonb(a) order by a.id) from public.csa061_role_audit a),'all denied operations preserve every audit record');
select '1..' || last_value from pg_temp.csa075_assertion;
rollback;
