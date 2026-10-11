begin;
create temporary sequence csa096_assertion;
grant usage,select on sequence csa096_assertion to anon,authenticated,service_role;
create function pg_temp.assert_ok(condition boolean,description text) returns text language plpgsql as $$
begin
 if condition is distinct from true then raise exception 'Assertion failed: %',description; end if;
 return 'ok '||nextval('pg_temp.csa096_assertion')||' - '||description;
end; $$;
create function pg_temp.expect_error(command text,expected_state text,description text) returns text language plpgsql as $$
declare actual_state text;
begin
 begin execute command; exception when others then actual_state:=sqlstate; end;
 return pg_temp.assert_ok(actual_state=expected_state,description||coalesce(' (actual '||actual_state||')',' (unexpected success)'));
end; $$;
insert into auth.users(id) select ('09600000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid from generate_series(1,3)n;
insert into public.profiles(id,display_name) select id,'Synthetic finance fixture' from auth.users where id::text like '09600000%' on conflict(id) do nothing;
insert into public.courses(id,slug,title,price_minor) values ('09600000-0000-0000-0000-000000000010','csa096-a','Synthetic finance course',10000),('09600000-0000-0000-0000-000000000011','csa096-b','Other course',10000);
insert into public.orders(id,order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method,created_at)
select ('09600000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,'CSA096-'||n,'09600000-0000-0000-0000-000000000001','09600000-0000-0000-0000-000000000010','Snapshot',10000,'LKR',case when n=22 then 'bank_transfer' else 'online' end,now()-interval '1 day' from generate_series(20,23)n;
insert into public.payment_attempts(id,order_id,method,amount_minor,currency_code,provider,provider_merchant_id,provider_environment)
select ('09600000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,'09600000-0000-0000-0000-000000000020','online',10000,'LKR','payhere',case when n=33 then 'merchant-b' else 'merchant-a' end,case when n=32 then 'production' else 'sandbox' end from generate_series(30,33)n;
insert into app_private.payment_events(id,payment_attempt_id,provider,provider_merchant_id,provider_environment,provider_event_id,event_type,payload_hash) values ('09600000-0000-0000-0000-000000000040','09600000-0000-0000-0000-000000000030','payhere','merchant-a','sandbox','event-1','payment',repeat('a',64));
select pg_temp.expect_error($q$insert into app_private.payment_events(payment_attempt_id,provider,provider_merchant_id,provider_environment,provider_event_id,event_type,payload_hash) values ('09600000-0000-0000-0000-000000000030','payhere','merchant-a','sandbox','event-1','payment',repeat('a',64))$q$,'23505','same scoped event identity cannot replay');
insert into app_private.payment_events(payment_attempt_id,provider,provider_merchant_id,provider_environment,provider_event_id,event_type,payload_hash)
select id,provider,provider_merchant_id,provider_environment,'event-1','payment',repeat('a',64) from public.payment_attempts where id in ('09600000-0000-0000-0000-000000000032','09600000-0000-0000-0000-000000000033');
select pg_temp.assert_ok((select count(*)=3 from app_private.payment_events where provider_event_id='event-1'),'merchant and environment distinguish event identity');
select pg_temp.expect_error($q$insert into app_private.payment_events(payment_attempt_id,provider,provider_merchant_id,provider_environment,provider_event_id,event_type,payload_hash) values ('09600000-0000-0000-0000-000000000030','payhere','wrong-merchant','sandbox','event-2','payment',repeat('a',64))$q$,'23503','event must match bound attempt merchant');
select pg_temp.expect_error($q$update public.payment_attempts set provider_environment='production' where id='09600000-0000-0000-0000-000000000030'$q$,'23514','bound attempt environment immutable');
select pg_temp.expect_error(format('update app_private.payment_events set %I=%s where id=''09600000-0000-0000-0000-000000000040''',col,val),'23514','event evidence immutable: '||col)
from (values ('provider_event_id',quote_literal('changed')),('payload_hash',quote_literal(repeat('b',64))),('received_at','now()+interval ''1 day'''))cases(col,val);
select pg_temp.expect_error($q$delete from app_private.payment_events$q$,'23514','event deletion denied');
select pg_temp.expect_error($q$truncate app_private.payment_events$q$,'23514','event truncate denied');
select pg_temp.expect_error($q$update app_private.payment_events set processing_status='processed' where id='09600000-0000-0000-0000-000000000040'$q$,'23514','processed event needs processing timestamp');
update app_private.payment_events set processing_status='processed',processed_at=now() where id='09600000-0000-0000-0000-000000000040';
select pg_temp.expect_error($q$update app_private.payment_events set processing_status='received',processed_at=null where id='09600000-0000-0000-0000-000000000040'$q$,'23514','final event outcome cannot reset');
-- Exact settlement identity is independently verified evidence, never a callback reference.
insert into app_private.verified_settlements(id,order_id,method,amount_minor,currency_code,provider,provider_merchant_id,provider_environment,external_settlement_id,verification_method,evidence_reference,confirmed_at)
values ('09600000-0000-0000-0000-000000000050','09600000-0000-0000-0000-000000000020','online',10000,'LKR','payhere','merchant-a','sandbox','payment-1','provider_retrieval','synthetic-retrieval',now());
select pg_temp.expect_error(format($q$insert into app_private.verified_settlements(order_id,method,amount_minor,currency_code,provider,provider_merchant_id,provider_environment,external_settlement_id,verification_method,evidence_reference,confirmed_at) values ('09600000-0000-0000-0000-000000000021','online',%s,'LKR','payhere','merchant-a','sandbox',%L,%L,'fixture',now())$q$,amount,identity,verification),expected,'settlement rejects '||label)
from (values ('9999','other','provider_retrieval','23503','amount mismatch'),('10000','payment-1','provider_retrieval','23505','reuse on another order'),('10000','other','callback','23514','callback-only proof'))cases(amount,identity,verification,expected,label);
insert into app_private.verified_settlements(order_id,method,amount_minor,currency_code,provider,provider_merchant_id,provider_environment,external_settlement_id,verification_method,evidence_reference,confirmed_at)
values ('09600000-0000-0000-0000-000000000021','online',10000,'LKR','payhere','merchant-a','production','payment-1','provider_retrieval','fixture',now()),('09600000-0000-0000-0000-000000000021','online',10000,'LKR','payhere','merchant-b','sandbox','payment-1','provider_retrieval','fixture',now());
select pg_temp.assert_ok((select count(*)=3 from app_private.verified_settlements where external_settlement_id='payment-1'),'environment and merchant distinguish verified payments');
select pg_temp.expect_error($q$update app_private.verified_settlements set evidence_reference='changed'$q$,'23514','settlement evidence immutable');
select pg_temp.expect_error($q$delete from app_private.verified_settlements$q$,'23514','settlement history cannot delete');
select pg_temp.expect_error($q$truncate app_private.verified_settlements cascade$q$,'23514','settlement history cannot truncate');
create function pg_temp.pay_without_evidence() returns void language plpgsql as $$ begin update public.orders set status='paid',paid_at=now() where order_number='CSA096-23'; set constraints all immediate; end; $$;
select pg_temp.expect_error('select pg_temp.pay_without_evidence()','23514','deferred check prevents paid order without settlement');
select pg_temp.assert_ok((select status='created' and paid_at is null from public.orders where order_number='CSA096-23'),'failed financial transaction rolls back paid state');
update public.orders set status='paid',paid_at=now() where order_number='CSA096-20';
set constraints all immediate;
select pg_temp.expect_error($q$update public.orders set paid_at=now()+interval '1 second' where order_number='CSA096-20'$q$,'23514','first fulfillment time immutable');
set constraints all deferred;
-- Bank receipt ownership, method, active uniqueness and independent review.
insert into app_private.media_assets(id,asset_type,storage_provider,bucket_name,object_path,mime_type,size_bytes,checksum_sha256,uploaded_by,validation_status,validated_at)
select ('09600000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,case when n=62 then 'course_pdf' else 'bank_receipt' end,'supabase','private-receipts','fixture-'||n,'application/pdf',100,repeat('a',64),case when n=61 then '09600000-0000-0000-0000-000000000002'::uuid else '09600000-0000-0000-0000-000000000001'::uuid end,'validated',now() from generate_series(60,62)n;
select pg_temp.expect_error(format($q$insert into public.bank_transfer_submissions(order_id,submitted_by,receipt_asset_id) values (%L,%L,%L)$q$,order_id,buyer,asset),'23514','bank submission rejects '||label)
from (values ('09600000-0000-0000-0000-000000000020','09600000-0000-0000-0000-000000000001','09600000-0000-0000-0000-000000000060','online order'),('09600000-0000-0000-0000-000000000022','09600000-0000-0000-0000-000000000002','09600000-0000-0000-0000-000000000061','foreign buyer'),('09600000-0000-0000-0000-000000000022','09600000-0000-0000-0000-000000000001','09600000-0000-0000-0000-000000000061','foreign receipt'),('09600000-0000-0000-0000-000000000022','09600000-0000-0000-0000-000000000001','09600000-0000-0000-0000-000000000062','course PDF as receipt'))cases(order_id,buyer,asset,label);
insert into public.bank_transfer_submissions(id,order_id,submitted_by,receipt_asset_id,status,submitted_at) values ('09600000-0000-0000-0000-000000000070','09600000-0000-0000-0000-000000000022','09600000-0000-0000-0000-000000000001','09600000-0000-0000-0000-000000000060','submitted',now());
select pg_temp.expect_error($q$insert into public.bank_transfer_submissions(order_id,submitted_by) values ('09600000-0000-0000-0000-000000000022','09600000-0000-0000-0000-000000000001')$q$,'23505','only one concurrent active submission per order');
select pg_temp.expect_error($q$update public.bank_transfer_submissions set status='rejected',reviewed_by=submitted_by,reviewed_at=now(),public_rejection_reason='Rejected' where id='09600000-0000-0000-0000-000000000070'$q$,'23514','reviewer cannot approve own submission');
select pg_temp.expect_error($q$update public.bank_transfer_submissions set status='approved',reviewed_by='09600000-0000-0000-0000-000000000003',reviewed_at=now() where id='09600000-0000-0000-0000-000000000070'$q$,'23514','receipt review alone cannot approve unfunded bank order');
update public.bank_transfer_submissions set status='rejected',reviewed_by='09600000-0000-0000-0000-000000000003',reviewed_at=now(),public_rejection_reason='Synthetic rejected evidence' where id='09600000-0000-0000-0000-000000000070';
select pg_temp.expect_error($q$update public.bank_transfer_submissions set status='submitted' where id='09600000-0000-0000-0000-000000000070'$q$,'23514','completed bank review immutable');
insert into public.bank_transfer_submissions(order_id,submitted_by) values ('09600000-0000-0000-0000-000000000022','09600000-0000-0000-0000-000000000001');
select pg_temp.assert_ok((select count(*)=2 from public.bank_transfer_submissions where order_id='09600000-0000-0000-0000-000000000022'),'resubmission preserves rejected evidence history');
insert into app_private.verified_settlements(id,order_id,method,amount_minor,currency_code,receiving_bank_account_scope,external_settlement_id,verification_method,evidence_reference,confirmed_at) values ('09600000-0000-0000-0000-000000000051','09600000-0000-0000-0000-000000000022','bank_transfer',10000,'LKR','synthetic-bank-account','bank-credit-1','bank_reconciliation','fixture',now());
select pg_temp.expect_error($q$insert into app_private.verified_settlements(order_id,method,amount_minor,currency_code,receiving_bank_account_scope,external_settlement_id,verification_method,evidence_reference,confirmed_at) values ('09600000-0000-0000-0000-000000000022','bank_transfer',10000,'LKR','synthetic-bank-account','bank-credit-1','bank_reconciliation','fixture',now())$q$,'23505','bank credit identity cannot be reused');
select pg_temp.expect_error($q$update public.bank_transfer_submissions set receipt_asset_id='09600000-0000-0000-0000-000000000060',submitted_at=now(),status='approved',reviewed_by='09600000-0000-0000-0000-000000000003',reviewed_at=now(),settlement_id='09600000-0000-0000-0000-000000000050' where status='awaiting_receipt' and order_id='09600000-0000-0000-0000-000000000022'$q$,'23514','online settlement cannot approve a bank submission');
update public.bank_transfer_submissions set receipt_asset_id='09600000-0000-0000-0000-000000000060',submitted_at=now(),status='approved',reviewed_by='09600000-0000-0000-0000-000000000003',reviewed_at=now(),settlement_id='09600000-0000-0000-0000-000000000051' where status='awaiting_receipt' and order_id='09600000-0000-0000-0000-000000000022';
select pg_temp.assert_ok((select count(*)=1 from public.bank_transfer_submissions where status='approved' and settlement_id='09600000-0000-0000-0000-000000000051'),'independent reviewer and exact verified bank settlement accepted');
-- Purchased source must match beneficiary, course, method, settlement and original fulfillment.
insert into public.enrollments(id,user_id,course_id,status,granted_at) values ('09600000-0000-0000-0000-000000000080','09600000-0000-0000-0000-000000000001','09600000-0000-0000-0000-000000000010','active',now()),('09600000-0000-0000-0000-000000000081','09600000-0000-0000-0000-000000000002','09600000-0000-0000-0000-000000000010','active',now()),('09600000-0000-0000-0000-000000000082','09600000-0000-0000-0000-000000000001','09600000-0000-0000-0000-000000000011','active',now());
select pg_temp.expect_error($q$insert into public.enrollments(user_id,course_id,status,granted_at) values ('09600000-0000-0000-0000-000000000001','09600000-0000-0000-0000-000000000010','active',now())$q$,'23505','one enrollment projection per user course');
select pg_temp.expect_error(format($q$insert into public.enrollment_grants(enrollment_id,user_id,course_id,source_type,source_order_id,settlement_id,valid_from) values (%L,%L,%L,%L,'09600000-0000-0000-0000-000000000020','09600000-0000-0000-0000-000000000050',now())$q$,enrollment,buyer,course,method),'23514','purchased grant rejects '||label)
from (values ('09600000-0000-0000-0000-000000000081','09600000-0000-0000-0000-000000000002','09600000-0000-0000-0000-000000000010','online_payment','foreign purchaser'),('09600000-0000-0000-0000-000000000082','09600000-0000-0000-0000-000000000001','09600000-0000-0000-0000-000000000011','online_payment','foreign course'),('09600000-0000-0000-0000-000000000080','09600000-0000-0000-0000-000000000001','09600000-0000-0000-0000-000000000010','bank_transfer','wrong funding method'))cases(enrollment,buyer,course,method,label);
select pg_temp.expect_error($q$insert into public.enrollment_grants(enrollment_id,user_id,course_id,source_type,source_order_id,valid_from) values ('09600000-0000-0000-0000-000000000080','09600000-0000-0000-0000-000000000001','09600000-0000-0000-0000-000000000010','online_payment','09600000-0000-0000-0000-000000000020',now())$q$,'23514','purchased grant requires independently verified settlement');
create function pg_temp.wrong_grant_time() returns void language plpgsql as $$ begin insert into public.enrollment_grants(enrollment_id,user_id,course_id,source_type,source_order_id,settlement_id,valid_from) values ('09600000-0000-0000-0000-000000000080','09600000-0000-0000-0000-000000000001','09600000-0000-0000-0000-000000000010','online_payment','09600000-0000-0000-0000-000000000020','09600000-0000-0000-0000-000000000050',now()+interval '1 second'); set constraints all immediate; end; $$;
select pg_temp.expect_error('select pg_temp.wrong_grant_time()','23514','deferred source time matches first fulfillment');
insert into public.enrollment_grants(id,enrollment_id,user_id,course_id,source_type,source_order_id,settlement_id,valid_from) values ('09600000-0000-0000-0000-000000000090','09600000-0000-0000-0000-000000000080','09600000-0000-0000-0000-000000000001','09600000-0000-0000-0000-000000000010','online_payment','09600000-0000-0000-0000-000000000020','09600000-0000-0000-0000-000000000050',now());
set constraints all immediate;
select pg_temp.expect_error($q$insert into public.enrollment_grants(enrollment_id,user_id,course_id,source_type,source_order_id,settlement_id,valid_from) select enrollment_id,user_id,course_id,source_type,source_order_id,settlement_id,valid_from from public.enrollment_grants where id='09600000-0000-0000-0000-000000000090'$q$,'23505','one purchased grant per funding order and settlement');
update public.enrollment_grants set invalidated_at=now(),invalidation_reason='Synthetic refund' where id='09600000-0000-0000-0000-000000000090';
select pg_temp.expect_error($q$update public.enrollment_grants set invalidated_at=null,invalidation_reason=null where id='09600000-0000-0000-0000-000000000090'$q$,'23514','invalidated source cannot resurrect');
select pg_temp.expect_error($q$update public.enrollment_grants set valid_from=now()+interval '1 second' where id='09600000-0000-0000-0000-000000000090'$q$,'23514','source fulfillment history immutable');
insert into app_private.idempotency_records(principal_scope,operation,idempotency_key,request_hash,safe_result) values ('buyer-a','checkout','key',repeat('a',64),'{}'),('buyer-b','checkout','key',repeat('a',64),'{}'),('buyer-a','other-operation','key',repeat('a',64),'{}');
select pg_temp.expect_error($q$insert into app_private.idempotency_records values ('buyer-a','checkout','key',repeat('a',64),'{}',now())$q$,'23505','idempotency key unique within principal and operation');
select pg_temp.assert_ok((select count(*)=3 from app_private.idempotency_records where idempotency_key='key'),'idempotency keys isolated by principal and operation');
select pg_temp.expect_error($q$update app_private.idempotency_records set safe_result='{"changed":true}'$q$,'23514','idempotency result immutable');
select pg_temp.expect_error($q$insert into app_private.idempotency_records values (null,'checkout','new',repeat('a',64),'{}',now())$q$,'23502','idempotency principal cannot be absent');
-- Direct clients never write financial truth, regardless of forged roles.
select set_config('request.jwt.claims','{"sub":"09600000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{"role":"super_admin"}}',true);
set local role authenticated;
select pg_temp.assert_ok((select count(*)=2 from public.enrollments),'buyer reads only own safe enrollment projections');
select pg_temp.expect_error('insert into public.enrollments default values','42501','buyer cannot create entitlement projection');
select pg_temp.expect_error('select * from public.enrollment_grants','42501','buyer cannot read private funding sources');
select pg_temp.expect_error('select * from public.bank_transfer_submissions','42501','buyer cannot read private receipt references');
select pg_temp.expect_error('select * from app_private.payment_events','42501','forged role cannot access payment evidence');
reset role;
update auth.users set banned_until=now()+interval '1 day' where id='09600000-0000-0000-0000-000000000001';
set local role authenticated;
select pg_temp.assert_ok((select count(*)=0 from public.enrollments),'current account revocation denies stale token enrollment reads');
reset role;
set local role anon;
select pg_temp.expect_error('select * from public.enrollments','42501','anonymous enrollment read denied');
reset role;
set local role service_role;
select pg_temp.expect_error('select * from app_private.verified_settlements','42501','service role cannot bypass explicit settlement grants');
reset role;
select '1..'||last_value from pg_temp.csa096_assertion;
rollback;

