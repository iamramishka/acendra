-- CSA-073: recheck the verified session at the trusted mutation boundary.
begin;
create function public.csa073_change_role(
  p_actor uuid,p_session_id uuid,p_aal text,p_target uuid,
  p_code text,p_action text,p_reason text,p_request_id uuid
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_session auth.sessions%rowtype;
begin
  -- Match the role core lock order. SHARE blocks non-key session updates and
  -- deletes, including MFA downgrade, through role mutation/audit commit.
  perform pg_catalog.pg_advisory_xact_lock(610061);
  if p_actor is null or p_session_id is null or p_aal is distinct from 'aal2' then
    raise exception using errcode='42501',message='Current verified MFA session required.';
  end if;
  select * into v_session from auth.sessions
    where id=p_session_id and user_id=p_actor for share;
  if not found or v_session.aal is distinct from 'aal2'
    or (v_session.not_after is not null and v_session.not_after<=clock_timestamp()) then
    raise exception using errcode='42501',message='Current verified MFA session required.';
  end if;
  -- Existing core rechecks current roles, account eligibility and invariants.
  return public.csa061_change_role(p_actor,p_aal,p_target,p_code,p_action,p_reason,p_request_id);
end;
$$;
revoke all on function public.csa073_change_role(uuid,uuid,text,uuid,text,text,text,uuid) from public,anon,authenticated,service_role;
grant execute on function public.csa073_change_role(uuid,uuid,text,uuid,text,text,text,uuid) to service_role;
-- Operator/internal core only: HTTP must not bypass the current-session check.
revoke execute on function public.csa061_change_role(uuid,text,uuid,text,text,text,uuid) from service_role;
commit;
