-- Additive, read-only admin payment list (finding 004). No financial state mutation.
-- Contract: docs/contracts/CSA-PAYMENT-LIST-PROPOSAL.md ("Implementation decisions").
-- Reuses app_private.csa158_reporting_roles for the live account/session/AAL/unrevoked-role
-- recheck under advisory lock 610061, then narrows to finance_admin/super_admin at AAL2.
begin;
create index orders_created_id_idx on public.orders(created_at desc,id desc);

create function app_private.csapaylist_require_finance(p_actor uuid,p_session_id uuid,p_aal text)
returns void language plpgsql security definer set search_path='' as $$
declare roles text[];
begin
 roles:=app_private.csa158_reporting_roles(p_actor,p_session_id,p_aal);
 if not coalesce(roles&&array['finance_admin','super_admin'],false) or p_aal is distinct from 'aal2' then
  raise exception using errcode='42501',message='Finance authority required.';
 end if;
end; $$;

-- One mapping for list, counts and detail. status is NULL for anything that must fail closed:
-- refunded orders, unknown states, and paid orders without a qualifying verified settlement
-- (bank_transfer, or production online; sandbox settlements never count as approved).
create function app_private.csapaylist_scope(p_as_of timestamptz,p_method text,p_start timestamptz,p_end timestamptz,p_id uuid)
returns table(payment_id uuid,order_id uuid,order_number text,course_id uuid,course_title text,amount_minor bigint,currency_code text,method text,status text,created_at timestamptz,updated_at timestamptz,settled_at timestamptz)
language sql stable security definer set search_path='' as $$
 select o.id,o.id,o.order_number,o.course_id,o.course_title_snapshot,o.amount_minor,o.currency_code,o.payment_method,
  case o.status
   when 'created' then 'pending'
   when 'pending_payment' then case when o.payment_method='bank_transfer' and b.status='rejected' then 'rejected' else 'pending' end
   when 'pending_verification' then 'processing'
   when 'failed' then 'rejected' when 'cancelled' then 'rejected'
   when 'paid' then case when st.confirmed is not null then 'approved' end
  end,
  o.created_at,o.updated_at,st.confirmed
 from public.orders o
 left join lateral (
  select submission.status from public.bank_transfer_submissions submission
  where o.payment_method='bank_transfer' and o.status='pending_payment' and submission.order_id=o.id
  order by submission.created_at desc,submission.id desc limit 1
 ) b on true
 left join lateral (
  select min(s.confirmed_at) as confirmed from app_private.verified_settlements s
  where o.status='paid' and s.order_id=o.id and (s.method='bank_transfer' or s.provider_environment='production')
 ) st on true
 where (p_id is null or o.id=p_id)
  and (p_as_of is null or o.created_at<=p_as_of)
  and (p_method is null or o.payment_method=p_method)
  and (p_start is null or (o.created_at>=p_start and o.created_at<p_end));
$$;

