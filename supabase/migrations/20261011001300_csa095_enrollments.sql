-- CSA-095: source history and safe current projection, no fulfillment RPC.
begin;
create table public.enrollments (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete restrict,
 course_id uuid not null references public.courses(id) on delete restrict,
 status text not null,
 granted_at timestamptz not null,
 expires_at timestamptz,
 revoked_at timestamptz,
 revocation_reason text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint enrollments_user_course unique(user_id,course_id),
 constraint enrollments_source_identity unique(id,user_id,course_id),
 constraint enrollments_status check (status in ('active','expired','revoked')),
 constraint enrollments_expiry check (expires_at is null or expires_at > granted_at),
 constraint enrollments_revocation_shape check (
   (status='revoked' and revoked_at is not null and revoked_at>=granted_at
     and revocation_reason is not null and length(revocation_reason) between 1 and 1000 and revocation_reason ~ '[^[:space:]]')
   or (status<>'revoked' and revoked_at is null and revocation_reason is null)
 )
);
create index enrollments_course_idx on public.enrollments(course_id);
create table public.enrollment_grants (
 id uuid primary key default gen_random_uuid(),
 enrollment_id uuid not null,
 user_id uuid not null,
 course_id uuid not null,
 source_type text not null,
 source_order_id uuid references public.orders(id) on delete restrict,
 granted_by uuid references public.profiles(id) on delete restrict,
 reason text,
 valid_from timestamptz not null,
 valid_until timestamptz,
 invalidated_at timestamptz,
 invalidation_reason text,
 created_at timestamptz not null default now(),
 constraint enrollment_grants_beneficiary foreign key(enrollment_id,user_id,course_id)
   references public.enrollments(id,user_id,course_id) on delete restrict,
 constraint enrollment_grants_source_type check (source_type in ('online_payment','bank_transfer','admin_grant')),
 constraint enrollment_grants_source_shape check (
   (source_type in ('online_payment','bank_transfer') and source_order_id is not null and valid_until is null)
   or (source_type='admin_grant' and source_order_id is null and granted_by is not null
     and granted_by<>user_id and reason is not null and length(reason) between 1 and 1000 and reason ~ '[^[:space:]]')
 ),
 constraint enrollment_grants_expiry check (valid_until is null or valid_until > valid_from),
 constraint enrollment_grants_invalidation check (
   (invalidated_at is null and invalidation_reason is null)
   or (invalidated_at is not null and invalidated_at>=valid_from
     and invalidation_reason is not null and length(invalidation_reason) between 1 and 1000 and invalidation_reason ~ '[^[:space:]]')
 )
);
create unique index enrollment_grants_one_order_idx on public.enrollment_grants(source_order_id) where source_order_id is not null;
create index enrollment_grants_enrollment_idx on public.enrollment_grants(enrollment_id);
create index enrollment_grants_actor_idx on public.enrollment_grants(granted_by);
create function app_private.csa095_preserve_enrollment()
returns trigger language plpgsql set search_path='' as $$
begin
 if row(new.id,new.user_id,new.course_id,new.granted_at,new.created_at)
    is distinct from row(old.id,old.user_id,old.course_id,old.granted_at,old.created_at) then
   raise exception 'Enrollment beneficiary and first fulfillment time are immutable.' using errcode='23514';
 end if;
 new.updated_at:=statement_timestamp();
 return new;
end;
$$;
create trigger enrollments_preserve_identity before update on public.enrollments
 for each row execute function app_private.csa095_preserve_enrollment();
create function app_private.csa095_validate_grant()
returns trigger language plpgsql set search_path='' as $$
begin
 if new.source_order_id is not null and not exists (
   select 1 from public.orders o where o.id=new.source_order_id and o.buyer_id=new.user_id
   and o.course_id=new.course_id
   and o.payment_method=case new.source_type when 'online_payment' then 'online' when 'bank_transfer' then 'bank_transfer' else null end
 ) then
   raise exception 'Grant must match the funding order purchaser, course and method.' using errcode='23514';
 end if;
 if tg_op='UPDATE' and (
   row(new.id,new.enrollment_id,new.user_id,new.course_id,new.source_type,new.source_order_id,
       new.granted_by,new.reason,new.valid_from,new.valid_until,new.created_at)
   is distinct from row(old.id,old.enrollment_id,old.user_id,old.course_id,old.source_type,old.source_order_id,
       old.granted_by,old.reason,old.valid_from,old.valid_until,old.created_at)
   or (old.invalidated_at is not null and row(new.invalidated_at,new.invalidation_reason)
       is distinct from row(old.invalidated_at,old.invalidation_reason))
 ) then
   raise exception 'Grant source history is immutable; invalidated sources cannot be restored.' using errcode='23514';
 end if;
 return new;
end;
$$;
create trigger enrollment_grants_validate before insert or update on public.enrollment_grants
 for each row execute function app_private.csa095_validate_grant();
revoke all on function app_private.csa095_preserve_enrollment(),app_private.csa095_validate_grant()
 from public,anon,authenticated,service_role;
alter table public.enrollments enable row level security;
alter table public.enrollment_grants enable row level security;
revoke all on table public.enrollments,public.enrollment_grants from public,anon,authenticated,service_role;
grant select on public.enrollments to authenticated;
create policy enrollments_read_own on public.enrollments for select to authenticated
 using(user_id=(select auth.uid()) and (select public.csa060_account_eligible()));
comment on table public.enrollments is
 'Own safe projection, not standalone proof of entitlement. Delivery must check eligible surviving sources, current time and restrictions. First fulfillment timestamp is immutable.';
comment on table public.enrollment_grants is
 'Immutable source history. CSA096 adds verified settlement proof before deployment. No client/service writes; authorized audited atomic fulfillment remains a separate operation.';
commit;
