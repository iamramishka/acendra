-- CSA-164: reservations are private; readiness is issued only after trusted byte inspection.
begin;
create table app_private.csa164_media_uploads (
 asset_id uuid primary key references app_private.media_assets(id) on delete restrict,
 actor_id uuid not null references public.profiles(id) on delete restrict,
 request_id uuid not null, course_id uuid not null references public.courses(id) on delete restrict,
 lesson_id uuid not null references public.lessons(id) on delete restrict,
 asset_type text not null check(asset_type in ('course_pdf','lesson_image')),
 mime_type text not null check(mime_type in ('application/pdf','image/png','image/jpeg')),
 size_bytes bigint not null check(size_bytes>0), policy_reference text not null check(policy_reference ~ '^[A-Za-z0-9._:-]{1,128}$'),
 created_at timestamptz not null default now(), unique(actor_id,request_id)
);
alter table app_private.csa164_media_uploads enable row level security;
revoke all on app_private.csa164_media_uploads from public,anon,authenticated,service_role;
create table app_private.csa164_media_validation_audit (
 asset_id uuid primary key references app_private.media_assets(id) on delete restrict,
 actor_id uuid not null references public.profiles(id) on delete restrict,
 checksum_sha256 text not null, policy_reference text not null, occurred_at timestamptz not null default now()
);
alter table app_private.csa164_media_validation_audit enable row level security;
revoke all on app_private.csa164_media_validation_audit from public,anon,authenticated,service_role;
create function app_private.csa164_immutable() returns trigger language plpgsql set search_path='' as $$
begin raise exception using errcode='42501',message='Media upload history is immutable.'; end; $$;
revoke all on function app_private.csa164_immutable() from public,anon,authenticated,service_role;
create trigger csa164_reservation_immutable before update or delete on app_private.csa164_media_uploads for each row execute function app_private.csa164_immutable();
create trigger csa164_reservation_no_truncate before truncate on app_private.csa164_media_uploads for each statement execute function app_private.csa164_immutable();
create trigger csa164_validation_immutable before update or delete on app_private.csa164_media_validation_audit for each row execute function app_private.csa164_immutable();
create trigger csa164_validation_no_truncate before truncate on app_private.csa164_media_validation_audit for each statement execute function app_private.csa164_immutable();
create function app_private.csa164_authorize(p_actor uuid,p_session_id uuid,p_aal text,p_course uuid,p_lesson uuid) returns void language plpgsql set search_path='' as $$
declare u auth.users%rowtype;s auth.sessions%rowtype;v_super boolean;v_manager boolean;
begin
 perform pg_catalog.pg_advisory_xact_lock(610061);
 if not exists(select 1 from storage.buckets where id='course-media' and not public) then raise exception using errcode='42501',message='Private storage required.';end if;
 select * into u from auth.users where id=p_actor for share;
 if not found or u.deleted_at is not null or coalesce(u.is_anonymous,false) or (u.banned_until is not null and u.banned_until>clock_timestamp()) then raise exception using errcode='42501',message='Current account required.';end if;
 select * into s from auth.sessions where id=p_session_id and user_id=p_actor for share;
 if not found or p_aal is null or p_aal not in ('aal1','aal2') or s.aal::text is distinct from p_aal or (s.not_after is not null and s.not_after<=clock_timestamp()) then raise exception using errcode='42501',message='Current session required.';end if;
 select coalesce(bool_or(r.code='super_admin'),false),coalesce(bool_or(r.code='content_manager'),false) into v_super,v_manager from public.user_roles ur join public.roles r on r.id=ur.role_id where ur.user_id=p_actor and ur.revoked_at is null;
 if (not v_super and not v_manager) or (v_super and p_aal<>'aal2') then raise exception using errcode='42501',message='Content authority required.';end if;
 perform 1 from public.courses where id=p_course for update;
 if not found then raise exception using errcode='P0002',message='Course not found.';end if;
 if not v_super then
 perform 1 from public.course_staff where course_id=p_course and user_id=p_actor and revoked_at is null for share;
 if not found then raise exception using errcode='42501',message='Current course assignment required.';end if;end if;
 perform 1 from public.lessons l join public.course_sections sec on sec.id=l.section_id where l.id=p_lesson and sec.course_id=p_course for share of l,sec;
 if not found then raise exception using errcode='22023',message='Lesson relationship invalid.';end if;
