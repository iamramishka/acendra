-- Synthetic fault injection against actual merged financial RPCs. No provider calls.
begin;
create temporary sequence csa201_assertion;
create function pg_temp.assert_ok(condition boolean, description text) returns text language plpgsql as $$
begin
 if condition is distinct from true then raise exception 'Assertion failed: %',description; end if;
 return 'ok '||nextval('pg_temp.csa201_assertion')||' - '||description;
end; $$;
insert into auth.users(id) values('20100000-0000-0000-0000-000000000001');
insert into auth.sessions(id,user_id,aal,not_after) values
 ('20100000-0000-0000-0000-000000000011','20100000-0000-0000-0000-000000000001','aal1',now()+interval '1 day');
insert into public.courses(id,slug,title,price_minor,status,published_at) values
 ('20100000-0000-0000-0000-000000000021','csa201-recovery','Synthetic recovery course',12345,'published',now());
create temporary table csa201_order as select public.csa098_create_checkout_order(
 '20100000-0000-0000-0000-000000000001','20100000-0000-0000-0000-000000000011','aal1','csa201-order',
 '20100000-0000-0000-0000-000000000021','online')->'data' data;
create temporary table csa201_attempt as select public.csa101_initialize_checkout(
 '20100000-0000-0000-0000-000000000001','20100000-0000-0000-0000-000000000011','aal1','csa201-init',
 (select (data->>'order_id')::uuid from csa201_order),'csa201-synthetic-merchant','sandbox')->'attempt' data;
create function pg_temp.finalize() returns jsonb language sql as $$
 select public.csa104_finalize_payment((select (data->>'attemptId')::uuid from csa201_attempt),
 'csa201-synthetic-merchant','sandbox','payhere:received:csa201-credit',repeat('a',64),'csa201-credit',12345,'LKR',
 clock_timestamp()-interval '1 day','payhere:authenticated_retrieval:csa201-credit');
$$;
create function pg_temp.inject_failure() returns trigger language plpgsql as $$
begin raise exception using errcode='P0001',message='CSA201 synthetic persistence fault'; end; $$;
create function pg_temp.expect_fault(boundary text) returns text language plpgsql as $$
declare state text; message text;
begin
 begin perform pg_temp.finalize(); exception when others then state:=sqlstate; message:=sqlerrm; end;
 return pg_temp.assert_ok(state='P0001' and message='CSA201 synthetic persistence fault',boundary||' exact fault propagated');
end; $$;
create function pg_temp.assert_clean(boundary text) returns text language sql as $$
 select pg_temp.assert_ok(
 (select status='pending_payment' and paid_at is null from public.orders where id=(select (data->>'order_id')::uuid from csa201_order))
 and (select status='initialized' and provider_transaction_id is null and completed_at is null from public.payment_attempts where id=(select (data->>'attemptId')::uuid from csa201_attempt))
 and not exists(select 1 from app_private.verified_settlements where order_id=(select (data->>'order_id')::uuid from csa201_order))
 and not exists(select 1 from app_private.payment_events where payment_attempt_id=(select (data->>'attemptId')::uuid from csa201_attempt))
 and not exists(select 1 from public.enrollments where user_id='20100000-0000-0000-0000-000000000001')
 and not exists(select 1 from public.enrollment_grants where source_order_id=(select (data->>'order_id')::uuid from csa201_order))
 and not exists(select 1 from app_private.notification_outbox where recipient_user_id='20100000-0000-0000-0000-000000000001')
 and not exists(select 1 from app_private.audit_logs where resource_id=(select (data->>'order_id')::uuid from csa201_order))
 and not public.csa117_check_entitlement('20100000-0000-0000-0000-000000000001','20100000-0000-0000-0000-000000000011','aal1','20100000-0000-0000-0000-000000000021'),
 boundary||' rolls back order, attempt, settlement, event, projection, grant, outbox and audit');
$$;
create trigger csa201_fault before insert on app_private.payment_events for each row execute function pg_temp.inject_failure();
select pg_temp.expect_fault('event after settlement');
select pg_temp.assert_clean('event after settlement');
drop trigger csa201_fault on app_private.payment_events;
create trigger csa201_fault before insert on public.enrollment_grants for each row execute function pg_temp.inject_failure();
select pg_temp.expect_fault('grant after paid transition');
select pg_temp.assert_clean('grant after paid transition');
drop trigger csa201_fault on public.enrollment_grants;
create trigger csa201_fault before insert on app_private.notification_outbox for each row execute function pg_temp.inject_failure();
select pg_temp.expect_fault('outbox after grant');
select pg_temp.assert_clean('outbox after grant');
drop trigger csa201_fault on app_private.notification_outbox;
create trigger csa201_fault before insert on app_private.audit_logs for each row when(new.action='payment_verified') execute function pg_temp.inject_failure();
select pg_temp.expect_fault('final audit after outbox');
select pg_temp.assert_clean('final audit after outbox');
drop trigger csa201_fault on app_private.audit_logs;
select pg_temp.assert_ok(pg_temp.finalize()->>'outcome'='processed','delayed verified event recovers after internal failure');
set constraints all immediate;
select pg_temp.assert_ok(pg_temp.finalize()->>'outcome'='duplicate','lost response retried with same event is duplicate');
create function pg_temp.assert_paid(description text) returns text language sql as $$
 select pg_temp.assert_ok(
 (select status='paid' and paid_at is not null from public.orders where id=(select (data->>'order_id')::uuid from csa201_order))
 and (select status='succeeded' and provider_transaction_id='csa201-credit' and amount_minor=12345 and currency_code='LKR' from public.payment_attempts where id=(select (data->>'attemptId')::uuid from csa201_attempt))
 and (select count(*)=1 from app_private.verified_settlements where order_id=(select (data->>'order_id')::uuid from csa201_order))
 and (select count(*)=1 from app_private.payment_events where payment_attempt_id=(select (data->>'attemptId')::uuid from csa201_attempt))
 and (select count(*)=1 from public.enrollment_grants where source_order_id=(select (data->>'order_id')::uuid from csa201_order))
 and (select count(*)=1 from public.enrollments where user_id='20100000-0000-0000-0000-000000000001' and status='active')
 and (select count(*)=1 from app_private.notification_outbox where recipient_user_id='20100000-0000-0000-0000-000000000001')
 and (select count(*)=1 from app_private.audit_logs where resource_id=(select (data->>'order_id')::uuid from csa201_order))
 and exists(select 1 from public.enrollment_grants g join app_private.verified_settlements s on s.id=g.settlement_id
 where g.source_order_id=(select (data->>'order_id')::uuid from csa201_order) and s.order_id=g.source_order_id
 and s.external_settlement_id='csa201-credit' and s.amount_minor=12345 and s.currency_code='LKR')
 and public.csa117_check_entitlement('20100000-0000-0000-0000-000000000001','20100000-0000-0000-0000-000000000011','aal1','20100000-0000-0000-0000-000000000021'),description);
