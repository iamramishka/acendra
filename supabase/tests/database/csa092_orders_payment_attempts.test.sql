begin;
create temporary sequence csa092_assertion;
grant usage,select on sequence csa092_assertion to anon,authenticated,service_role;
create function pg_temp.assert_ok(condition boolean,description text) returns text language plpgsql as $$
begin
 if condition is distinct from true then raise exception 'Assertion failed: %',description; end if;
 return 'ok '||nextval('pg_temp.csa092_assertion')||' - '||description;
end; $$;
create function pg_temp.expect_error(command text,expected_state text,description text) returns text language plpgsql as $$
declare actual_state text;
begin
 begin execute command; exception when others then actual_state:=sqlstate; end;
 return pg_temp.assert_ok(actual_state=expected_state,description);
end; $$;
select pg_temp.assert_ok((select count(*)=2 from pg_class where oid in ('public.orders'::regclass,'public.payment_attempts'::regclass) and relrowsecurity),'financial tables enable RLS');
insert into auth.users(id) values ('09200000-0000-0000-0000-000000000001'),('09200000-0000-0000-0000-000000000002');
insert into public.profiles(id,display_name) values ('09200000-0000-0000-0000-000000000001','Buyer A'),('09200000-0000-0000-0000-000000000002','Buyer B') on conflict(id) do nothing;
insert into public.courses(id,slug,title,price_minor) values ('09200000-0000-0000-0000-000000000003','csa092-course','Synthetic course',10000);
insert into public.orders(id,order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method,created_at,updated_at) values
 ('09200000-0000-0000-0000-000000000011','CSA092-A','09200000-0000-0000-0000-000000000001','09200000-0000-0000-0000-000000000003','Original title',10000,'LKR','online',now()-interval '1 day',now()-interval '1 day'),
 ('09200000-0000-0000-0000-000000000012','CSA092-B','09200000-0000-0000-0000-000000000002','09200000-0000-0000-0000-000000000003','Original title',10000,'LKR','bank_transfer',now()-interval '1 day',now()-interval '1 day');
