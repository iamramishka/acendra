-- CSA-133: JWT-derived ownership; progress never creates an entitlement.
begin;
create function app_private.csa133_require_access(p_course uuid) returns uuid
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
 if p_course is null then raise exception using errcode='42501',message='Course access required.'; end if;
 perform pg_advisory_xact_lock(hashtext(actor::text),hashtext(p_course::text));
 if not app_private.csa117_has_access(actor,p_course) then
  raise exception using errcode='42501',message='Course access required.';
 end if;
 return actor;
end; $$;
revoke all on function app_private.csa133_require_access(uuid) from public,anon,authenticated,service_role;

create function public.csa133_save_progress(p_lesson uuid,p_completed boolean,
 p_pdf_page integer default null,p_pdf_position numeric default null,p_video_seconds integer default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare course uuid; actor uuid; lesson public.lessons%rowtype; progress public.lesson_progress%rowtype;
begin
 -- Resolve metadata only; no lesson existence or content is exposed on denial.
 select s.course_id into course from public.lessons l join public.course_sections s on s.id=l.section_id where l.id=p_lesson;
 actor:=app_private.csa133_require_access(course);
 select l.* into lesson from public.lessons l join public.course_sections s on s.id=l.section_id
 where l.id=p_lesson and s.course_id=course and l.is_published and s.is_published for share of l,s;
 if not found then raise exception using errcode='42501',message='Published lesson access required.'; end if;
 if p_completed is null or
  (p_pdf_page is not null and (lesson.lesson_type<>'pdf' or p_pdf_page<1)) or
  (p_pdf_position is not null and (lesson.lesson_type<>'pdf' or p_pdf_page is null or not (p_pdf_position>=0 and p_pdf_position<=1))) or
  (p_video_seconds is not null and (lesson.lesson_type<>'video' or p_video_seconds<0 or (lesson.duration_seconds is not null and p_video_seconds>lesson.duration_seconds))) then
  raise exception using errcode='22023',message='Valid completion and lesson-specific position required.';
 end if;
 insert into public.lesson_progress(user_id,lesson_id,is_completed,pdf_page,pdf_position,progress_seconds,last_opened_at)
 values(actor,p_lesson,p_completed,p_pdf_page,p_pdf_position,p_video_seconds,clock_timestamp())
 on conflict(user_id,lesson_id) do update set is_completed=excluded.is_completed,pdf_page=excluded.pdf_page,
 pdf_position=excluded.pdf_position,progress_seconds=excluded.progress_seconds,last_opened_at=excluded.last_opened_at
 returning * into progress;
 return jsonb_build_object('lesson_id',progress.lesson_id,'is_completed',progress.is_completed,
  'pdf_page',progress.pdf_page,'pdf_position',progress.pdf_position,'progress_seconds',progress.progress_seconds,
  'last_opened_at',progress.last_opened_at,'updated_at',progress.updated_at);
end; $$;

create function public.csa133_read_progress(p_course uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid;
begin
 actor:=app_private.csa133_require_access(p_course);
 return coalesce((select jsonb_agg(jsonb_build_object('lesson_id',p.lesson_id,'is_completed',p.is_completed,
  'pdf_page',p.pdf_page,'pdf_position',p.pdf_position,'progress_seconds',p.progress_seconds,
  'last_opened_at',p.last_opened_at,'updated_at',p.updated_at) order by s.position,l.position,l.id)
 from public.lesson_progress p join public.lessons l on l.id=p.lesson_id join public.course_sections s on s.id=l.section_id
 where p.user_id=actor and s.course_id=p_course and s.is_published and l.is_published),'[]'::jsonb);
end; $$;
revoke all on function public.csa133_save_progress(uuid,boolean,integer,numeric,integer),public.csa133_read_progress(uuid)
 from public,anon,authenticated,service_role;
grant execute on function public.csa133_save_progress(uuid,boolean,integer,numeric,integer),public.csa133_read_progress(uuid) to authenticated;
comment on table public.lesson_progress is 'Private student resume data. Only CSA-133 JWT-derived current-session, entitlement-checked RPCs expose read/write access.';
commit;
