-- Ordered after CSA-094/095. Database owner is the only writer until reviewed
-- trusted operations are implemented. Unverified references never fund grants.
begin;
alter table public.payment_attempts
 add column provider_merchant_id text check(provider_merchant_id is null or (char_length(provider_merchant_id) between 1 and 100 and provider_merchant_id ~ '[^[:space:]]')),
 add column provider_environment text check(provider_environment in ('sandbox','production')),
 add constraint payment_attempts_provider_scope check(
  (provider is null and provider_merchant_id is null and provider_environment is null)
  or (method='online' and provider is not null and provider='payhere' and provider_merchant_id is not null and provider_environment is not null)),
 add constraint payment_attempts_event_scope unique(id,provider,provider_merchant_id,provider_environment);
alter table app_private.payment_events add constraint payment_events_attempt_scope_fk
 foreign key(payment_attempt_id,provider,provider_merchant_id,provider_environment)
 references public.payment_attempts(id,provider,provider_merchant_id,provider_environment) on delete restrict on update restrict;

create table app_private.verified_settlements (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null,
 method text not null check(method in ('online','bank_transfer')),
 amount_minor bigint not null check(amount_minor>0),
 currency_code text not null check(currency_code='LKR'),
 provider text,
 provider_merchant_id text,
 provider_environment text,
 receiving_bank_account_scope text,
 external_settlement_id text not null check(char_length(external_settlement_id) between 1 and 500 and external_settlement_id ~ '[^[:space:]]'),
 verification_method text not null,
 evidence_reference text not null check(char_length(evidence_reference) between 1 and 500 and evidence_reference ~ '[^[:space:]]'),
 confirmed_at timestamptz not null,
 recorded_at timestamptz not null default now(),
 constraint verified_settlement_scope check(
  (method='online' and provider is not null and provider='payhere' and provider_environment is not null and provider_merchant_id is not null and char_length(provider_merchant_id) between 1 and 100 and provider_merchant_id ~ '[^[:space:]]' and provider_environment in ('sandbox','production') and receiving_bank_account_scope is null and verification_method='provider_retrieval')
  or (method='bank_transfer' and provider is null and provider_merchant_id is null and provider_environment is null and receiving_bank_account_scope is not null and char_length(receiving_bank_account_scope) between 1 and 200 and receiving_bank_account_scope ~ '[^[:space:]]' and verification_method='bank_reconciliation')),
 constraint verified_settlement_order_terms foreign key(order_id,method,amount_minor,currency_code) references public.orders(id,payment_method,amount_minor,currency_code) on delete restrict on update restrict,
 constraint verified_settlement_order_identity unique(id,order_id),
 constraint verified_settlement_time check(confirmed_at<=recorded_at)
);
create unique index verified_online_settlement_identity on app_private.verified_settlements(provider,provider_merchant_id,provider_environment,external_settlement_id) where method='online';
create unique index verified_bank_settlement_identity on app_private.verified_settlements(receiving_bank_account_scope,external_settlement_id) where method='bank_transfer';
create index verified_settlements_order_idx on app_private.verified_settlements(order_id);

create function app_private.csa096_preserve_attempt_scope() returns trigger language plpgsql set search_path='' as $$
begin
 if old.provider_merchant_id is not null and row(new.provider,new.provider_merchant_id,new.provider_environment)
 is distinct from row(old.provider,old.provider_merchant_id,old.provider_environment) then
  raise exception using errcode='23514',message='Bound provider scope is immutable.';
 end if;
 return new;
end; $$;
create trigger payment_attempts_preserve_scope before update on public.payment_attempts for each row execute function app_private.csa096_preserve_attempt_scope();

create function app_private.csa096_preserve_fulfillment_time() returns trigger language plpgsql set search_path='' as $$
begin
 if old.paid_at is not null and new.paid_at is distinct from old.paid_at then
  raise exception using errcode='23514',message='First fulfillment timestamp is immutable.';
 end if;
 return new;
end; $$;
create trigger orders_preserve_fulfillment_time before update on public.orders for each row execute function app_private.csa096_preserve_fulfillment_time();
create function app_private.csa096_require_paid_settlement() returns trigger language plpgsql set search_path='' as $$
declare current_order public.orders;
begin
 select * into current_order from public.orders where id=new.id;
 if current_order.status in ('paid','refunded') and (current_order.paid_at is null or not exists(select 1 from app_private.verified_settlements where order_id=current_order.id)) then
  raise exception using errcode='23514',message='Paid orders require verified settlement and first fulfillment time.';
 end if;
 return null;
end; $$;
create constraint trigger orders_require_paid_settlement after insert or update on public.orders deferrable initially deferred for each row execute function app_private.csa096_require_paid_settlement();

