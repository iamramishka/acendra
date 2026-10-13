-- CSA-175: actual trusted HTTP RPC, not the operator-only legacy core.
begin;
create temporary sequence csa175_assertion;
grant usage,select on sequence csa175_assertion to service_role;
create function pg_temp.ok(c boolean,d text) returns text language plpgsql as $$begin
 if c is distinct from true then raise exception 'Assertion failed: %',d; end if;
 return 'ok '||nextval('pg_temp.csa175_assertion')||' - '||d; end;$$;
create function pg_temp.denied(q text,s text,d text) returns text language plpgsql as $$declare a text;begin
 begin execute q;exception when others then a:=sqlstate;end;
 return pg_temp.ok(a=s,d);end;$$;
insert into auth.users(id,raw_user_meta_data) values
 ('17500000-0000-0000-0000-000000000001','{}'),
 ('17500000-0000-0000-0000-000000000002','{"role":"super_admin"}'),
 ('17500000-0000-0000-0000-000000000003','{}');
insert into public.profiles(id,display_name) select id,'Synthetic CSA175' from auth.users where id::text like '17500000-%' on conflict do nothing;
insert into public.user_roles(user_id,role_id) select '17500000-0000-0000-0000-000000000001',id from public.roles where code='super_admin';
insert into auth.sessions(id,user_id,aal) values
 ('17500000-0000-0000-0000-000000000011','17500000-0000-0000-0000-000000000001','aal2'),
 ('17500000-0000-0000-0000-000000000012','17500000-0000-0000-0000-000000000002','aal2');
create function pg_temp.mutate(a uuid,t uuid,c text,op text,k uuid) returns jsonb language sql as $$
 select public.csa073_change_role(a,case when a='17500000-0000-0000-0000-000000000001' then '17500000-0000-0000-0000-000000000011'::uuid else '17500000-0000-0000-0000-000000000012'::uuid end,'aal2',t,c,op,'Synthetic authorized change',k);$$;
set local role service_role;
select pg_temp.denied($q$select pg_temp.mutate('17500000-0000-0000-0000-000000000002','17500000-0000-0000-0000-000000000003','super_admin','grant','17500000-0000-0000-0000-000000000021')$q$,'42501','signup metadata and MFA cannot assign privileges');
select pg_temp.denied($q$select pg_temp.mutate('17500000-0000-0000-0000-000000000001','17500000-0000-0000-0000-000000000001','student','grant','17500000-0000-0000-0000-000000000022')$q$,'42501','super admin self-role changes forbidden');
select pg_temp.ok((pg_temp.mutate('17500000-0000-0000-0000-000000000001','17500000-0000-0000-0000-000000000002','finance_admin','grant','17500000-0000-0000-0000-000000000023')->>'replayed')='false','current super admin grants finance role');
select pg_temp.ok((pg_temp.mutate('17500000-0000-0000-0000-000000000001','17500000-0000-0000-0000-000000000002','finance_admin','grant','17500000-0000-0000-0000-000000000023')->>'replayed')='true','identical request replays through current session');
select pg_temp.denied($q$select pg_temp.mutate('17500000-0000-0000-0000-000000000001','17500000-0000-0000-0000-000000000002','content_manager','grant','17500000-0000-0000-0000-000000000023')$q$,'22023','request identity cannot grant a different role');
select pg_temp.denied($q$select pg_temp.mutate('17500000-0000-0000-0000-000000000002','17500000-0000-0000-0000-000000000003','super_admin','grant','17500000-0000-0000-0000-000000000024')$q$,'42501','current finance role cannot assign privileges');
reset role;
select pg_temp.ok((select count(*)=1 from public.csa061_role_audit where actor_id='17500000-0000-0000-0000-000000000001'),'one audit for successful change and identical replay');
create function pg_temp.fail_audit() returns trigger language plpgsql as $$begin raise exception 'Injected audit failure';end;$$;
create trigger csa175_fail before insert on public.csa061_role_audit for each row execute function pg_temp.fail_audit();
set local role service_role;
select pg_temp.denied($q$select pg_temp.mutate('17500000-0000-0000-0000-000000000001','17500000-0000-0000-0000-000000000003','content_manager','grant','17500000-0000-0000-0000-000000000025')$q$,'P0001','audit failure aborts trusted operation');
reset role;
select pg_temp.ok(not exists(select 1 from public.user_roles where user_id='17500000-0000-0000-0000-000000000003'),'audit failure leaves no role grant');
drop trigger csa175_fail on public.csa061_role_audit;
update public.user_roles set revoked_at=clock_timestamp() where user_id='17500000-0000-0000-0000-000000000001';
set local role service_role;
select pg_temp.denied($q$select pg_temp.mutate('17500000-0000-0000-0000-000000000001','17500000-0000-0000-0000-000000000002','finance_admin','grant','17500000-0000-0000-0000-000000000023')$q$,'42501','revoked super admin cannot replay old success with live session');
reset role;
select '1..'||last_value from pg_temp.csa175_assertion;
rollback;
