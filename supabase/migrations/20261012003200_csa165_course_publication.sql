begin;
create table app_private.csa165_publication_audit (
 id uuid primary key default gen_random_uuid(), actor_id uuid not null references public.profiles(id) on delete restrict,
 course_id uuid not null references public.courses(id) on delete restrict,
 command_key text not null, payload jsonb not null, result jsonb not null,
 old_status text not null, new_status text not null, occurred_at timestamptz not null default clock_timestamp(),
 unique(actor_id,command_key)
);
alter table app_private.csa165_publication_audit enable row level security;
revoke all on app_private.csa165_publication_audit from public,anon,authenticated,service_role;
create trigger csa165_audit_no_change before update or delete on app_private.csa165_publication_audit for each row execute function app_private.csa089_audit_immutable();
create trigger csa165_audit_no_truncate before truncate on app_private.csa165_publication_audit for each statement execute function app_private.csa089_audit_immutable();
create function public.csa165_publish_course(p_actor uuid,p_session_id uuid,p_aal text,p_course uuid,p_expected timestamptz,p_action text,p_key text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u auth.users%rowtype; s auth.sessions%rowtype; c public.courses%rowtype;
 prior app_private.csa165_publication_audit%rowtype; payload jsonb; result jsonb; target text;
begin
 perform pg_catalog.pg_advisory_xact_lock(610061);
 select * into u from auth.users where id=p_actor for share;
 if not found or u.deleted_at is not null or coalesce(u.is_anonymous,false) or (u.banned_until is not null and u.banned_until>clock_timestamp()) then raise exception using errcode='42501',message='Current authority required.';end if;
 select * into s from auth.sessions where id=p_session_id and user_id=p_actor for share;
 if not found or p_aal is distinct from 'aal2' or s.aal::text is distinct from 'aal2' or (s.not_after is not null and s.not_after<=clock_timestamp())
 or not exists(select 1 from public.user_roles ur join public.roles r on r.id=ur.role_id where ur.user_id=p_actor and ur.revoked_at is null and r.code='super_admin') then raise exception using errcode='42501',message='Current authority required.';end if;
 if p_course is null or p_expected is null or p_action is null or p_action not in ('publish','unpublish') or p_key is null or p_key !~ '^[A-Za-z0-9._:-]{1,128}$' then raise exception using errcode='22023',message='Invalid command.';end if;
 payload:=jsonb_build_object('course_id',p_course,'expected_updated_at',p_expected,'action',p_action);
 select * into prior from app_private.csa165_publication_audit where actor_id=p_actor and command_key=p_key;
 if found then if prior.payload is distinct from payload then raise exception using errcode='40001',message='Command conflict.';end if;return prior.result||jsonb_build_object('replayed',true);end if;
 select * into c from public.courses where id=p_course for update;
 if not found then raise exception using errcode='P0002',message='Course missing.';end if;
 if c.updated_at is distinct from p_expected then raise exception using errcode='40001',message='Course conflict.';end if;
 if (p_action='publish' and c.status<>'draft') or (p_action='unpublish' and c.status<>'published') then raise exception using errcode='55000',message='Invalid transition.';end if;
 if p_action='publish' then
  -- Table SHARE locks stop inserts, updates and deletes through readiness/commit.
  -- Order: role authority -> course -> curriculum -> associations -> media.
  lock table public.course_sections,public.lessons,app_private.lesson_assets,app_private.media_assets in share mode;
  if c.currency_code<>'LKR' or c.price_minor<0 or nullif(btrim(c.description),'') is null
   or nullif(btrim(c.short_description),'') is null
   or (c.category_id is not null and not exists(select 1 from public.categories where id=c.category_id and is_active))
   or (c.thumbnail_path is not null and not exists(select 1 from app_private.media_assets ma where ma.asset_type='public_thumbnail' and ma.object_path=c.thumbnail_path and ma.validation_status='validated' and ma.validated_at is not null and ma.deleted_at is null and ma.mime_type in ('image/jpeg','image/png') and ma.size_bytes>0))
   or not exists(select 1 from public.course_sections where course_id=p_course and is_published)
   or exists(select 1 from public.course_sections cs where cs.course_id=p_course and cs.is_published and not exists(select 1 from public.lessons l where l.section_id=cs.id and l.is_published)) then raise exception using errcode='23514',message='Course incomplete.';end if;
  if exists(select 1 from public.lessons l join public.course_sections cs on cs.id=l.section_id where cs.course_id=p_course and cs.is_published and l.is_published and
   (l.lesson_type='text' or not exists(select 1 from app_private.lesson_assets la join app_private.media_assets ma on ma.id=la.media_asset_id where la.lesson_id=l.id
    and ma.validation_status='validated' and ma.validated_at is not null and ma.deleted_at is null and ma.checksum_sha256 is not null and ma.size_bytes>0
    and ((l.lesson_type='pdf' and ma.asset_type='course_pdf' and ma.mime_type='application/pdf' and ma.bucket_name='course-pdfs' and ma.object_path is not null)
     or (l.lesson_type='image' and ma.asset_type='lesson_image' and ma.mime_type in ('image/jpeg','image/png') and ma.bucket_name is not null and ma.object_path is not null)
     or (l.lesson_type='video' and ma.asset_type='course_video' and ma.storage_provider='mux' and ma.external_asset_id is not null)))
   or exists(select 1 from app_private.lesson_assets la join app_private.media_assets ma on ma.id=la.media_asset_id where la.lesson_id=l.id and (ma.validation_status<>'validated' or ma.validated_at is null or ma.deleted_at is not null or ma.asset_type not in ('course_pdf','lesson_image','course_video'))))) then raise exception using errcode='23514',message='Lesson content not ready.';end if;
 end if;
 target:=case when p_action='publish' then 'published' else 'draft' end;
 update public.courses set status=target,published_at=case when p_action='publish' then clock_timestamp() else null end where id=p_course returning * into c;
 result:=jsonb_build_object('course_id',c.id,'status',c.status,'published_at',c.published_at,'updated_at',c.updated_at,'replayed',false);
 insert into app_private.csa165_publication_audit(actor_id,course_id,command_key,payload,result,old_status,new_status) values(p_actor,p_course,p_key,payload,result,case when p_action='publish' then 'draft' else 'published' end,target);
 return result;
end;$$;
revoke all on function public.csa165_publish_course(uuid,uuid,text,uuid,timestamptz,text,text) from public,anon,authenticated,service_role;
grant execute on function public.csa165_publish_course(uuid,uuid,text,uuid,timestamptz,text,text) to service_role;
commit;
