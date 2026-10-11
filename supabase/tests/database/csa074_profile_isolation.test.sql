-- CSA-074: symmetric profile isolation; FR-PROFILE-001/002/004.
begin;
create temporary sequence csa074_assertion;
grant usage,select on sequence csa074_assertion to anon,authenticated;
create function pg_temp.assert_ok(condition boolean,description text) returns text language plpgsql as $$
begin
 if condition is distinct from true then raise exception 'Assertion failed: %',description; end if;
 return 'ok ' || nextval('pg_temp.csa074_assertion') || ' - ' || description;
end; $$;
create function pg_temp.expect_error(command text,description text) returns text language plpgsql as $$
declare actual_state text;
begin
 begin execute command; exception when others then actual_state:=sqlstate; end;
 return pg_temp.assert_ok(actual_state='42501',description);
end; $$;
insert into auth.users(id,raw_user_meta_data) values
 ('07400000-0000-0000-0000-000000000001','{"full_name":"Student A"}'),
 ('07400000-0000-0000-0000-000000000002','{"full_name":"Student B"}');
create temporary table csa074_snapshot as select id,to_jsonb(p) as row_data from public.profiles p;
select set_config('request.jwt.claim.sub','07400000-0000-0000-0000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"07400000-0000-0000-0000-000000000001","role":"authenticated"}',true);
set local role authenticated;
select pg_temp.assert_ok((select count(*)=1 and bool_and(id='07400000-0000-0000-0000-000000000001') from public.profiles),'A unfiltered read returns exactly own profile');
select pg_temp.assert_ok((select count(*)=0 from public.profiles where id='07400000-0000-0000-0000-000000000002'),'A cannot read guessed foreign identity');
select pg_temp.assert_ok((select count(*)=1 and bool_and(id='07400000-0000-0000-0000-000000000001') from public.profiles where id in ('07400000-0000-0000-0000-000000000001','07400000-0000-0000-0000-000000000002')),'A mixed ownership filter cannot enumerate foreign profile');
with changed as (update public.profiles set display_name='Intrusion A',locale='forged' where id='07400000-0000-0000-0000-000000000002' returning *)
select pg_temp.assert_ok((select count(*)=0 from changed),'A foreign update RETURNING exposes no rows');
with changed as (update public.profiles set display_name='Updated A',locale='si-LK' returning *)
select pg_temp.assert_ok((select count(*)=1 and bool_and(id='07400000-0000-0000-0000-000000000001' and display_name='Updated A' and locale='si-LK') from changed),'A unfiltered update changes and returns only own profile');
select pg_temp.expect_error($q$insert into public.profiles(id,display_name) values ('07400000-0000-0000-0000-000000000002','Forgery')$q$,'A cannot insert a foreign profile');
select pg_temp.expect_error($q$delete from public.profiles where id='07400000-0000-0000-0000-000000000002' returning *$q$,'A cannot delete a foreign profile');
reset role;
select pg_temp.assert_ok(not exists (select from public.profiles p full join csa074_snapshot s using(id) where coalesce(p.id,s.id)<>'07400000-0000-0000-0000-000000000001' and to_jsonb(p) is distinct from s.row_data),'A attempts preserve every complete foreign row including timestamps');
update csa074_snapshot s set row_data=to_jsonb(p) from public.profiles p where p.id=s.id;
select set_config('request.jwt.claim.sub','07400000-0000-0000-0000-000000000002',true);
select set_config('request.jwt.claims','{"sub":"07400000-0000-0000-0000-000000000002","role":"authenticated"}',true);
set local role authenticated;
select pg_temp.assert_ok((select count(*)=1 and bool_and(id='07400000-0000-0000-0000-000000000002') from public.profiles),'B unfiltered read returns exactly own profile');
select pg_temp.assert_ok((select count(*)=0 from public.profiles where id='07400000-0000-0000-0000-000000000001'),'B cannot read guessed foreign identity');
select pg_temp.assert_ok((select count(*)=1 and bool_and(id='07400000-0000-0000-0000-000000000002') from public.profiles where id in ('07400000-0000-0000-0000-000000000002','07400000-0000-0000-0000-000000000001')),'B mixed ownership filter cannot enumerate foreign profile');
with changed as (update public.profiles set display_name='Intrusion B',locale='forged' where id='07400000-0000-0000-0000-000000000001' returning *)
select pg_temp.assert_ok((select count(*)=0 from changed),'B foreign update RETURNING exposes no rows');
with changed as (update public.profiles set display_name='Updated B',locale='en-LK' returning *)
select pg_temp.assert_ok((select count(*)=1 and bool_and(id='07400000-0000-0000-0000-000000000002' and display_name='Updated B' and locale='en-LK') from changed),'B unfiltered update changes and returns only own profile');
select pg_temp.expect_error($q$insert into public.profiles(id,display_name) values ('07400000-0000-0000-0000-000000000001','Forgery')$q$,'B cannot insert a foreign profile');
select pg_temp.expect_error($q$delete from public.profiles where id='07400000-0000-0000-0000-000000000001' returning *$q$,'B cannot delete a foreign profile');
reset role;
select pg_temp.assert_ok(not exists (select from public.profiles p full join csa074_snapshot s using(id) where coalesce(p.id,s.id)<>'07400000-0000-0000-0000-000000000002' and to_jsonb(p) is distinct from s.row_data),'B attempts preserve every complete foreign row including timestamps');
update csa074_snapshot s set row_data=to_jsonb(p) from public.profiles p where p.id=s.id;
-- Clear both claim representations; prior identity cannot survive.
select set_config('request.jwt.claim.sub','',true);
select set_config('request.jwt.claims','{"role":"authenticated"}',true);
set local role authenticated;
select pg_temp.assert_ok((select count(*)=0 from public.profiles),'Missing identity cannot reuse previous profile access');
with changed as (update public.profiles set display_name='No identity' returning *)
select pg_temp.assert_ok((select count(*)=0 from changed),'Missing identity cannot mutate or return any profile');
reset role;
set local role anon;
select pg_temp.expect_error('select * from public.profiles','Guest SELECT denied');
select pg_temp.expect_error('update public.profiles set display_name=''Guest intrusion'' returning *','Guest UPDATE denied');
select pg_temp.expect_error($q$insert into public.profiles(id,display_name) values ('07400000-0000-0000-0000-000000000001','Guest forgery')$q$,'Guest INSERT denied');
select pg_temp.expect_error('delete from public.profiles returning *','Guest DELETE denied');
reset role;
select pg_temp.assert_ok((select count(*) from public.profiles)=(select count(*) from csa074_snapshot),'Denied operations preserve profile cardinality');
select pg_temp.assert_ok(not exists (select from public.profiles p full join csa074_snapshot s using(id) where to_jsonb(p) is distinct from s.row_data),'Missing identity and guest attempts preserve complete profile snapshots');
select '1..' || last_value from pg_temp.csa074_assertion;
rollback;
