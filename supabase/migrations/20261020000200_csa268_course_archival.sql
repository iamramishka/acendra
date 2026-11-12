-- Owner decision 2026-10-20: remove courses from sale by archival; never erase
-- orders, enrollments, learning progress, media or immutable audit history.
begin;
create function public.csa268_archive_course(
 p_actor uuid,p_session_id uuid,p_aal text,p_course uuid,
 p_expected timestamptz,p_request_id uuid
) returns jsonb language plpgsql security definer set search_path='' as $$
declare roles text[]; c public.courses%rowtype;
 prior app_private.csa268_authoring_audit%rowtype; command jsonb; result jsonb;
begin
 -- Same authority -> course lock order as publication, authoring and media.
 roles:=app_private.csa158_reporting_roles(p_actor,p_session_id,p_aal);
 if not coalesce('super_admin'=any(roles),false) or p_aal is distinct from 'aal2' then
  raise exception using errcode='42501',message='Current super-admin and MFA required.';
 end if;
 if p_course is null or p_expected is null or not isfinite(p_expected) or p_request_id is null then
  raise exception using errcode='22023',message='Course, original revision and request identity required.';
 end if;
 select * into c from public.courses where id=p_course for update;
 if not found then raise exception using errcode='P0002',message='Course missing.';end if;
 command:=jsonb_build_object('action','archive','course_id',p_course,
  'expected_updated_at',p_expected,'payload','{}'::jsonb);
 select * into prior from app_private.csa268_authoring_audit
  where actor_id=p_actor and request_id=p_request_id;
 if found then
  if prior.payload is distinct from command then
   raise exception using errcode='40001',message='Request conflict.';
  end if;
  return prior.result||jsonb_build_object('replayed',true);
 end if;
 if c.updated_at is distinct from p_expected then
  raise exception using errcode='40001',message='Course changed. Reload before archiving.';
 end if;
 if c.status not in ('draft','published') then
  raise exception using errcode='55000',message='Course is already archived.';
 end if;
 update public.courses set status='archived' where id=p_course
  returning updated_at into p_expected;
 result:=jsonb_build_object('course_id',p_course,'updated_at',p_expected,
  'previous_status',c.status,'status','archived','replayed',false);
 insert into app_private.csa268_authoring_audit(actor_id,course_id,request_id,action,payload,result)
  values(p_actor,p_course,p_request_id,'archive',command,result);
 return result;
end; $$;
revoke all on function public.csa268_archive_course(uuid,uuid,text,uuid,timestamptz,uuid)
 from public,anon,authenticated,service_role;
grant execute on function public.csa268_archive_course(uuid,uuid,text,uuid,timestamptz,uuid) to service_role;
commit;
