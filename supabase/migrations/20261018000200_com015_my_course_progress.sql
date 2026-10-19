-- COM-015/016: one-call progress summary for the signed-in student's courses.
-- Read-only. Ownership comes from the JWT; entitlement is re-checked per course
-- with the same helper as csa133, so progress never reveals unentitled courses.
begin;
create function public.com015_my_course_progress() returns jsonb
language plpgsql security definer set search_path='' as $$
declare claims jsonb:=auth.jwt(); actor uuid:=auth.uid(); session_id uuid;
begin
 if claims->>'role' is distinct from 'authenticated' or actor is null then
  raise exception using errcode='42501',message='Authenticated session required.';
 end if;
 begin session_id:=(claims->>'session_id')::uuid;
 exception when invalid_text_representation then
  raise exception using errcode='42501',message='Current verified session required.';
 end;
 perform app_private.csa108_require_session(actor,session_id,claims->>'aal',false);
 return coalesce((
  select jsonb_agg(jsonb_build_object(
    'course_id',c.course_id,
    'total_lessons',t.total,
    'completed_lessons',p.completed,
    'next_lesson_id',n.lesson_id,
    'last_opened_at',p.last_opened_at)
   order by p.last_opened_at desc nulls last,c.course_id)
  from (select distinct g.course_id from public.enrollment_grants g where g.user_id=actor) c
  cross join lateral (
   select count(*)::int as total
   from public.lessons l join public.course_sections s on s.id=l.section_id
   where s.course_id=c.course_id and s.is_published and l.is_published) t
  cross join lateral (
   select (count(*) filter (where lp.is_completed))::int as completed,max(lp.last_opened_at) as last_opened_at
   from public.lesson_progress lp
   join public.lessons l on l.id=lp.lesson_id
   join public.course_sections s on s.id=l.section_id
   where lp.user_id=actor and s.course_id=c.course_id and s.is_published and l.is_published) p
  left join lateral (
   select l.id as lesson_id
   from public.lessons l join public.course_sections s on s.id=l.section_id
   left join public.lesson_progress lp on lp.lesson_id=l.id and lp.user_id=actor
   where s.course_id=c.course_id and s.is_published and l.is_published and coalesce(lp.is_completed,false)=false
   order by s.position,l.position,l.id limit 1) n on true
  where app_private.csa117_has_access(actor,c.course_id)),'[]'::jsonb);
end; $$;
revoke all on function public.com015_my_course_progress() from public,anon,authenticated,service_role;
grant execute on function public.com015_my_course_progress() to authenticated;
comment on function public.com015_my_course_progress() is 'Per-course lesson counts and next unfinished lesson for the caller. Progress is a preference, never an entitlement.';
commit;
