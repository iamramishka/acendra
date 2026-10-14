begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select plan(14);
select ok(not has_function_privilege('anon','public.csa179_read_bank_transfer(uuid,uuid,text,uuid,boolean)','EXECUTE'),'anonymous cannot call private bank reads');
select ok(not has_function_privilege('authenticated','public.csa179_read_bank_transfer(uuid,uuid,text,uuid,boolean)','EXECUTE'),'authenticated cannot forge service actor parameters');
select ok(has_function_privilege('service_role','public.csa179_read_bank_transfer(uuid,uuid,text,uuid,boolean)','EXECUTE'),'trusted service owns read invocation');
select throws_ok($$select public.csa179_read_bank_transfer(null,null,'aal2',null,true)$$,'22023','Invalid read request.','missing actor/session fail closed');
select throws_ok($$select public.csa179_read_bank_transfer('11111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222','aal2','33333333-3333-4333-8333-333333333333',true)$$,'22023','Invalid read request.','mixed queue/order mode fails closed');
select throws_ok($$select public.csa179_read_bank_transfer('11111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222','aal2',null,true)$$,'42501','Current account required.','nonexistent account cannot read queue');
insert into auth.users(id) values('17900000-0000-0000-0000-000000000001'),('17900000-0000-0000-0000-000000000002'),('17900000-0000-0000-0000-000000000003');
insert into auth.sessions(id,user_id,aal,not_after) values
('17900000-0000-0000-0000-000000000011','17900000-0000-0000-0000-000000000001','aal2',now()+interval '1 day'),
('17900000-0000-0000-0000-000000000012','17900000-0000-0000-0000-000000000002','aal2',now()+interval '1 day'),
('17900000-0000-0000-0000-000000000013','17900000-0000-0000-0000-000000000003','aal2',now()+interval '1 day');
insert into public.user_roles(user_id,role_id) select u,r.id from unnest(array['17900000-0000-0000-0000-000000000001'::uuid,'17900000-0000-0000-0000-000000000002'::uuid]) u cross join public.roles r where r.code='finance_admin';
insert into public.courses(id,slug,title,price_minor,status,published_at) values('17900000-0000-0000-0000-000000000021','bank-read-test','Synthetic bank course',12345,'published',now());
insert into app_private.bank_account_versions(id,bank_account_id,version,bank_name,account_holder,account_number,branch_name) values('17900000-0000-0000-0000-000000000031','17900000-0000-0000-0000-000000000032',1,'Synthetic bank','Synthetic holder','SYNTHETIC-ONLY','Synthetic branch');
create temporary table csa108_orders as select key,public.csa098_create_checkout_order('17900000-0000-0000-0000-000000000001','17900000-0000-0000-0000-000000000011','aal2',key,'17900000-0000-0000-0000-000000000021','bank_transfer','17900000-0000-0000-0000-000000000031')->'data' data from unnest(array['approve','reject','reuse','rollback']) key;
select is(public.csa179_read_bank_transfer('17900000-0000-0000-0000-000000000001','17900000-0000-0000-0000-000000000011','aal2',(select (data->>'order_id')::uuid from csa108_orders where key='approve'),false)->>'status','awaiting_receipt','owner sees actual initial status');
select throws_ok($$select public.csa179_read_bank_transfer('17900000-0000-0000-0000-000000000003','17900000-0000-0000-0000-000000000013','aal2',(select (data->>'order_id')::uuid from csa108_orders where key='approve'),false)$$,'P0002','Order unavailable.','other student cannot see order');
select throws_ok($$select public.csa179_read_bank_transfer('17900000-0000-0000-0000-000000000003','17900000-0000-0000-0000-000000000013','aal2',null,true)$$,'42501','Current finance authority required.','student cannot read finance queue');
select throws_ok($$select public.csa179_read_bank_transfer('17900000-0000-0000-0000-000000000002','17900000-0000-0000-0000-000000000012','aal1',null,true)$$,'42501','Current verified session required.','finance queue rejects non-MFA');
select is(public.csa179_read_bank_transfer('17900000-0000-0000-0000-000000000002','17900000-0000-0000-0000-000000000012','aal2',null,true)->'items','[]'::jsonb,'pending-payment orders do not invent submitted queue entries');
update public.user_roles set revoked_at=clock_timestamp() where user_id='17900000-0000-0000-0000-000000000002';
select throws_ok($$select public.csa179_read_bank_transfer('17900000-0000-0000-0000-000000000002','17900000-0000-0000-0000-000000000012','aal2',null,true)$$,'42501','Current finance authority required.','revoked finance role cannot read queue');
update auth.sessions set not_after=clock_timestamp()-interval '1 second' where id='17900000-0000-0000-0000-000000000011';
select throws_ok($$select public.csa179_read_bank_transfer('17900000-0000-0000-0000-000000000001','17900000-0000-0000-0000-000000000011','aal2',(select (data->>'order_id')::uuid from csa108_orders where key='approve'),false)$$,'42501','Current verified session required.','expired session cannot read owner status');
select ok(not has_table_privilege('authenticated','public.bank_transfer_submissions','SELECT'),'direct submission table remains revoked');
select * from finish();
rollback;


