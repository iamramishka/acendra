begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select plan(9);
insert into auth.users(id) values('26500000-0000-0000-0000-000000000001'),('26500000-0000-0000-0000-000000000002');
insert into auth.sessions(id,user_id,aal,not_after) values
('26500000-0000-0000-0000-000000000011','26500000-0000-0000-0000-000000000001','aal1',now()+interval '1 day'),
('26500000-0000-0000-0000-000000000012','26500000-0000-0000-0000-000000000002','aal1',now()+interval '1 day');
insert into public.courses(id,slug,title,price_minor,status,published_at) values
('26500000-0000-0000-0000-000000000021','csa265-first','Synthetic course',12345,'published',now()),
('26500000-0000-0000-0000-000000000022','csa265-second','Other synthetic course',12345,'published',now());
insert into app_private.bank_account_versions(id,bank_account_id,version,bank_name,account_holder,account_number,branch_name) values
('26500000-0000-0000-0000-000000000031','26500000-0000-0000-0000-000000000032',1,'Synthetic bank','Synthetic holder','SYNTHETIC-ONLY','Synthetic branch');
create function pg_temp.purchase(key text,method text default 'online',course uuid default '26500000-0000-0000-0000-000000000021') returns jsonb language sql as $$
 select public.csa265_create_checkout_order('26500000-0000-0000-0000-000000000001','26500000-0000-0000-0000-000000000011','aal1',key,course,method,'26500000-0000-0000-0000-000000000031'); $$;
create temporary table original as select pg_temp.purchase('first') as result;
select is((select result->'data'->>'status' from original),'pending_payment','new order remains pending');
select is(pg_temp.purchase('first')->>'replayed','true','identical key replays before open-order rejection');
select throws_ok($$select pg_temp.purchase('second')$$,'22023','An open order already exists for this course.','different key cannot create second open online order');
select throws_ok($$select pg_temp.purchase('bank','bank_transfer')$$,'22023','An open order already exists for this course.','different payment method cannot create second open order');
select is(public.csa265_create_checkout_order('26500000-0000-0000-0000-000000000002','26500000-0000-0000-0000-000000000012','aal1','first','26500000-0000-0000-0000-000000000021','online')->>'replayed','false','different buyer may purchase same course');
select is(pg_temp.purchase('other','online','26500000-0000-0000-0000-000000000022')->>'replayed','false','different course remains independent');
update public.orders set status='cancelled' where id=(select (result->'data'->>'order_id')::uuid from original);
select is(pg_temp.purchase('after-cancel')->>'replayed','false','closed order permits a new purchase');
select ok(not has_function_privilege('authenticated','public.csa265_create_checkout_order(uuid,uuid,text,text,uuid,text,uuid)','EXECUTE'),'students cannot forge trusted actor parameters');
select is((select count(*)::integer from public.enrollments where user_id='26500000-0000-0000-0000-000000000001'),0,'order creation never grants enrollment');
select * from finish();
rollback;
