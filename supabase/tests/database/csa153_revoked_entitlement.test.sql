-- Real merged entitlement boundary; every fixture is rolled back.
begin;
create temporary sequence csa153_assertion;
create function pg_temp.check_it(ok boolean,description text) returns text language plpgsql as $$begin
 if ok is distinct from true then raise exception 'Assertion failed: %',description; end if;
 return 'ok '||nextval('pg_temp.csa153_assertion')||' - '||description;
end;$$;
insert into auth.users(id) values('15300000-0000-0000-0000-000000000001'),('15300000-0000-0000-0000-000000000002');
insert into auth.sessions(id,user_id,aal,not_after) values
('15300000-0000-0000-0000-000000000011','15300000-0000-0000-0000-000000000001','aal1',now()+interval '1 day'),
('15300000-0000-0000-0000-000000000012','15300000-0000-0000-0000-000000000002','aal2',now()+interval '1 day');
insert into public.user_roles(user_id,role_id) select '15300000-0000-0000-0000-000000000002',id from public.roles where code='super_admin';
insert into public.courses(id,slug,title,price_minor,status,published_at) values
('15300000-0000-0000-0000-000000000021','csa153-revoke','Synthetic revocation',10000,'published',now()),
('15300000-0000-0000-0000-000000000022','csa153-unrelated','Synthetic independent course',10000,'published',now());
create function pg_temp.grant_it(key text,course uuid) returns jsonb language sql as $$select public.csa116_grant_admin(
 '15300000-0000-0000-0000-000000000002','15300000-0000-0000-0000-000000000012','aal2',key,
 '15300000-0000-0000-0000-000000000001',course,'Synthetic regression grant',null);$$;
create temporary table csa153_grants(key text,result jsonb);
insert into csa153_grants values('primary',pg_temp.grant_it('primary','15300000-0000-0000-0000-000000000021')),
('unrelated',pg_temp.grant_it('unrelated','15300000-0000-0000-0000-000000000022'));
select set_config('request.jwt.claims','{"sub":"15300000-0000-0000-0000-000000000001","session_id":"15300000-0000-0000-0000-000000000011","aal":"aal1","role":"authenticated"}',true);
grant usage,select on sequence csa153_assertion to authenticated;
set local role authenticated;
select pg_temp.check_it(public.csa117_verify_entitlement('15300000-0000-0000-0000-000000000021'),'active source authorizes buyer before revocation');
reset role;
select public.csa118_revoke_access('15300000-0000-0000-0000-000000000002','15300000-0000-0000-0000-000000000012','aal2','revoke-primary',
 '15300000-0000-0000-0000-000000000001','15300000-0000-0000-0000-000000000021',
 (select (result->>'grant_id')::uuid from csa153_grants where key='primary'),'grant','Synthetic revocation');
set local role authenticated;
select pg_temp.check_it(not public.csa117_verify_entitlement('15300000-0000-0000-0000-000000000021'),'same still-valid bearer claims deny next request after source revocation');
select pg_temp.check_it(public.csa117_verify_entitlement('15300000-0000-0000-0000-000000000022'),'source revocation preserves independently entitled course');
reset role;
select pg_temp.check_it(pg_temp.grant_it('primary','15300000-0000-0000-0000-000000000021')->>'replayed'='true','old grant key returns immutable historical acknowledgement');
select pg_temp.check_it(not public.csa117_verify_entitlement('15300000-0000-0000-0000-000000000021'),'replayed grant acknowledgement cannot restore access');
select pg_temp.grant_it('fresh','15300000-0000-0000-0000-000000000021');
select pg_temp.check_it(public.csa117_verify_entitlement('15300000-0000-0000-0000-000000000021'),'new independently authorized source may grant access');
select public.csa118_revoke_access('15300000-0000-0000-0000-000000000002','15300000-0000-0000-0000-000000000012','aal2','restrict-course',
 '15300000-0000-0000-0000-000000000001','15300000-0000-0000-0000-000000000021',null,'course','Synthetic safety restriction');
select pg_temp.grant_it('under-restriction','15300000-0000-0000-0000-000000000021');
set local role authenticated;
select pg_temp.check_it(not public.csa117_verify_entitlement('15300000-0000-0000-0000-000000000021'),'new grant cannot bypass course restriction');
select pg_temp.check_it(public.csa117_verify_entitlement('15300000-0000-0000-0000-000000000022'),'course restriction remains scoped to requested course');
reset role;
select public.csa118_revoke_access('15300000-0000-0000-0000-000000000002','15300000-0000-0000-0000-000000000012','aal2','restrict-account',
 '15300000-0000-0000-0000-000000000001',null,null,'account','Synthetic account restriction');
set local role authenticated;
select pg_temp.check_it(not public.csa117_verify_entitlement('15300000-0000-0000-0000-000000000022'),'account restriction denies previously entitled independent course');
reset role;
select '1..'||last_value from csa153_assertion;
rollback;
