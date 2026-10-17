-- PR165 review: lists return bounded summaries; details retain the full description.
begin;
create or replace function public.csa164_admin_directory(p_actor uuid,p_session_id uuid,p_aal text,p_resource text,p_id uuid,p_search text,p_after uuid,p_limit integer)
returns jsonb language plpgsql security definer set search_path='' as $$
declare roles text[]; result jsonb;
begin
 roles:=app_private.csa158_reporting_roles(p_actor,p_session_id,p_aal);
 if p_resource is null or p_resource not in ('courses','students') or p_search is null or length(p_search)>200 or p_limit is null or p_limit not between 1 and 50 then
 raise exception using errcode='22023',message='Bounded directory query required.'; end if;
 if p_resource='courses' then
  if not roles&&array['content_manager','super_admin'] then raise exception using errcode='42501',message='Content authority required.'; end if;
  with page as (
   select c.* from public.courses c
   where ('super_admin'=any(roles) or exists(select 1 from public.course_staff cs where cs.course_id=c.id and cs.user_id=p_actor and cs.revoked_at is null))
    and (p_id is null or c.id=p_id) and (p_after is null or c.id>p_after)
    and (p_search='' or strpos(lower(c.title),lower(p_search))>0)
   order by c.id limit p_limit+1
  ), visible as (select * from page order by id limit p_limit)
  select jsonb_build_object('items',coalesce((select jsonb_agg(jsonb_build_object(
   'id',v.id,'title',v.title,'description',case when p_id is null then '' else coalesce(v.description,'') end,'thumbnail_url',null,
   'price_minor',v.price_minor::text,'currency_code',v.currency_code,'status',v.status,
   'enrollment_count',(select count(*) from public.enrollments e where e.course_id=v.id),
   'section_count',(select count(*) from public.course_sections s where s.course_id=v.id),
   'lesson_count',(select count(*) from public.lessons l join public.course_sections s on s.id=l.section_id where s.course_id=v.id),
   'created_at',v.created_at,'updated_at',v.updated_at) order by v.id) from visible v),'[]'::jsonb),
   'next_after_id',case when (select count(*) from page)>p_limit then (select id from visible order by id desc limit 1) else null end) into result;
 else
  if not 'super_admin'=any(roles) then raise exception using errcode='42501',message='Super-admin authority required.'; end if;
  with page as (
   select p.id,p.display_name,p.created_at,u.email,(u.banned_until is null or u.banned_until<=clock_timestamp()) as is_active
   from public.profiles p join auth.users u on u.id=p.id
   where u.deleted_at is null and not coalesce(u.is_anonymous,false)
    and (exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id where ur.user_id=p.id and ur.revoked_at is null and r.code='student')
     or not exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id where ur.user_id=p.id and ur.revoked_at is null and r.code in ('content_manager','finance_admin','super_admin')))
    and (p_id is null or p.id=p_id) and (p_after is null or p.id>p_after)
    and (p_search='' or strpos(lower(p.display_name),lower(p_search))>0 or strpos(lower(u.email),lower(p_search))>0)
   order by p.id limit p_limit+1
  ), visible as (select * from page order by id limit p_limit)
  select jsonb_build_object('items',coalesce((select jsonb_agg(jsonb_build_object(
   'id',v.id,'display_name',v.display_name,'email',coalesce(v.email,''),'created_at',v.created_at,'is_active',v.is_active,
   'enrolled_course_count',(select count(*) from public.enrollments e where e.user_id=v.id),
   'total_paid_minor',null,'currency_code','LKR') order by v.id) from visible v),'[]'::jsonb),
   'next_after_id',case when (select count(*) from page)>p_limit then (select id from visible order by id desc limit 1) else null end) into result;
 end if;
 return result;
end; $$;
revoke all on function public.csa164_admin_directory(uuid,uuid,text,text,uuid,text,uuid,integer) from public,anon,authenticated,service_role;
grant execute on function public.csa164_admin_directory(uuid,uuid,text,text,uuid,text,uuid,integer) to service_role;
comment on function public.csa164_admin_directory(uuid,uuid,text,text,uuid,text,uuid,integer) is 'Issue 164. JWT-verified Edge adapter only. Course assignment scope; student PII requires current super-admin and MFA. Private thumbnails and unverified financial totals deliberately omitted.';
commit;