end; $$;
revoke all on function app_private.csa164_authorize(uuid,uuid,text,uuid,uuid) from public,anon,authenticated,service_role;
create function public.csa164_get_media_upload(p_actor uuid,p_session_id uuid,p_aal text,p_asset uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare r app_private.csa164_media_uploads%rowtype;a app_private.media_assets%rowtype;
begin
 select * into r from app_private.csa164_media_uploads where asset_id=p_asset;
 if not found then raise exception using errcode='P0002',message='Asset not found.';end if;
 perform app_private.csa164_authorize(p_actor,p_session_id,p_aal,r.course_id,r.lesson_id);
 if not exists(select 1 from storage.buckets where id='course-media' and not public) then raise exception using errcode='42501',message='Private storage required.';end if;
 select * into a from app_private.media_assets where id=p_asset for share;
 if a.deleted_at is not null or a.validation_status='rejected' then raise exception using errcode='22023',message='Asset unavailable.';end if;
 return jsonb_build_object('asset_id',r.asset_id,'course_id',r.course_id,'lesson_id',r.lesson_id,'asset_type',r.asset_type,'mime',r.mime_type,'size',r.size_bytes,'bucket',a.bucket_name,'path',a.object_path,'policy_reference',r.policy_reference,'validated',a.validation_status='validated');
end; $$;
create function public.csa164_prepare_media_upload(p_actor uuid,p_session_id uuid,p_aal text,p_request_id uuid,p_course uuid,p_lesson uuid,p_type text,p_mime text,p_size bigint,p_policy text) returns jsonb language plpgsql security definer set search_path='' as $$
declare r app_private.csa164_media_uploads%rowtype;v_asset uuid:=gen_random_uuid();v_extension text;
begin
 perform app_private.csa164_authorize(p_actor,p_session_id,p_aal,p_course,p_lesson);
 if p_type is null or p_mime is null or p_request_id is null or p_size is null or p_size<=0 or p_policy is null or p_policy !~ '^[A-Za-z0-9._:-]{1,128}$' or not ((p_type='course_pdf' and p_mime='application/pdf') or (p_type='lesson_image' and p_mime in ('image/png','image/jpeg'))) then raise exception using errcode='22023',message='Invalid upload metadata.';end if;
 if not exists(select 1 from public.lessons where id=p_lesson and lesson_type=case p_type when 'course_pdf' then 'pdf' else 'image' end) then raise exception using errcode='22023',message='Asset type does not match lesson.';end if;
 select * into r from app_private.csa164_media_uploads where actor_id=p_actor and request_id=p_request_id;
 if found then
 if row(r.course_id,r.lesson_id,r.asset_type,r.mime_type,r.size_bytes,r.policy_reference) is distinct from row(p_course,p_lesson,p_type,p_mime,p_size,p_policy) then raise exception using errcode='22023',message='Request payload conflict.';end if;
 return public.csa164_get_media_upload(p_actor,p_session_id,p_aal,r.asset_id);end if;
 v_extension:=case p_mime when 'application/pdf' then 'pdf' when 'image/png' then 'png' else 'jpg' end;
 insert into app_private.media_assets(id,asset_type,storage_provider,bucket_name,object_path,mime_type,size_bytes,uploaded_by) values(v_asset,p_type,'supabase','course-media',p_course::text||'/'||p_lesson::text||'/'||v_asset::text||'.'||v_extension,p_mime,p_size,p_actor);
 insert into app_private.csa164_media_uploads(asset_id,actor_id,request_id,course_id,lesson_id,asset_type,mime_type,size_bytes,policy_reference) values(v_asset,p_actor,p_request_id,p_course,p_lesson,p_type,p_mime,p_size,p_policy);
 return public.csa164_get_media_upload(p_actor,p_session_id,p_aal,v_asset);
end; $$;
create function public.csa164_finalize_media_upload(p_actor uuid,p_session_id uuid,p_aal text,p_asset uuid,p_digest text,p_size bigint,p_mime text,p_policy text) returns jsonb language plpgsql security definer set search_path='' as $$
declare r app_private.csa164_media_uploads%rowtype;a app_private.media_assets%rowtype;v_position integer;
begin
 select * into r from app_private.csa164_media_uploads where asset_id=p_asset;
 if not found then raise exception using errcode='P0002',message='Asset not found.';end if;
 perform app_private.csa164_authorize(p_actor,p_session_id,p_aal,r.course_id,r.lesson_id);
 -- Same global order as publication: role, course, associations, assets.
 lock table app_private.lesson_assets in share row exclusive mode;
 select * into a from app_private.media_assets where id=p_asset for update;
 if p_digest is null or p_digest !~ '^[0-9a-f]{64}$' or row(p_size,p_mime,p_policy) is distinct from row(r.size_bytes,r.mime_type,r.policy_reference) or a.deleted_at is not null or a.validation_status='rejected' then raise exception using errcode='22023',message='Inspection identity conflict.';end if;
 if a.validation_status='validated' then
 if a.checksum_sha256 is distinct from p_digest then raise exception using errcode='22023',message='Validated content conflict.';end if;
 return jsonb_build_object('asset_id',p_asset,'status','validated','replayed',true);end if;
 if not exists(select 1 from public.lessons where id=r.lesson_id and lesson_type=case r.asset_type when 'course_pdf' then 'pdf' else 'image' end) then raise exception using errcode='22023',message='Lesson type changed.';end if;
 update app_private.media_assets set checksum_sha256=p_digest,validation_status='validated',validated_at=clock_timestamp() where id=p_asset;
 select coalesce(max(position)+1,0) into v_position from app_private.lesson_assets where lesson_id=r.lesson_id;
 insert into app_private.lesson_assets(lesson_id,media_asset_id,usage,position) values(r.lesson_id,p_asset,'primary',v_position);
 insert into app_private.csa164_media_validation_audit(asset_id,actor_id,checksum_sha256,policy_reference) values(p_asset,p_actor,p_digest,p_policy);
 return jsonb_build_object('asset_id',p_asset,'status','validated','replayed',false);
end; $$;
revoke all on function public.csa164_get_media_upload(uuid,uuid,text,uuid),public.csa164_prepare_media_upload(uuid,uuid,text,uuid,uuid,uuid,text,text,bigint,text),public.csa164_finalize_media_upload(uuid,uuid,text,uuid,text,bigint,text,text) from public,anon,authenticated,service_role;
grant execute on function public.csa164_get_media_upload(uuid,uuid,text,uuid),public.csa164_prepare_media_upload(uuid,uuid,text,uuid,uuid,uuid,text,text,bigint,text),public.csa164_finalize_media_upload(uuid,uuid,text,uuid,text,bigint,text,text) to service_role;
-- Bucket provision is deployment-gated; all upload calls require a private bucket.
insert into storage.buckets(id,name,public) values('course-media','course-media',false);
commit;