create function public.csapaylist_admin_payment_list(p_actor uuid,p_session_id uuid,p_aal text,p_page_size integer,p_after_created_at timestamptz,p_after_id uuid,p_as_of timestamptz,p_status text,p_method text,p_from date,p_to date,p_prefix text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_now timestamptz:=statement_timestamp(); v_as_of timestamptz; v_start timestamptz; v_end timestamptz; v_bad boolean; v_result jsonb;
begin
 -- Authority first: callers without it learn nothing about validity or existence.
 perform app_private.csapaylist_require_finance(p_actor,p_session_id,p_aal);
 if p_page_size is null or p_page_size not between 1 and 50
  or (p_after_created_at is null)<>(p_after_id is null) or (p_after_id is null)<>(p_as_of is null)
  or (p_as_of is not null and (not isfinite(p_as_of) or p_as_of>v_now+interval '1 minute' or not isfinite(p_after_created_at)))
  or (p_status is not null and p_status not in ('pending','processing','approved','rejected'))
  or (p_method is not null and p_method not in ('online','bank_transfer'))
  or (p_from is null)<>(p_to is null)
  or (p_from is not null and (not isfinite(p_from) or not isfinite(p_to) or p_to<p_from or p_to-p_from>365))
  or (p_prefix is not null and p_prefix !~ '^[A-Za-z0-9-]{1,40}$') then
  raise exception using errcode='22023',message='Invalid payment list request.';
 end if;
 v_as_of:=coalesce(p_as_of,v_now);
 if p_from is not null then
  v_start:=p_from::timestamp at time zone 'Asia/Colombo';
  v_end:=(p_to+1)::timestamp at time zone 'Asia/Colombo';
 end if;
 -- One statement = one snapshot for counts and page rows. Counts honour method/date but not status/prefix.
 with scope as (select * from app_private.csapaylist_scope(v_as_of,p_method,v_start,v_end,null)),
 totals as (
  select count(*) as total,
   count(*) filter (where status='pending') as pending,
   count(*) filter (where status='processing') as processing,
   count(*) filter (where status='approved') as approved,
   count(*) filter (where status='rejected') as rejected,
   coalesce(bool_or(status is null),false) as bad
  from scope),
 page as (
  select * from scope
  where status is not null and (p_status is null or status=p_status)
   and (p_prefix is null or starts_with(lower(order_number),lower(p_prefix)))
   and (p_after_id is null or (created_at,payment_id)<(p_after_created_at,p_after_id))
  order by created_at desc,payment_id desc limit p_page_size+1),
 shown as (select * from page order by created_at desc,payment_id desc limit p_page_size)
 select t.bad,jsonb_build_object(
  'items',coalesce((select jsonb_agg(jsonb_build_object(
    'payment_id',s.payment_id,'order_id',s.order_id,'order_number',s.order_number,'course_id',s.course_id,'course_title',s.course_title,
    'amount_minor',s.amount_minor::text,'currency_code',s.currency_code,'method',s.method,'status',s.status,
    'created_at',to_char(s.created_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'updated_at',to_char(s.updated_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'settled_at',case when s.settled_at is null then null else to_char(s.settled_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') end
   ) order by s.created_at desc,s.payment_id desc) from shown s),'[]'::jsonb),
  'has_more',(select count(*) from page)>p_page_size,
  'counts',jsonb_build_object('pending',t.pending::text,'processing',t.processing::text,'approved',t.approved::text,'rejected',t.rejected::text,'total',t.total::text),
  'as_of',to_char(v_as_of at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
  'count_as_of',to_char(v_now at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'))
 into v_bad,v_result from totals t;
 if v_bad or v_result is null then
  raise exception using errcode='55000',message='Payment reporting unavailable.';
 end if;
 return v_result;
end; $$;

create function public.csapaylist_admin_payment_detail(p_actor uuid,p_session_id uuid,p_aal text,p_payment_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r record;
begin
 perform app_private.csapaylist_require_finance(p_actor,p_session_id,p_aal);
 if p_payment_id is null then raise exception using errcode='22023',message='Invalid payment request.'; end if;
 select * into r from app_private.csapaylist_scope(null,null,null,null,p_payment_id);
 if not found then raise exception using errcode='P0002',message='Payment not found.'; end if;
 if r.status is null then raise exception using errcode='55000',message='Payment reporting unavailable.'; end if;
 return jsonb_build_object('item',jsonb_build_object(
   'payment_id',r.payment_id,'order_id',r.order_id,'order_number',r.order_number,'course_id',r.course_id,'course_title',r.course_title,
   'amount_minor',r.amount_minor::text,'currency_code',r.currency_code,'method',r.method,'status',r.status,
   'created_at',to_char(r.created_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
   'updated_at',to_char(r.updated_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
   'settled_at',case when r.settled_at is null then null else to_char(r.settled_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') end),
  'as_of',to_char(statement_timestamp() at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'));
end; $$;

revoke all on function app_private.csapaylist_require_finance(uuid,uuid,text),
 app_private.csapaylist_scope(timestamptz,text,timestamptz,timestamptz,uuid),
 public.csapaylist_admin_payment_list(uuid,uuid,text,integer,timestamptz,uuid,timestamptz,text,text,date,date,text),
 public.csapaylist_admin_payment_detail(uuid,uuid,text,uuid) from public,anon,authenticated,service_role;
grant execute on function public.csapaylist_admin_payment_list(uuid,uuid,text,integer,timestamptz,uuid,timestamptz,text,text,date,date,text),
 public.csapaylist_admin_payment_detail(uuid,uuid,text,uuid) to service_role;
comment on function public.csapaylist_admin_payment_list(uuid,uuid,text,integer,timestamptz,uuid,timestamptz,text,text,date,date,text) is 'Read-only admin payment list for finance_admin/super_admin at AAL2. Omits receipts, bank/provider references, emails. Fails closed on refunded, unmapped or unsettled-paid orders.';
commit;