create table app_private.idempotency_records (
 principal_scope text not null check(char_length(principal_scope) between 1 and 200 and principal_scope ~ '[^[:space:]]'),
 operation text not null check(char_length(operation) between 1 and 100 and operation ~ '[^[:space:]]'),
 idempotency_key text not null check(char_length(idempotency_key) between 1 and 128 and idempotency_key ~ '[^[:space:]]'),
 request_hash text not null check(request_hash ~ '^[0-9a-f]{64}$'),
 safe_result jsonb not null check(jsonb_typeof(safe_result)='object'),
 created_at timestamptz not null default now(),
 primary key(principal_scope,operation,idempotency_key)
);
create function app_private.csa096_immutable_record() returns trigger language plpgsql set search_path='' as $$
begin raise exception using errcode='23514',message='Financial evidence and idempotency records are immutable.'; end; $$;
create trigger verified_settlements_immutable before update or delete on app_private.verified_settlements for each row execute function app_private.csa096_immutable_record();
create trigger idempotency_records_immutable before update or delete on app_private.idempotency_records for each row execute function app_private.csa096_immutable_record();

alter table public.enrollment_grants add column settlement_id uuid,
 add constraint enrollment_grants_settlement_order foreign key(settlement_id,source_order_id) references app_private.verified_settlements(id,order_id) on delete restrict on update restrict,
 add constraint enrollment_grants_verified_funding check((source_type='admin_grant' and settlement_id is null) or (source_type in ('online_payment','bank_transfer') and settlement_id is not null));
create unique index enrollment_grants_settlement_once on public.enrollment_grants(settlement_id) where settlement_id is not null;
create function app_private.csa096_check_grant_settlement() returns trigger language plpgsql set search_path='' as $$
declare settlement_method text;
begin
 if tg_op='UPDATE' and new.settlement_id is distinct from old.settlement_id then
  raise exception using errcode='23514',message='Grant settlement identity is immutable.';
 end if;
 if new.settlement_id is not null then
  select method into settlement_method from app_private.verified_settlements where id=new.settlement_id and order_id=new.source_order_id;
  if settlement_method is distinct from case when new.source_type='online_payment' then 'online' else 'bank_transfer' end then
   raise exception using errcode='23514',message='Grant funding method does not match settlement.';
  end if;
 end if;
 return new;
end; $$;
create trigger enrollment_grants_check_settlement before insert or update on public.enrollment_grants for each row execute function app_private.csa096_check_grant_settlement();

alter table public.bank_transfer_submissions add column settlement_id uuid,
 add constraint bank_submissions_settlement_order foreign key(settlement_id,order_id) references app_private.verified_settlements(id,order_id) on delete restrict on update restrict,
 add constraint bank_submissions_approval_funding check((status='approved' and settlement_id is not null) or (status<>'approved' and settlement_id is null));
create unique index bank_submissions_settlement_once on public.bank_transfer_submissions(settlement_id) where settlement_id is not null;
create function app_private.csa096_check_bank_settlement() returns trigger language plpgsql set search_path='' as $$
begin
 if new.settlement_id is not null and not exists(select 1 from app_private.verified_settlements where id=new.settlement_id and order_id=new.order_id and method='bank_transfer') then
  raise exception using errcode='23514',message='Bank approval requires matching verified bank settlement.';
 end if;
 if tg_op='UPDATE' and old.settlement_id is not null and new.settlement_id is distinct from old.settlement_id then
  raise exception using errcode='23514',message='Bank approval evidence is immutable.';
 end if;
 return new;
end; $$;
create trigger bank_submissions_check_settlement before insert or update on public.bank_transfer_submissions for each row execute function app_private.csa096_check_bank_settlement();
alter table app_private.verified_settlements enable row level security;
alter table app_private.idempotency_records enable row level security;
revoke all on app_private.verified_settlements,app_private.idempotency_records from public,anon,authenticated,service_role;
revoke all on function app_private.csa096_immutable_record(),app_private.csa096_check_grant_settlement(),app_private.csa096_preserve_attempt_scope() from public,anon,authenticated,service_role;
revoke all on function app_private.csa096_preserve_fulfillment_time(),app_private.csa096_require_paid_settlement(),app_private.csa096_check_bank_settlement() from public,anon,authenticated,service_role;
comment on table app_private.verified_settlements is 'Independently verified exact LKR settlements; multiple real payments per order preserved for reconciliation, each external identity belongs to one order. Caller must verify retrieval/bank reconciliation before insertion.';
comment on table app_private.idempotency_records is 'Private non-null principal/operation/key response cache. Trusted operations compare request_hash and commit safe_result atomically with their writes.';
comment on column public.enrollment_grants.settlement_id is 'Purchased sources require independently verified settlement, exactly once. Status/receipt/callback alone cannot fund a grant.';
commit;

