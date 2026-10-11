-- CSA-061: privileged role writes are service-only, verified-user operations.
begin;

create table public.csa061_role_audit (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete restrict,
  target_id uuid not null references public.profiles(id) on delete restrict,
  role_code text not null references public.roles(code) on delete restrict,
  action text not null check (action in ('grant','revoke','bootstrap')),
  reason text not null check (char_length(reason) between 1 and 500 and reason ~ '[^[:space:]]'),
  request_id uuid not null,
  grant_id uuid not null references public.user_roles(id) on delete restrict,
  occurred_at timestamptz not null default now(),
  unique(actor_id, request_id),
  check ((action = 'bootstrap') = (actor_id is null))
);
create unique index csa061_bootstrap_request_unique on public.csa061_role_audit(request_id) where actor_id is null;
alter table public.csa061_role_audit enable row level security;
revoke all on public.csa061_role_audit from public, anon, authenticated, service_role;

create function public.csa061_audit_immutable() returns trigger
language plpgsql set search_path = '' as $$
begin
  raise exception using errcode='42501', message='Role audit records are immutable.';
end;
$$;
revoke all on function public.csa061_audit_immutable() from public, anon, authenticated, service_role;
create trigger csa061_audit_no_change before update or delete on public.csa061_role_audit
  for each row execute function public.csa061_audit_immutable();
create trigger csa061_audit_no_truncate before truncate on public.csa061_role_audit
  for each statement execute function public.csa061_audit_immutable();

-- Safe current-role projection; mutation grants are deliberately absent.
grant select (id,code,name,description) on public.roles to authenticated;
create policy csa061_role_definitions_read on public.roles for select to authenticated using (true);
grant select (id,user_id,role_id,granted_at,revoked_at) on public.user_roles to authenticated;
create policy csa061_own_current_roles on public.user_roles for select to authenticated
using (user_id = (select auth.uid()) and revoked_at is null
  and (select public.csa060_account_eligible()));