insert into public.payment_attempts(id,order_id,method,amount_minor,currency_code) values ('09200000-0000-0000-0000-000000000021','09200000-0000-0000-0000-000000000011','online',10000,'LKR');
select pg_temp.assert_ok((select status='created' and access_duration_snapshot_days is null and paid_at is null from public.orders where order_number='CSA092-A'),'order defaults unfulfilled lifetime snapshot');
select pg_temp.assert_ok((select status='initialized' and completed_at is null from public.payment_attempts where id='09200000-0000-0000-0000-000000000021'),'attempt defaults incomplete');
select pg_temp.expect_error(format('update public.orders set %I=%s where order_number=''CSA092-A''',col,val),'23514','immutable order field '||col)
from (values ('buyer_id',quote_literal('09200000-0000-0000-0000-000000000002')),('course_id',quote_literal('09200000-0000-0000-0000-000000000099')),('order_number',quote_literal('Changed')),('course_title_snapshot',quote_literal('Changed')),('amount_minor','20000'),('currency_code',quote_literal('USD')),('payment_method',quote_literal('bank_transfer')),('created_at','now()'),('access_duration_snapshot_days','30')) cases(col,val);
select pg_temp.expect_error(format('update public.payment_attempts set %I=%s where id=''09200000-0000-0000-0000-000000000021''',col,val),'23514','immutable attempt field '||col)
from (values ('order_id',quote_literal('09200000-0000-0000-0000-000000000012')),('method',quote_literal('bank_transfer')),('amount_minor','1'),('currency_code',quote_literal('USD')),('created_at','now()+interval ''1 day''')) cases(col,val);
select pg_temp.expect_error(format('insert into public.payment_attempts(order_id,method,amount_minor,currency_code) values (''09200000-0000-0000-0000-000000000011'',%L,%s,%L)',method,amount,currency),'23503','attempt must match order terms '||label)
from (values ('bank_transfer','10000','LKR','method'),('online','9999','LKR','amount')) cases(method,amount,currency,label);
select pg_temp.expect_error($q$insert into public.orders(order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method) values ('CSA092-INVALID','09200000-0000-0000-0000-000000000099','09200000-0000-0000-0000-000000000003','Title',0,'LKR','online')$q$,'23503','buyer FK required');
select pg_temp.expect_error($q$insert into public.orders(order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method) values ('CSA092-INVALID','09200000-0000-0000-0000-000000000001','09200000-0000-0000-0000-000000000099','Title',0,'LKR','online')$q$,'23503','course FK required');
select pg_temp.expect_error($q$delete from public.orders where order_number='CSA092-A'$q$,'23503','order cannot cascade attempts');
select pg_temp.expect_error($q$delete from public.courses where slug='csa092-course'$q$,'23503','course cannot cascade orders');
select pg_temp.expect_error($q$delete from public.profiles where id='09200000-0000-0000-0000-000000000001'$q$,'23503','buyer cannot cascade financial history');
select pg_temp.expect_error($q$update public.orders set status='unknown' where order_number='CSA092-A'$q$,'23514','unknown order status rejected');
select pg_temp.expect_error($q$update public.payment_attempts set status='unknown'$q$,'23514','unknown attempt status rejected');
select pg_temp.expect_error(format($q$insert into public.orders(order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method,status,access_duration_snapshot_days) values (%L,'09200000-0000-0000-0000-000000000001','09200000-0000-0000-0000-000000000003',%L,%s,%L,%L,%L,%s)$q$,number,title,amount,currency,method,status,duration),'23514','invalid new order '||label)
from (values ('','Title','0','LKR','online','created','null','empty number'),('CSA092-INVALID','','0','LKR','online','created','null','empty title'),('CSA092-INVALID','Title','-1','LKR','online','created','null','negative money'),('CSA092-INVALID','Title','0','USD','online','created','null','unsupported currency'),('CSA092-INVALID','Title','0','LKR','card','created','null','unsupported method'),('CSA092-INVALID','Title','0','LKR','online','success','null','unsupported state'),('CSA092-INVALID','Title','0','LKR','online','created','30','unapproved paid expiry')) cases(number,title,amount,currency,method,status,duration,label);
select pg_temp.expect_error($q$insert into public.orders(order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method) values ('CSA092-A','09200000-0000-0000-0000-000000000001','09200000-0000-0000-0000-000000000003','Title',0,'LKR','online')$q$,'23505','order number unique');
select pg_temp.expect_error($q$update public.payment_attempts set completed_at=created_at-interval '1 second'$q$,'23514','completion cannot precede attempt');
select pg_temp.expect_error($q$update public.orders set paid_at=created_at-interval '1 second' where order_number='CSA092-A'$q$,'23514','paid timestamp cannot precede purchase');
select pg_temp.expect_error($q$update public.payment_attempts set provider_transaction_id=chr(9)$q$,'23514','blank provider reference rejected');
update public.courses set title='Changed course',price_minor=20000 where slug='csa092-course';
select pg_temp.assert_ok((select amount_minor=10000 and course_title_snapshot='Original title' from public.orders where order_number='CSA092-A'),'catalog changes preserve purchase snapshot');
update public.orders set status='pending_payment' where order_number='CSA092-A';
select pg_temp.assert_ok((select updated_at>created_at from public.orders where order_number='CSA092-A'),'order timestamp updates');
select set_config('request.jwt.claims','{"sub":"09200000-0000-0000-0000-000000000001","role":"authenticated"}',true);
set local role authenticated;
select pg_temp.assert_ok((select count(*)=1 from public.orders),'buyer A sees own order only');
select pg_temp.assert_ok((select count(*)=0 from public.orders where order_number='CSA092-B'),'foreign guessed order hidden');
select pg_temp.expect_error('select * from public.payment_attempts','42501','buyer cannot read provider attempt metadata');
select pg_temp.expect_error('update public.orders set status=''paid''','42501','buyer cannot mark paid');
select pg_temp.expect_error('insert into public.orders default values','42501','buyer cannot create authoritative orders');
select pg_temp.expect_error('delete from public.orders','42501','buyer cannot delete financial history');
reset role;
select set_config('request.jwt.claims','{"sub":"09200000-0000-0000-0000-000000000002","role":"authenticated","app_metadata":{"role":"super_admin"}}',true);
set local role authenticated;
select pg_temp.assert_ok((select count(*)=1 and bool_and(order_number='CSA092-B') from public.orders),'buyer B isolation ignores forged admin claim');
reset role;
update auth.users set banned_until=now()+interval '1 day' where id='09200000-0000-0000-0000-000000000002';
set local role authenticated;
select pg_temp.assert_ok((select count(*)=0 from public.orders),'current account ban denies old token');
reset role;
select set_config('request.jwt.claims','{}',true);
set local role authenticated;
select pg_temp.assert_ok((select count(*)=0 from public.orders),'missing identity denies all order reads');
reset role;
set local role anon;
select pg_temp.expect_error('select * from public.orders','42501','guest denied orders');
reset role;
set local role service_role;
select pg_temp.expect_error('select * from public.orders','42501','service access withheld until trusted workflow');
reset role;
select pg_temp.assert_ok(not has_function_privilege(r,'public.csa092_preserve_financial_terms()','EXECUTE'),r||' cannot invoke trigger helper') from unnest(array['anon','authenticated','service_role']) r;
select '1..'||last_value from pg_temp.csa092_assertion;
rollback;
