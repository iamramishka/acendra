-- CSA101–105: disabled trusted payment workflow. No merchant configuration seeded.
begin;
create table app_private.audit_logs (
 id uuid primary key default gen_random_uuid(), actor_user_id uuid references public.profiles(id) on delete restrict,
 action text not null, resource_type text not null, resource_id uuid, request_id text,
 outcome text not null, safe_metadata jsonb not null default '{}'::jsonb check(jsonb_typeof(safe_metadata)='object'),
 created_at timestamptz not null default now()
);
create table app_private.notification_outbox (
 id uuid primary key default gen_random_uuid(), event_key text unique not null,
 recipient_user_id uuid references public.profiles(id) on delete restrict,
 notification_type text not null, safe_payload jsonb not null check(jsonb_typeof(safe_payload)='object'),
 status text not null default 'pending' check(status in ('pending','processing','sent','failed')),
 attempt_count integer not null default 0 check(attempt_count>=0), next_attempt_at timestamptz,
 created_at timestamptz not null default now(), sent_at timestamptz
);
create trigger csa104_audit_immutable before update or delete on app_private.audit_logs for each row execute function app_private.csa096_immutable_record();
create trigger csa104_audit_no_truncate before truncate on app_private.audit_logs for each statement execute function app_private.csa096_immutable_record();
alter table app_private.audit_logs enable row level security;
alter table app_private.notification_outbox enable row level security;
revoke all on app_private.audit_logs,app_private.notification_outbox from public,anon,authenticated,service_role;
create unique index csa101_attempt_provider_order on public.payment_attempts(provider,provider_session_id) where provider_session_id is not null;

