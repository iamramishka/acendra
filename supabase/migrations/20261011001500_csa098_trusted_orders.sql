begin;
-- Bank destinations are configured through separately reviewed trusted operations.
-- No real account or production configuration is seeded by this migration.
create table app_private.bank_account_versions (
 id uuid primary key default gen_random_uuid(), bank_account_id uuid not null,
 version integer not null check(version>0), bank_name text not null,
 account_holder text not null, account_number text not null, branch_name text not null,
 currency_code text not null default 'LKR' check(currency_code='LKR'),
 created_at timestamptz not null default now(),
 unique(bank_account_id,version),
 check(char_length(bank_name) between 1 and 200 and bank_name ~ '[^[:space:]]'),
 check(char_length(account_holder) between 1 and 200 and account_holder ~ '[^[:space:]]'),
 check(char_length(account_number) between 1 and 100 and account_number ~ '[^[:space:]]'),
 check(char_length(branch_name) between 1 and 200 and branch_name ~ '[^[:space:]]')
);
create table app_private.order_bank_instructions (
 order_id uuid primary key references public.orders(id) on delete restrict,
 bank_account_version_id uuid not null references app_private.bank_account_versions(id) on delete restrict,
 instruction_snapshot jsonb not null check(jsonb_typeof(instruction_snapshot)='object'),
 created_at timestamptz not null default now()
);
create index order_bank_instructions_version_idx on app_private.order_bank_instructions(bank_account_version_id);
alter table app_private.bank_account_versions enable row level security;
alter table app_private.order_bank_instructions enable row level security;
revoke all on app_private.bank_account_versions,app_private.order_bank_instructions from public,anon,authenticated,service_role;
create function app_private.csa098_preserve_bank_instruction() returns trigger language plpgsql set search_path='' as $$
declare b app_private.bank_account_versions%rowtype; o public.orders%rowtype;
begin
 if tg_op<>'INSERT' then raise exception using errcode='42501',message='Bank evidence is immutable.'; end if;
 select * into o from public.orders where id=new.order_id for share;
 if o.payment_method is distinct from 'bank_transfer' then raise exception using errcode='23514',message='Bank order required.'; end if;
 select * into b from app_private.bank_account_versions where id=new.bank_account_version_id;
 if not found or new.instruction_snapshot is distinct from jsonb_build_object('bank_name',b.bank_name,'account_holder',b.account_holder,'account_number',b.account_number,'branch_name',b.branch_name,'currency_code',b.currency_code) then
 raise exception using errcode='23514',message='Trusted bank snapshot required.'; end if;
 return new;
end; $$;
revoke all on function app_private.csa098_preserve_bank_instruction() from public,anon,authenticated,service_role;
create trigger csa098_instruction_identity before insert or update or delete on app_private.order_bank_instructions for each row execute function app_private.csa098_preserve_bank_instruction();
-- Reuse an unconditional immutable trigger for versions and TRUNCATE boundaries.
create function app_private.csa098_immutable() returns trigger language plpgsql set search_path='' as $$
begin raise exception using errcode='42501',message='Bank evidence is immutable.'; end; $$;
revoke all on function app_private.csa098_immutable() from public,anon,authenticated,service_role;
create trigger csa098_version_immutable before update or delete on app_private.bank_account_versions for each row execute function app_private.csa098_immutable();
create trigger csa098_version_no_truncate before truncate on app_private.bank_account_versions for each statement execute function app_private.csa098_immutable();
create trigger csa098_instruction_no_truncate before truncate on app_private.order_bank_instructions for each statement execute function app_private.csa098_immutable();