$$;
select pg_temp.assert_paid('recovery and duplicate commit one of each financial effect');
-- Notification failure/retry/crashed lease must remain separate from paid state.
create temporary table csa201_lease as select public.csa119_claim_notifications(1)->0 data;
select pg_temp.assert_ok((select data->>'event_key'='payment_verified:'||(select data->>'order_id' from csa201_order) from csa201_lease),'worker claims the recovered payment notification');
select pg_temp.assert_ok(public.csa119_complete_notification((select (data->>'id')::uuid from csa201_lease),(select (data->>'lease_token')::uuid from csa201_lease),false),'delivery failure acknowledged');
select pg_temp.assert_ok((select status='pending' and attempt_count=1 and last_error_code='DELIVERY_FAILED' and next_attempt_at>clock_timestamp() from app_private.notification_outbox where id=(select (data->>'id')::uuid from csa201_lease)),'delivery failure schedules bounded retry');
select pg_temp.assert_paid('failed email preserves verified payment and entitlement');
update app_private.notification_outbox set next_attempt_at=clock_timestamp()-interval '1 second' where id=(select (data->>'id')::uuid from csa201_lease);
create temporary table csa201_crashed as select public.csa119_claim_notifications(1)->0 data;
update app_private.notification_outbox set lease_until=clock_timestamp()-interval '1 second' where id=(select (data->>'id')::uuid from csa201_crashed);
create temporary table csa201_reclaimed as select public.csa119_claim_notifications(1)->0 data;
select pg_temp.assert_ok((select data->>'id'=(select data->>'id' from csa201_crashed) and data->>'lease_token'<>(select data->>'lease_token' from csa201_crashed) from csa201_reclaimed),'crashed expired lease reclaimed with new token');
select pg_temp.assert_ok(not public.csa119_complete_notification((select (data->>'id')::uuid from csa201_crashed),(select (data->>'lease_token')::uuid from csa201_crashed),true),'stale worker cannot acknowledge reclaimed lease');
select pg_temp.assert_ok(public.csa119_complete_notification((select (data->>'id')::uuid from csa201_reclaimed),(select (data->>'lease_token')::uuid from csa201_reclaimed),true),'current retry acknowledges delivery');
select pg_temp.assert_ok((select status='sent' and attempt_count=3 and lease_token is null and last_error_code is null from app_private.notification_outbox where id=(select (data->>'id')::uuid from csa201_reclaimed)),'successful notification retry closes lease');
select pg_temp.assert_paid('notification crash and recovery preserve one paid entitlement');
create function pg_temp.expect_conflict() returns text language plpgsql as $$
declare state text;
begin
 begin
  perform public.csa104_finalize_payment((select (data->>'attemptId')::uuid from csa201_attempt),
   'csa201-synthetic-merchant','sandbox','payhere:received:csa201-credit',repeat('b',64),'csa201-credit',12345,'LKR',
   clock_timestamp()-interval '1 day','payhere:authenticated_retrieval:csa201-credit');
 exception when others then state:=sqlstate; end;
 return pg_temp.assert_ok(state='22023','changed payload on recovered event identity rejected');
end; $$;
select pg_temp.expect_conflict();
select pg_temp.assert_paid('conflicting retry preserves verified financial state');
-- Simulate four unsuccessful delivery attempts, then a crash on the final lease.
update app_private.notification_outbox set status='pending',attempt_count=4,sent_at=null,next_attempt_at=clock_timestamp()-interval '1 second'
 where id=(select (data->>'id')::uuid from csa201_reclaimed);
create temporary table csa201_exhausted as select public.csa119_claim_notifications(1)->0 data;
update app_private.notification_outbox set lease_until=clock_timestamp()-interval '1 second' where id=(select (data->>'id')::uuid from csa201_exhausted);
select pg_temp.assert_ok(public.csa119_claim_notifications(1)='[]'::jsonb,'exhausted crashed lease is not reclaimed');
select pg_temp.assert_ok((select status='failed' and attempt_count=5 and lease_token is null and last_error_code='DELIVERY_FAILED' from app_private.notification_outbox where id=(select (data->>'id')::uuid from csa201_exhausted)),'exhausted delivery remains observable terminal failure');
select pg_temp.assert_paid('terminal notification failure never reverses paid entitlement');
select '1..'||last_value from csa201_assertion;
rollback;