create function public.csa101_initialize_checkout(p_actor uuid,p_session_id uuid,p_aal text,p_key text,p_order uuid,p_merchant text,p_environment text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u auth.users%rowtype; s auth.sessions%rowtype; o public.orders%rowtype; a public.payment_attempts%rowtype;
 prior app_private.idempotency_records%rowtype; h text; scope text; result jsonb; aid uuid;
begin
 if p_key is null or p_key !~ '^[A-Za-z0-9._:-]{1,128}$' or p_order is null or p_merchant is null
 or char_length(p_merchant) not between 1 and 100 or p_merchant !~ '[^[:space:]]'
 or p_environment is null or p_environment not in ('sandbox','production') then
 raise exception using errcode='22023',message='Invalid checkout request.'; end if;
 select * into u from auth.users where id=p_actor for share;
 if not found or u.deleted_at is not null or coalesce(u.is_anonymous,false) or u.banned_until>clock_timestamp() then
 raise exception using errcode='42501',message='Current account required.'; end if;
 select * into s from auth.sessions where id=p_session_id and user_id=p_actor for share;
 if not found or p_aal is null or p_aal not in ('aal1','aal2') or s.aal::text is distinct from p_aal or s.not_after<=clock_timestamp() then
 raise exception using errcode='42501',message='Current verified session required.'; end if;
 scope:='user:'||p_actor::text;
 h:=encode(sha256(convert_to(jsonb_build_object('order',p_order,'merchant',p_merchant,'environment',p_environment)::text,'UTF8')),'hex');
 perform pg_advisory_xact_lock(hashtext(scope),hashtext('initialize-checkout:'||p_key));
 select * into o from public.orders where id=p_order for update;
 if not found or o.buyer_id is distinct from p_actor then raise exception using errcode='42501',message='Owned order required.'; end if;
 if o.payment_method<>'online' or o.status not in ('pending_payment','pending_verification') or o.amount_minor<=0 or o.amount_minor>9007199254740991 then
 raise exception using errcode='55000',message='Payable online order required.'; end if;
 select * into prior from app_private.idempotency_records where principal_scope=scope and operation='initialize-checkout' and idempotency_key=p_key;
 if found then
 if prior.request_hash is distinct from h then raise exception using errcode='22023',message='Idempotency conflict.'; end if;
 return prior.safe_result||jsonb_build_object('replayed',true); end if;

 select * into a from public.payment_attempts where order_id=o.id and status in ('initialized','pending') order by created_at,id limit 1 for update;
 if found then
 if a.provider is distinct from 'payhere' or a.provider_merchant_id is distinct from p_merchant or a.provider_environment is distinct from p_environment then
 raise exception using errcode='22023',message='Provider scope conflict.'; end if;
 else
 aid:=gen_random_uuid();
 insert into public.payment_attempts(id,order_id,method,provider,provider_session_id,amount_minor,currency_code,provider_merchant_id,provider_environment)
 values(aid,o.id,'online','payhere',aid::text,o.amount_minor,o.currency_code,p_merchant,p_environment) returning * into a;
 end if;
 result:=jsonb_build_object('replayed',false,'order_id',o.id,'attempt',jsonb_build_object('attemptId',a.id,'orderId',a.provider_session_id,
 'method',a.method,'provider',a.provider,'merchantId',a.provider_merchant_id,'environment',a.provider_environment,'currency',a.currency_code,'amountMinor',a.amount_minor::text,'title',o.course_title_snapshot));
 insert into app_private.idempotency_records(principal_scope,operation,idempotency_key,request_hash,safe_result) values(scope,'initialize-checkout',p_key,h,result);
 return result;
end; $$;
create function public.csa102_lookup_payment_attempt(p_provider_order_id text)
returns jsonb language sql security definer set search_path='' as $$
 select jsonb_build_object('attemptId',a.id,'orderId',a.provider_session_id,'method',a.method,'provider',a.provider,
 'merchantId',a.provider_merchant_id,'environment',a.provider_environment,'currency',a.currency_code,'amountMinor',a.amount_minor::text,'title',o.course_title_snapshot)
 from public.payment_attempts a join public.orders o on o.id=a.order_id
 where a.provider_session_id=p_provider_order_id and a.provider='payhere' and a.method='online' and a.provider_merchant_id is not null and a.provider_environment is not null;
$$;
create function public.csa104_finalize_payment(p_attempt_id uuid,p_merchant text,p_environment text,p_event_id text,p_payload_hash text,
 p_external_settlement_id text,p_amount_minor bigint,p_currency text,p_confirmed_at timestamptz,p_evidence_reference text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare a public.payment_attempts%rowtype; o public.orders%rowtype; e app_private.payment_events%rowtype;
 settlement app_private.verified_settlements%rowtype; eid uuid; sid uuid; enrollment uuid; fulfilled timestamptz; outcome text;
begin
 if p_attempt_id is null or p_merchant is null or p_environment is null or p_event_id is null or p_payload_hash is null
 or p_payload_hash !~ '^[0-9a-f]{64}$' or p_external_settlement_id is null or char_length(p_external_settlement_id) not between 1 and 500
 or p_external_settlement_id !~ '[^[:space:]]' or p_event_id is distinct from 'payhere:received:'||p_external_settlement_id
 or p_evidence_reference is distinct from 'payhere:authenticated_retrieval:'||p_external_settlement_id
 or p_confirmed_at is null or not isfinite(p_confirmed_at) or p_confirmed_at>clock_timestamp() or p_amount_minor is null or p_currency is null then
 raise exception using errcode='22023',message='Verified success evidence required.'; end if;
 -- Global settlement identity first; then order, attempt, beneficiary/course. All fulfillment/reversal callers must reuse this ordering.
 perform pg_advisory_xact_lock(hashtext('payhere:'||p_merchant||':'||p_environment),hashtext(p_external_settlement_id));
 select * into a from public.payment_attempts where id=p_attempt_id;
 if not found then raise exception using errcode='P0002',message='Payment attempt unavailable.'; end if;
 select * into o from public.orders where id=a.order_id for update;
 select * into a from public.payment_attempts where id=p_attempt_id for update;
 if a.method<>'online' or a.provider is distinct from 'payhere' or a.provider_merchant_id is distinct from p_merchant or a.provider_environment is distinct from p_environment
 or a.amount_minor is distinct from p_amount_minor or a.currency_code is distinct from p_currency or p_amount_minor<=0
 or o.amount_minor is distinct from p_amount_minor or o.currency_code is distinct from p_currency then
 raise exception using errcode='22023',message='Verified evidence does not match stored terms.'; end if;
 select * into e from app_private.payment_events where provider='payhere' and provider_merchant_id=p_merchant and provider_environment=p_environment and provider_event_id=p_event_id;
 if found then
 if e.payment_attempt_id is distinct from a.id or e.payload_hash is distinct from p_payload_hash then raise exception using errcode='22023',message='Event identity conflict.'; end if;
 return jsonb_build_object('outcome','duplicate','order_id',o.id,'event_id',e.id); end if;
 select * into settlement from app_private.verified_settlements where provider='payhere' and provider_merchant_id=p_merchant and provider_environment=p_environment and external_settlement_id=p_external_settlement_id;
 if found then raise exception using errcode='23505',message='Settlement identity already bound.'; end if;
 fulfilled:=clock_timestamp(); sid:=gen_random_uuid(); eid:=gen_random_uuid();
 insert into app_private.verified_settlements(id,order_id,method,amount_minor,currency_code,provider,provider_merchant_id,provider_environment,external_settlement_id,verification_method,evidence_reference,confirmed_at,recorded_at)
 values(sid,o.id,'online',p_amount_minor,p_currency,'payhere',p_merchant,p_environment,p_external_settlement_id,'provider_retrieval',p_evidence_reference,p_confirmed_at,fulfilled);
 outcome:=case when o.status in ('pending_payment','pending_verification') and a.status in ('initialized','pending') then 'processed' else 'reconciliation_required' end;
 insert into app_private.payment_events(id,payment_attempt_id,provider,provider_merchant_id,provider_environment,provider_event_id,event_type,payload_hash,received_at,processed_at,processing_status)
 values(eid,a.id,'payhere',p_merchant,p_environment,p_event_id,'RECEIVED',p_payload_hash,fulfilled,fulfilled,outcome);
 if outcome='processed' then
 perform pg_advisory_xact_lock(hashtext(o.buyer_id::text),hashtext(o.course_id::text));
 update public.orders set status='paid',paid_at=fulfilled where id=o.id;
 update public.payment_attempts set status='succeeded',provider_transaction_id=p_external_settlement_id,completed_at=fulfilled where id=a.id;
 insert into public.enrollments(user_id,course_id,status,granted_at) values(o.buyer_id,o.course_id,'active',fulfilled)
 on conflict(user_id,course_id) do nothing;
 select id into enrollment from public.enrollments where user_id=o.buyer_id and course_id=o.course_id for update;
 insert into public.enrollment_grants(enrollment_id,user_id,course_id,source_type,source_order_id,valid_from,settlement_id)
 values(enrollment,o.buyer_id,o.course_id,'online_payment',o.id,fulfilled,sid);
 -- Preserve a revoked projection conservatively: a later trusted restriction-aware operation may resolve its scope.
 update public.enrollments set status='active',expires_at=null where id=enrollment and status<>'revoked';
 insert into app_private.notification_outbox(event_key,recipient_user_id,notification_type,safe_payload)
 values('payment_verified:'||o.id::text,o.buyer_id,'payment_verified',jsonb_build_object('order_id',o.id,'course_id',o.course_id));
 end if;
 insert into app_private.audit_logs(action,resource_type,resource_id,request_id,outcome,safe_metadata)
 values('payment_verified','order',o.id,eid::text,outcome,jsonb_build_object('event_id',eid,'settlement_id',sid,'attempt_id',a.id));
 return jsonb_build_object('outcome',outcome,'order_id',o.id,'event_id',eid);
end; $$;
revoke all on function public.csa101_initialize_checkout(uuid,uuid,text,text,uuid,text,text),public.csa102_lookup_payment_attempt(text),public.csa104_finalize_payment(uuid,text,text,text,text,text,bigint,text,timestamptz,text) from public,anon,authenticated,service_role;
grant execute on function public.csa101_initialize_checkout(uuid,uuid,text,text,uuid,text,text),public.csa102_lookup_payment_attempt(text),public.csa104_finalize_payment(uuid,text,text,text,text,text,bigint,text,timestamptz,text) to service_role;
comment on function public.csa104_finalize_payment(uuid,text,text,text,text,text,bigint,text,timestamptz,text) is 'Verified Edge retrieval success only. Atomic fulfillment, scoped duplicate conflict and late/extra settlement reconciliation. Never call using callback checksum alone.';
commit;



