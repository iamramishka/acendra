-- Schema foundation; trusted creation/finalization are separately owned tasks.
begin;
create table public.orders (
 id uuid primary key default gen_random_uuid(),
 order_number text not null unique check(char_length(order_number) between 1 and 100 and order_number ~ '[^[:space:]]'),
 buyer_id uuid not null references public.profiles(id) on delete restrict,
 course_id uuid not null references public.courses(id) on delete restrict,
 course_title_snapshot text not null check(char_length(course_title_snapshot) between 1 and 200 and course_title_snapshot ~ '[^[:space:]]'),
 amount_minor bigint not null check(amount_minor>=0),
 currency_code text not null check(currency_code='LKR'),
 payment_method text not null check(payment_method in ('online','bank_transfer')),
 status text not null default 'created' check(status in ('created','pending_payment','pending_verification','paid','failed','cancelled','refunded')),
 access_duration_snapshot_days integer check(access_duration_snapshot_days is null),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 paid_at timestamptz,
 cancelled_at timestamptz,
 constraint orders_timestamp_order check(updated_at>=created_at and (paid_at is null or paid_at>=created_at) and (cancelled_at is null or cancelled_at>=created_at)),
 constraint orders_attempt_terms unique(id,payment_method,amount_minor,currency_code)
);
create table public.payment_attempts (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null,
 method text not null check(method in ('online','bank_transfer')),
 provider text check(provider is null or (char_length(provider) between 1 and 100 and provider ~ '[^[:space:]]')),
 provider_session_id text check(provider_session_id is null or (char_length(provider_session_id) between 1 and 500 and provider_session_id ~ '[^[:space:]]')),
 provider_transaction_id text check(provider_transaction_id is null or (char_length(provider_transaction_id) between 1 and 500 and provider_transaction_id ~ '[^[:space:]]')),
 amount_minor bigint not null check(amount_minor>=0),
 currency_code text not null check(currency_code='LKR'),
 status text not null default 'initialized' check(status in ('initialized','pending','succeeded','failed','cancelled','refunded')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 completed_at timestamptz,
 constraint payment_attempts_order_terms_fk foreign key(order_id,method,amount_minor,currency_code)
 references public.orders(id,payment_method,amount_minor,currency_code) on delete restrict on update restrict,
 constraint payment_attempts_timestamp_order check(updated_at>=created_at and (completed_at is null or completed_at>=created_at))
);
create index orders_buyer_created_idx on public.orders(buyer_id,created_at desc,id);
create index orders_course_idx on public.orders(course_id);
create index payment_attempts_order_idx on public.payment_attempts(order_id);
-- Lookup only: settlement uniqueness needs verified merchant/environment scope.
create index payment_attempts_provider_reference_idx on public.payment_attempts(provider,provider_transaction_id) where provider_transaction_id is not null;
create function public.csa092_preserve_financial_terms() returns trigger language plpgsql set search_path='' as $$
begin
 if tg_table_name='orders' then
  if row(new.id,new.order_number,new.buyer_id,new.course_id,new.course_title_snapshot,new.amount_minor,new.currency_code,new.payment_method,new.access_duration_snapshot_days,new.created_at)
   is distinct from row(old.id,old.order_number,old.buyer_id,old.course_id,old.course_title_snapshot,old.amount_minor,old.currency_code,old.payment_method,old.access_duration_snapshot_days,old.created_at) then
   raise exception using errcode='23514',message='Order purchase snapshots are immutable.';
  end if;
 else
  if row(new.id,new.order_id,new.method,new.amount_minor,new.currency_code,new.created_at)
   is distinct from row(old.id,old.order_id,old.method,old.amount_minor,old.currency_code,old.created_at) then
   raise exception using errcode='23514',message='Payment attempt terms are immutable.';
  end if;
 end if;
 new.updated_at:=statement_timestamp();
 return new;
end; $$;
revoke all on function public.csa092_preserve_financial_terms() from public,anon,authenticated,service_role;
create trigger orders_preserve_terms before update on public.orders for each row execute function public.csa092_preserve_financial_terms();
create trigger payment_attempts_preserve_terms before update on public.payment_attempts for each row execute function public.csa092_preserve_financial_terms();
alter table public.orders enable row level security;
alter table public.payment_attempts enable row level security;
revoke all on public.orders,public.payment_attempts from public,anon,authenticated,service_role;
grant select on public.orders to authenticated;
create policy csa092_orders_read_own on public.orders for select to authenticated
 using(buyer_id=(select auth.uid()) and (select public.csa060_account_eligible()));
comment on table public.orders is 'One-course immutable LKR purchase snapshot. Status alone never grants access; trusted payment/entitlement workflows remain separate.';
comment on table public.payment_attempts is 'Restricted operational metadata with exact order terms. Provider reference strings are not verified settlement evidence.';
comment on column public.orders.access_duration_snapshot_days is 'Approved lifetime purchase policy: NULL only; scheduled paid access is not enabled.';
commit;
