-- Synthetic transactional database assertions; actual file parser is verified by Edge tests separately.
begin;
create temporary sequence csa121_assertion;
create function pg_temp.assert_ok(condition boolean,description text) returns text language plpgsql as $$begin if condition is distinct from true then raise exception 'Assertion failed: %',description; end if; return 'ok '||nextval('pg_temp.csa121_assertion')||' - '||description; end;$$;
create function pg_temp.expect_error(command text,expected text,description text) returns text language plpgsql as $$declare actual text; begin begin execute command; exception when others then actual:=sqlstate; end; return pg_temp.assert_ok(actual=expected,description); end;$$;
insert into auth.users(id) values('12100000-0000-0000-0000-000000000001'),('12100000-0000-0000-0000-000000000002'),('12100000-0000-0000-0000-000000000003');
insert into auth.sessions(id,user_id,aal,not_after) values
('12100000-0000-0000-0000-000000000011','12100000-0000-0000-0000-000000000001','aal2',now()+interval '1 day'),
('12100000-0000-0000-0000-000000000012','12100000-0000-0000-0000-000000000002','aal2',now()+interval '1 day'),
('12100000-0000-0000-0000-000000000013','12100000-0000-0000-0000-000000000003','aal2',now()+interval '1 day');
insert into public.user_roles(user_id,role_id) select u,r.id from unnest(array['12100000-0000-0000-0000-000000000001'::uuid,'12100000-0000-0000-0000-000000000002'::uuid]) u cross join public.roles r where r.code='finance_admin';
insert into public.courses(id,slug,title,price_minor,status,published_at) values('12100000-0000-0000-0000-000000000021','csa121-bank-test','Synthetic bank course',12345,'published',now());
insert into app_private.bank_account_versions(id,bank_account_id,version,bank_name,account_holder,account_number,branch_name) values('12100000-0000-0000-0000-000000000031','12100000-0000-0000-0000-000000000032',1,'Synthetic bank','Synthetic holder','SYNTHETIC-ONLY','Synthetic branch');
create temporary table csa121_orders as select key,public.csa098_create_checkout_order('12100000-0000-0000-0000-000000000001','12100000-0000-0000-0000-000000000011','aal2',key,'12100000-0000-0000-0000-000000000021','bank_transfer','12100000-0000-0000-0000-000000000031')->'data' data from unnest(array['approve','reject','reuse','rollback']) key;
create function pg_temp.prepare(orderkey text,key text,digest text default repeat('a',64),size bigint default 100,mime text default 'image/png',ext text default 'png') returns jsonb language sql as $$select public.csa108_prepare_receipt('12100000-0000-0000-0000-000000000001','12100000-0000-0000-0000-000000000011','aal2',key,(select (data->>'order_id')::uuid from csa121_orders where csa121_orders.key=orderkey),digest,size,mime,ext);$$;
create temporary table csa121_uploads(key text,data jsonb);
insert into csa121_uploads select key,pg_temp.prepare(key,key) from csa121_orders;
create function pg_temp.finalize(key text,digest text default repeat('a',64),inspection text default 'synthetic-policy-v1') returns jsonb language sql as $$select public.csa109_finalize_receipt('12100000-0000-0000-0000-000000000001','12100000-0000-0000-0000-000000000011','aal2',(select (data->>'upload_id')::uuid from csa121_uploads u where u.key=finalize.key),digest,100,'image/png',inspection);$$;
create function pg_temp.credit(key text,transaction text default 'synthetic-credit') returns jsonb language sql as $$select jsonb_build_object('destination_account_id','12100000-0000-0000-0000-000000000032','bank_transaction_id',transaction,'amount_minor','12345','currency','LKR','settled_at','2026-10-11T00:00:00Z','source','bank_statement','order_reference',(select data->>'order_number' from csa121_orders o where o.key=credit.key),'bank_credit_confirmed',true);$$;
create function pg_temp.review(key text,decision text default 'approve',credit jsonb default null,idempotency text default null,actor uuid default '12100000-0000-0000-0000-000000000002',session uuid default '12100000-0000-0000-0000-000000000012',aal text default 'aal2') returns jsonb language sql as $$select public.csa112_review_bank_transfer(actor,session,aal,coalesce(idempotency,'review-'||key),(select (data->>'submission_id')::uuid from csa121_uploads u where u.key=review.key),decision,case when decision='approve' then coalesce(credit,pg_temp.credit(key)) else credit end,case when decision='reject' then 'Unable to match settled credit' else null end,'PRIVATE synthetic reviewer note');$$;
-- New regressions for CSA121/124/125/126. Existing real races cover CSA123.
insert into storage.objects(bucket_id,name) select 'bank-receipts',data->>'object_path' from csa121_uploads;
select pg_temp.finalize(key) from csa121_uploads where key<>'reuse';
select pg_temp.assert_ok(not exists(select 1 from public.enrollment_grants where user_id='12100000-0000-0000-0000-000000000001'),'CSA124 pending receipts grant no paid access');
select pg_temp.review('reject','reject');
select pg_temp.assert_ok(not exists(select 1 from public.enrollments where user_id='12100000-0000-0000-0000-000000000001'),'CSA124 rejected receipt creates no enrollment projection');
select pg_temp.assert_ok((select status='pending_payment' from public.orders where id=(select (data->>'order_id')::uuid from csa121_orders where key='reject')),'CSA124 rejection preserves unpaid state');
select pg_temp.expect_error($q$select pg_temp.review('approve','approve',pg_temp.credit('approve')||'{"amount_minor":"12344"}')$q$,'22023','CSA121 underpayment rejected');
select pg_temp.expect_error($q$select pg_temp.review('approve','approve',pg_temp.credit('approve')||'{"amount_minor":"0"}')$q$,'22023','CSA121 zero amount rejected');
select pg_temp.expect_error($q$select pg_temp.review('approve','approve',pg_temp.credit('approve')||'{"currency":"lkr"}')$q$,'22023','CSA121 noncanonical currency rejected');
select pg_temp.assert_ok(not exists(select 1 from app_private.verified_settlements where order_id=(select (data->>'order_id')::uuid from csa121_orders where key='approve')),'CSA121 mismatches leave settlement absent');
-- Current account and session checks must apply even to otherwise valid reviewers.
update auth.sessions set not_after=clock_timestamp()-interval '1 second' where id='12100000-0000-0000-0000-000000000012';
select pg_temp.expect_error($q$select pg_temp.review('approve')$q$,'42501','CSA125 expired finance session denied');
update auth.sessions set not_after=now()+interval '1 day' where id='12100000-0000-0000-0000-000000000012';
update auth.users set banned_until=now()+interval '1 day' where id='12100000-0000-0000-0000-000000000002';
select pg_temp.expect_error($q$select pg_temp.review('approve','reject')$q$,'42501','CSA125 banned reviewer rejection denied');
update auth.users set banned_until=null where id='12100000-0000-0000-0000-000000000002';
select pg_temp.expect_error($q$select pg_temp.review('approve','reject',null,null,'12100000-0000-0000-0000-000000000003','12100000-0000-0000-0000-000000000013')$q$,'42501','CSA125 ordinary student cannot reject finance submission');
select pg_temp.assert_ok((select status='submitted' from public.bank_transfer_submissions where id=(select (data->>'submission_id')::uuid from csa121_uploads where key='approve')),'CSA125 denials preserve submission');
select set_config('request.jwt.claims','{"sub":"12100000-0000-0000-0000-000000000001","role":"authenticated"}',true);
grant usage,select on sequence csa121_assertion to authenticated;
set local role authenticated;
select pg_temp.assert_ok(not exists(select 1 from public.enrollments),'CSA124 pending/rejected buyer cannot see active enrollment');
select pg_temp.expect_error('select * from app_private.lesson_assets','42501','CSA124 protected lesson asset metadata denied');
select pg_temp.expect_error('select * from app_private.media_assets','42501','CSA124 private receipt/content asset paths denied');
select pg_temp.expect_error($q$select public.csa112_review_bank_transfer('12100000-0000-0000-0000-000000000001','12100000-0000-0000-0000-000000000011','aal2','forged','12100000-0000-0000-0000-000000000099','reject',null,'Forged',null)$q$,'42501','CSA125 browser cannot call trusted finance RPC');
reset role;
create function pg_temp.recovery_failure() returns trigger language plpgsql as $$begin raise exception 'Synthetic transaction recovery fault'; end;$$;
-- Fail after settlement/order/grant writes at each downstream persistence boundary.
create trigger csa126_fault before insert on app_private.bank_transfer_reviews for each row execute function pg_temp.recovery_failure();
select pg_temp.expect_error($q$select pg_temp.review('rollback')$q$,'P0001','CSA126 review evidence failure aborts transaction');
drop trigger csa126_fault on app_private.bank_transfer_reviews;
create trigger csa126_fault before insert on app_private.audit_logs for each row when(new.action='bank_transfer_approved') execute function pg_temp.recovery_failure();
select pg_temp.expect_error($q$select pg_temp.review('rollback')$q$,'P0001','CSA126 final audit failure aborts transaction');
drop trigger csa126_fault on app_private.audit_logs;
create trigger csa126_fault before insert on app_private.notification_outbox for each row execute function pg_temp.recovery_failure();
select pg_temp.expect_error($q$select pg_temp.review('rollback')$q$,'P0001','CSA126 post-grant outbox failure aborts transaction');
drop trigger csa126_fault on app_private.notification_outbox;
select pg_temp.assert_ok((select status='pending_verification' from public.orders where id=(select (data->>'order_id')::uuid from csa121_orders where key='rollback')),'CSA126 aborted attempts restore pending order');
select pg_temp.assert_ok((select status='submitted' and reviewed_by is null from public.bank_transfer_submissions where id=(select (data->>'submission_id')::uuid from csa121_uploads where key='rollback')),'CSA126 aborted attempts restore reviewable receipt');
select pg_temp.assert_ok(not exists(select 1 from app_private.verified_settlements where order_id=(select (data->>'order_id')::uuid from csa121_orders where key='rollback')) and not exists(select 1 from public.payment_attempts where order_id=(select (data->>'order_id')::uuid from csa121_orders where key='rollback')),'CSA126 settlement and attempt fully rolled back');
select pg_temp.assert_ok(not exists(select 1 from public.enrollment_grants where user_id='12100000-0000-0000-0000-000000000001') and not exists(select 1 from public.enrollments where user_id='12100000-0000-0000-0000-000000000001'),'CSA126 grant and projection fully rolled back');
select pg_temp.assert_ok(not exists(select 1 from app_private.idempotency_records where principal_scope='user:12100000-0000-0000-0000-000000000002' and operation='review-bank-transfer' and idempotency_key='review-rollback'),'CSA126 aborted request key remains retryable');
select pg_temp.assert_ok(pg_temp.review('rollback')->>'status'='approved','CSA126 same request succeeds after transient faults removed');
select pg_temp.assert_ok(pg_temp.review('rollback')->>'replayed'='true','CSA122 recovered review duplicate replays safely');
select pg_temp.assert_ok((select count(*)=1 from public.enrollment_grants where user_id='12100000-0000-0000-0000-000000000001') and (select count(*)=1 from app_private.notification_outbox where event_key='bank_review:'||(select data->>'submission_id' from csa121_uploads where key='rollback')),'CSA122 recovered duplicate grants and notifies once');
select '1..'||last_value from csa121_assertion;
rollback;