-- CSA168: least-data current super-admin enrollment viewing only.
begin;
create function public.csa168_list_enrollments(p_actor uuid,p_session_id uuid,p_aal text,p_user uuid,p_after uuid default null,p_limit integer default 20)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb; eligible boolean;
begin
 -- Reuses the role-mutation lock and current account/session checks; no mutation.
 perform app_private.csa108_require_session(p_actor,p_session_id,p_aal,true);
 if not exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id
 where ur.user_id=p_actor and ur.revoked_at is null and r.code='super_admin') then
 raise exception using errcode='42501',message='Current super-admin required.'; end if;
 if p_user is null or p_limit is null or p_limit not between 1 and 50 then
 raise exception using errcode='22023',message='Bounded student enrollment query required.'; end if;
 select exists(select 1 from auth.users u where u.id=p_user and u.deleted_at is null
 and not coalesce(u.is_anonymous,false) and (u.banned_until is null or u.banned_until<=clock_timestamp())) into eligible;
 with page as (
 select e.id,e.course_id,e.status,e.granted_at,e.expires_at,
 eligible and app_private.csa117_has_access(e.user_id,e.course_id) as has_access
 from public.enrollments e where e.user_id=p_user and (p_after is null or e.id>p_after)
 order by e.id limit p_limit+1
 ), visible as (select * from page order by id limit p_limit)
 select jsonb_build_object('items',coalesce((select jsonb_agg(jsonb_build_object(
 'enrollment_id',v.id,'course_id',v.course_id,'projection_status',v.status,
 'granted_at',v.granted_at,'expires_at',v.expires_at,'has_access',v.has_access) order by v.id) from visible v),'[]'::jsonb),
 'next_after_id',case when (select count(*) from page)>p_limit then (select id from visible order by id desc limit 1) else null end) into result;
 return result;
end; $$;
revoke all on function public.csa168_list_enrollments(uuid,uuid,text,uuid,uuid,integer) from public,anon,authenticated,service_role;
grant execute on function public.csa168_list_enrollments(uuid,uuid,text,uuid,uuid,integer) to service_role;
commit;