create function public.csa098_create_checkout_order(p_actor uuid,p_session_id uuid,p_aal text,p_key text,p_course uuid,p_method text,p_bank_version uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u auth.users%rowtype; s auth.sessions%rowtype; c public.courses%rowtype;
 b app_private.bank_account_versions%rowtype; prior app_private.idempotency_records%rowtype;
 v_hash text; v_scope text; v_order uuid; v_number text; v_result jsonb; v_instruction jsonb;
begin
 if p_key is null or char_length(p_key) not between 1 and 128 or p_key !~ '^[A-Za-z0-9._:-]+$'
 or p_course is null or p_method is null or p_method not in ('online','bank_transfer') then
 raise exception using errcode='22023',message='Invalid order request.'; end if;
 -- Lock ordering: account, session, principal/key, course; no external I/O.
 select * into u from auth.users where id=p_actor for share;
 if not found or u.deleted_at is not null or coalesce(u.is_anonymous,false)
 or (u.banned_until is not null and u.banned_until>clock_timestamp()) then
 raise exception using errcode='42501',message='Current account required.'; end if;
 select * into s from auth.sessions where id=p_session_id and user_id=p_actor for share;
 if not found or p_aal is null or p_aal not in ('aal1','aal2') or s.aal::text is distinct from p_aal
 or (s.not_after is not null and s.not_after<=clock_timestamp()) then
 raise exception using errcode='42501',message='Current verified session required.'; end if;
 v_scope := 'user:'||p_actor::text;
 v_hash := pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(jsonb_build_object('course_id',p_course,'payment_method',p_method)::text,'UTF8')),'hex');
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_scope),pg_catalog.hashtext('create-checkout-order:'||p_key));
 select * into prior from app_private.idempotency_records where principal_scope=v_scope and operation='create-checkout-order' and idempotency_key=p_key;
 if found then
 if prior.request_hash is distinct from v_hash then raise exception using errcode='22023',message='Idempotency conflict.'; end if;
 return jsonb_build_object('replayed',true,'data',prior.safe_result); end if;
 select * into c from public.courses where id=p_course for share;
 if not found or c.status<>'published' then raise exception using errcode='P0002',message='Course unavailable.'; end if;
 if c.currency_code<>'LKR' or c.price_minor>9007199254740991 then raise exception using errcode='22023',message='Unsupported price.'; end if;
 if exists(select 1 from public.enrollments e join public.enrollment_grants g on g.enrollment_id=e.id
 where e.user_id=p_actor and e.course_id=p_course and e.status='active' and g.invalidated_at is null
 and g.valid_from<=clock_timestamp() and (g.valid_until is null or g.valid_until>clock_timestamp())) then
 raise exception using errcode='23505',message='Already enrolled.'; end if;
 if p_method='bank_transfer' then
 select * into b from app_private.bank_account_versions where id=p_bank_version;
 if not found then raise exception using errcode='55000',message='Bank checkout unavailable.'; end if;
 v_instruction := jsonb_build_object('bank_name',b.bank_name,'account_holder',b.account_holder,'account_number',b.account_number,'branch_name',b.branch_name,'currency_code',b.currency_code);
 end if;
 v_order := gen_random_uuid(); v_number := 'ACD-'||upper(replace(v_order::text,'-',''));
 insert into public.orders(id,order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method,status)
 values(v_order,v_number,p_actor,c.id,c.title,c.price_minor,c.currency_code,p_method,'pending_payment');
 if p_method='bank_transfer' then
 insert into app_private.order_bank_instructions(order_id,bank_account_version_id,instruction_snapshot) values(v_order,b.id,v_instruction); end if;
 v_result := jsonb_build_object('order_id',v_order,'order_number',v_number,'course',jsonb_build_object('id',c.id,'title',c.title),
 'amount_minor',c.price_minor,'currency_code',c.currency_code,'payment_method',p_method,'status','pending_payment',
 'next_action',case when p_method='online' then 'initialize_online_payment' else 'show_bank_instructions' end);
 if p_method='bank_transfer' then v_result := v_result||jsonb_build_object('bank_instructions',v_instruction); end if;
 insert into app_private.idempotency_records(principal_scope,operation,idempotency_key,request_hash,safe_result)
 values(v_scope,'create-checkout-order',p_key,v_hash,v_result);
 return jsonb_build_object('replayed',false,'data',v_result);
end; $$;
revoke all on function public.csa098_create_checkout_order(uuid,uuid,text,text,uuid,text,uuid) from public,anon,authenticated,service_role;
grant execute on function public.csa098_create_checkout_order(uuid,uuid,text,text,uuid,text,uuid) to service_role;
comment on function public.csa098_create_checkout_order(uuid,uuid,text,text,uuid,text,uuid) is 'Verified Edge caller only; snapshots authoritative price atomically with user-scoped idempotency. No payment attempt, settlement or entitlement is created.';
commit;
