-- Actual transactional RPC behavior; all data is synthetic and rolled back.
begin;
create temporary sequence csa098_assertion;
grant usage,select on sequence csa098_assertion to anon,authenticated,service_role;
create function pg_temp.assert_ok(condition boolean,description text) returns text language plpgsql as $$
begin if condition is distinct from true then raise exception 'Assertion failed: %',description; end if;
return 'ok '||nextval('pg_temp.csa098_assertion')||' - '||description; end; $$;
create function pg_temp.expect_error(command text,expected_state text,description text) returns text language plpgsql as $$
declare actual_state text; begin
begin execute command; exception when others then actual_state:=sqlstate; end;
return pg_temp.assert_ok(actual_state=expected_state,description); end; $$;
insert into auth.users(id) values('09800000-0000-0000-0000-000000000001'),('09800000-0000-0000-0000-000000000002');
insert into auth.sessions(id,user_id,aal,not_after) values
('09800000-0000-0000-0000-000000000011','09800000-0000-0000-0000-000000000001','aal1',now()+interval '1 day'),
('09800000-0000-0000-0000-000000000012','09800000-0000-0000-0000-000000000002','aal1',now()+interval '1 day');
insert into public.courses(id,slug,title,price_minor,status,published_at) values
('09800000-0000-0000-0000-000000000021','csa098-published','Original title',12345,'published',now()),
('09800000-0000-0000-0000-000000000022','csa098-draft','Draft',12345,'draft',null);
create function pg_temp.checkout(key text,method text default 'online',course uuid default '09800000-0000-0000-0000-000000000021',bank uuid default null) returns jsonb language sql as $$
select public.csa098_create_checkout_order('09800000-0000-0000-0000-000000000001','09800000-0000-0000-0000-000000000011','aal1',key,course,method,bank); $$;
create temporary table csa098_result as select pg_temp.checkout('original') as response;
select pg_temp.assert_ok((select response->>'replayed'='false' and response->'data'->>'amount_minor'='12345' and response->'data'->>'status'='pending_payment' from csa098_result),'server priced pending order');
select pg_temp.assert_ok((select count(*)=1 from public.orders where buyer_id='09800000-0000-0000-0000-000000000001'),'one order');
select pg_temp.assert_ok((select count(*)=0 from public.payment_attempts where order_id=(select (response->'data'->>'order_id')::uuid from csa098_result)),'order creation does not create checkout attempt');
select pg_temp.assert_ok((select count(*)=0 from public.enrollments where user_id='09800000-0000-0000-0000-000000000001'),'creation never grants access');
select pg_temp.assert_ok(pg_temp.checkout('original')->>'replayed'='true','same request replays');
select pg_temp.assert_ok(pg_temp.checkout('original')->'data'=(select response->'data' from csa098_result),'replay exactly preserves safe result');
update public.courses set title='New title',price_minor=99999,status='archived' where id='09800000-0000-0000-0000-000000000021';
select pg_temp.assert_ok(pg_temp.checkout('original')->'data'=(select response->'data' from csa098_result),'catalog changes do not change replay');
select pg_temp.expect_error($q$select pg_temp.checkout('new-after-archive')$q$,'P0002','archived course unavailable for new order');
select pg_temp.expect_error($q$select pg_temp.checkout('draft','online','09800000-0000-0000-0000-000000000022')$q$,'P0002','draft course unavailable');
select pg_temp.expect_error($q$select pg_temp.checkout('original','bank_transfer')$q$,'22023','changed payload with existing key conflicts');
select pg_temp.expect_error($q$select pg_temp.checkout('','online')$q$,'22023','empty key rejected');
select pg_temp.expect_error($q$select pg_temp.checkout('bad key','online')$q$,'22023','noncanonical key rejected');
select pg_temp.expect_error($q$select pg_temp.checkout('bad-method','card')$q$,'22023','unsupported payment method rejected');
update public.courses set status='published' where id='09800000-0000-0000-0000-000000000021';
select pg_temp.expect_error($q$select pg_temp.checkout('bank-unconfigured','bank_transfer')$q$,'55000','unconfigured bank destination fails closed');
select pg_temp.assert_ok(not exists(select 1 from app_private.idempotency_records where idempotency_key='bank-unconfigured'),'failed bank checkout leaves no replay record');
select pg_temp.expect_error($q$select public.csa098_create_checkout_order('09800000-0000-0000-0000-000000000001','09800000-0000-0000-0000-000000000012','aal1','forged','09800000-0000-0000-0000-000000000021','online')$q$,'42501','foreign session rejected');
select pg_temp.expect_error($q$select public.csa098_create_checkout_order('09800000-0000-0000-0000-000000000001','09800000-0000-0000-0000-000000000011','aal2','forged-aal','09800000-0000-0000-0000-000000000021','online')$q$,'42501','forged assurance rejected');
update auth.sessions set not_after=now()-interval '1 second' where id='09800000-0000-0000-0000-000000000011';
select pg_temp.expect_error($q$select pg_temp.checkout('original')$q$,'42501','expired session cannot replay');
update auth.sessions set not_after=now()+interval '1 day' where id='09800000-0000-0000-0000-000000000011';
update auth.users set banned_until=now()+interval '1 day' where id='09800000-0000-0000-0000-000000000001';
select pg_temp.expect_error($q$select pg_temp.checkout('original')$q$,'42501','banned account cannot replay');
update auth.users set banned_until=null,is_anonymous=true where id='09800000-0000-0000-0000-000000000001';
select pg_temp.expect_error($q$select pg_temp.checkout('original')$q$,'42501','anonymous account denied');
update auth.users set is_anonymous=false,deleted_at=now() where id='09800000-0000-0000-0000-000000000001';
select pg_temp.expect_error($q$select pg_temp.checkout('original')$q$,'42501','deleted account denied');
update auth.users set deleted_at=null where id='09800000-0000-0000-0000-000000000001';
insert into app_private.bank_account_versions(id,bank_account_id,version,bank_name,account_holder,account_number,branch_name) values
('09800000-0000-0000-0000-000000000031','09800000-0000-0000-0000-000000000039',1,'Synthetic bank','Synthetic holder','SYNTHETIC-ONLY','Synthetic branch'),
('09800000-0000-0000-0000-000000000032','09800000-0000-0000-0000-000000000039',2,'Synthetic bank','Synthetic holder','SYNTHETIC-ONLY','New branch');
select pg_temp.assert_ok(pg_temp.checkout('bank','bank_transfer','09800000-0000-0000-0000-000000000021','09800000-0000-0000-0000-000000000031')->'data'->'bank_instructions'->>'branch_name'='Synthetic branch','bank destination snapshot returned');
select pg_temp.assert_ok(pg_temp.checkout('bank','bank_transfer','09800000-0000-0000-0000-000000000021','09800000-0000-0000-0000-000000000032')->'data'->'bank_instructions'->>'branch_name'='Synthetic branch','bank replay preserves original destination version');
select pg_temp.expect_error('update app_private.order_bank_instructions set instruction_snapshot=''{}''','42501','bank instruction evidence immutable');
select pg_temp.expect_error('update app_private.bank_account_versions set account_number=''CHANGED''','42501','bank destination version immutable');
select pg_temp.assert_ok((public.csa098_create_checkout_order('09800000-0000-0000-0000-000000000002','09800000-0000-0000-0000-000000000012','aal1','original','09800000-0000-0000-0000-000000000021','online')->>'replayed')='false','same key is isolated by principal');
create function pg_temp.inject_failure() returns trigger language plpgsql as $$begin raise exception 'injected idempotency failure'; end;$$;
create trigger csa098_test_failure before insert on app_private.idempotency_records for each row execute function pg_temp.inject_failure();
select pg_temp.expect_error($q$select pg_temp.checkout('rollback')$q$,'P0001','idempotency write failure propagates');
select pg_temp.expect_error($q$select pg_temp.checkout('bank-rollback','bank_transfer','09800000-0000-0000-0000-000000000021','09800000-0000-0000-0000-000000000031')$q$,'P0001','bank replay failure propagates');
select pg_temp.assert_ok((select count(*)=1 from app_private.order_bank_instructions where order_id in (select id from public.orders where buyer_id='09800000-0000-0000-0000-000000000001')),'bank replay failure rolls back destination snapshot');
select pg_temp.assert_ok((select count(*)=2 from public.orders where buyer_id='09800000-0000-0000-0000-000000000001'),'failed replay record rolls back newly created order');
select pg_temp.assert_ok(not exists(select 1 from app_private.idempotency_records where idempotency_key='rollback'),'failed record absent');
drop trigger csa098_test_failure on app_private.idempotency_records;
insert into app_private.verified_settlements(id,order_id,method,amount_minor,currency_code,provider,provider_merchant_id,provider_environment,external_settlement_id,verification_method,evidence_reference,confirmed_at)
select '09800000-0000-0000-0000-000000000053',(response->'data'->>'order_id')::uuid,'online',12345,'LKR','payhere','synthetic-checkout','sandbox','synthetic-payment','provider_retrieval','synthetic-only',now() from csa098_result;
update public.orders set status='paid',paid_at=now() where id=(select (response->'data'->>'order_id')::uuid from csa098_result);
insert into public.enrollments(id,user_id,course_id,status,granted_at) values('09800000-0000-0000-0000-000000000051','09800000-0000-0000-0000-000000000001','09800000-0000-0000-0000-000000000021','active',now());
insert into public.enrollment_grants(enrollment_id,user_id,course_id,source_type,source_order_id,valid_from,settlement_id)
select '09800000-0000-0000-0000-000000000051','09800000-0000-0000-0000-000000000001','09800000-0000-0000-0000-000000000021','online_payment',(response->'data'->>'order_id')::uuid,now(),'09800000-0000-0000-0000-000000000053' from csa098_result;
set constraints all immediate;
select pg_temp.expect_error($q$select pg_temp.checkout('already-enrolled')$q$,'23505','active funded entitlement prevents duplicate purchase');
select pg_temp.assert_ok(pg_temp.checkout('original')->>'replayed'='true','original request can replay after fulfillment');
update public.enrollment_grants set invalidated_at=now(),invalidation_reason='Synthetic revocation' where user_id='09800000-0000-0000-0000-000000000001';
select pg_temp.assert_ok(pg_temp.checkout('repurchase')->>'replayed'='false','invalidated source does not prevent repurchase');
update public.courses set price_minor=9007199254740992 where id='09800000-0000-0000-0000-000000000021';
select pg_temp.expect_error($q$select pg_temp.checkout('unsafe-price')$q$,'22023','price exceeding exact client integer range rejected');
select pg_temp.assert_ok(not has_function_privilege(role_name,'public.csa098_create_checkout_order(uuid,uuid,text,text,uuid,text,uuid)','EXECUTE'),'RPC denied to '||role_name) from unnest(array['anon','authenticated']) r(role_name);
select pg_temp.assert_ok(has_function_privilege('service_role','public.csa098_create_checkout_order(uuid,uuid,text,text,uuid,text,uuid)','EXECUTE'),'verified service boundary can call RPC');
select pg_temp.assert_ok(not has_table_privilege(role_name,'app_private.idempotency_records','SELECT'),'private replay denied to '||role_name) from unnest(array['anon','authenticated','service_role']) r(role_name);
select '1..'||last_value from csa098_assertion;
rollback;