create function public.csa061_change_role(
  p_actor uuid, p_aal text, p_target uuid, p_code text, p_action text,
  p_reason text, p_request_id uuid
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_role uuid;
  v_grant uuid;
  v_event public.csa061_role_audit%rowtype;
  v_active boolean;
begin
  -- One mutation lock serializes authority checks, last-admin decisions and writes.
  perform pg_catalog.pg_advisory_xact_lock(610061);
  if p_actor is null or p_aal is distinct from 'aal2' or not exists (
    select 1 from auth.users u join public.user_roles ur on ur.user_id=u.id
    join public.roles r on r.id=ur.role_id
    where u.id=p_actor and u.deleted_at is null and not coalesce(u.is_anonymous,false)
      and (u.banned_until is null or u.banned_until <= statement_timestamp())
      and ur.revoked_at is null and r.code='super_admin'
  ) then
    raise exception using errcode='42501', message='Current eligible super-admin authority and MFA required.';
  end if;
  if p_target is null or p_target=p_actor then
    raise exception using errcode='42501', message='Self-role changes are prohibited.';
  end if;
  if p_request_id is null or p_reason is null or char_length(p_reason) not between 1 and 500
    or p_reason !~ '[^[:space:]]' or p_action is null or p_action not in ('grant','revoke') then
    raise exception using errcode='22023', message='Invalid role operation.';
  end if;
  select id into v_role from public.roles where code=p_code;
  if v_role is null then raise exception using errcode='22023', message='Unsupported role.'; end if;
  if not exists (select 1 from public.profiles where id=p_target) then
    raise exception using errcode='23503', message='Target profile not found.';
  end if;
  select * into v_event from public.csa061_role_audit where actor_id=p_actor and request_id=p_request_id;
  if found then
    if v_event.target_id is distinct from p_target or v_event.role_code is distinct from p_code
      or v_event.action is distinct from p_action or v_event.reason is distinct from p_reason then
      raise exception using errcode='22023', message='Idempotency key payload mismatch.';
    end if;
    return jsonb_build_object('user_id',p_target,'role_code',p_code,'action',p_action,
      'status',case when exists(select 1 from public.user_roles where user_id=p_target and role_id=v_role and revoked_at is null) then 'active' else 'revoked' end,
      'operation_status',case p_action when 'grant' then 'active' else 'revoked' end,
      'replayed',true,'grant_id',v_event.grant_id,'audit_id',v_event.id);
  end if;
  if p_action='grant' and not exists (select 1 from auth.users u where u.id=p_target
    and u.deleted_at is null and not coalesce(u.is_anonymous,false)
    and (u.banned_until is null or u.banned_until <= statement_timestamp())) then
    raise exception using errcode='42501', message='Target account is ineligible.';
  end if;
  select id into v_grant from public.user_roles where user_id=p_target and role_id=v_role and revoked_at is null;
  v_active := found;
  if p_action='grant' then
    if v_active then raise exception using errcode='22023', message='Role already active; replay its original request.'; end if;
    insert into public.user_roles(user_id,role_id,granted_by) values(p_target,v_role,p_actor) returning id into v_grant;
  else
    if not v_active then raise exception using errcode='22023', message='No active grant.'; end if;
    if p_code='super_admin' and exists (select 1 from auth.users u where u.id=p_target
      and u.deleted_at is null and not coalesce(u.is_anonymous,false)
      and (u.banned_until is null or u.banned_until <= statement_timestamp()))
      and (select count(*) from public.user_roles ur join public.roles r on r.id=ur.role_id
        join auth.users u on u.id=ur.user_id where r.code='super_admin' and ur.revoked_at is null
          and u.deleted_at is null and not coalesce(u.is_anonymous,false)
          and (u.banned_until is null or u.banned_until <= statement_timestamp())) <= 1 then
      raise exception using errcode='42501', message='Last active super-admin must be preserved.';
    end if;
    update public.user_roles set revoked_at=statement_timestamp(), revoked_by=p_actor where id=v_grant;
  end if;
  insert into public.csa061_role_audit(actor_id,target_id,role_code,action,reason,request_id,grant_id)
    values(p_actor,p_target,p_code,p_action,p_reason,p_request_id,v_grant) returning * into v_event;
  return jsonb_build_object('user_id',p_target,'role_code',p_code,'action',p_action,
    'status',case p_action when 'grant' then 'active' else 'revoked' end,
    'operation_status',case p_action when 'grant' then 'active' else 'revoked' end,
    'replayed',false,'grant_id',v_grant,'audit_id',v_event.id);
end;
$$;
revoke all on function public.csa061_change_role(uuid,text,uuid,text,text,text,uuid) from public,anon,authenticated,service_role;
grant execute on function public.csa061_change_role(uuid,text,uuid,text,text,text,uuid) to service_role;

-- Operator-only, explicit first-admin bootstrap. No public signup/HTTP route.
create function public.csa061_bootstrap_super_admin(p_target uuid,p_reason text,p_request_id uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_grant uuid; v_event public.csa061_role_audit%rowtype;
begin
  perform pg_catalog.pg_advisory_xact_lock(610061);
  if p_target is null or p_request_id is null or p_reason is null or char_length(p_reason) not between 1 and 500 or p_reason !~ '[^[:space:]]' then
    raise exception using errcode='22023', message='Bootstrap reason and request UUID required.';
  end if;
  select * into v_event from public.csa061_role_audit where actor_id is null and request_id=p_request_id;
  if found then
    if v_event.target_id is distinct from p_target or v_event.reason is distinct from p_reason then
      raise exception using errcode='22023', message='Bootstrap request mismatch.';
    end if;
    return v_event.grant_id;
  end if;
  if exists (select 1 from public.csa061_role_audit where action='bootstrap')
    or exists (select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id where r.code='super_admin' and ur.revoked_at is null) then
    raise exception using errcode='42501', message='First-admin bootstrap already completed.';
  end if;
  if not exists (select 1 from public.profiles p join auth.users u on u.id=p.id where p.id=p_target
    and u.deleted_at is null and not coalesce(u.is_anonymous,false)
    and (u.banned_until is null or u.banned_until <= statement_timestamp())) then
    raise exception using errcode='42501', message='Bootstrap target is ineligible.';
  end if;
  insert into public.user_roles(user_id,role_id) select p_target,id from public.roles where code='super_admin' returning id into v_grant;
  insert into public.csa061_role_audit(target_id,role_code,action,reason,request_id,grant_id)
    values(p_target,'super_admin','bootstrap',p_reason,p_request_id,v_grant);
  return v_grant;
end;
$$;
revoke all on function public.csa061_bootstrap_super_admin(uuid,text,uuid) from public,anon,authenticated,service_role;
commit;
