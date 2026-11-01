-- CSA-271 / COM-020: owner D-3 branding with privacy-safe opaque license IDs.
-- Version the immutable identity so v1 objects are never rewritten or reused as v2.
-- Session, entitlement, storage, worker and privilege contracts are unchanged.
begin;

create or replace function public.csa140_resolve_pdf(p_actor uuid,p_session_id uuid,p_aal text,p_lesson uuid,p_resource uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare course uuid; asset app_private.media_assets; derivative app_private.pdf_derivatives; actor_name text;
 policy constant uuid:='14000000-0000-4000-8000-000000000002'::uuid;
begin
 perform app_private.csa108_require_session(p_actor,p_session_id,p_aal,false);
 select s.course_id into course from public.lessons l join public.course_sections s on s.id=l.section_id
 join public.courses c on c.id=s.course_id
 where l.id=p_lesson and l.lesson_type='pdf' and l.is_published and s.is_published;
 if course is null then raise exception 'PDF_NOT_FOUND' using errcode='P0002'; end if;
 if not app_private.csa117_has_access(p_actor,course) then raise exception 'ACCESS_DENIED' using errcode='42501'; end if;
 -- Ambiguous associations cannot silently select a different source.
 if (select count(*) from app_private.lesson_assets la join app_private.media_assets m on m.id=la.media_asset_id where la.lesson_id=p_lesson and m.asset_type='course_pdf')<>1 then
 raise exception 'PDF_NOT_FOUND' using errcode='P0002'; end if;
 select m.* into asset from app_private.lesson_assets la join app_private.media_assets m on m.id=la.media_asset_id
 where la.lesson_id=p_lesson and m.asset_type='course_pdf' and m.storage_provider='supabase' and m.bucket_name='course-pdfs'
 and m.object_path='originals/'||m.id::text||'/v'||m.content_version::text||'.pdf'
 and m.validation_status='validated' and m.validated_at is not null and m.deleted_at is null and m.mime_type='application/pdf'
 and m.size_bytes between 1 and 52428800;
 if asset.id is null then raise exception 'PDF_NOT_FOUND' using errcode='P0002'; end if;
 if not exists(select 1 from storage.buckets where id='course-pdfs' and public=false and file_size_limit between 1 and 52428800 and allowed_mime_types=array['application/pdf']::text[]) then
 raise exception 'SERVICE_UNAVAILABLE' using errcode='55000'; end if;
 select display_name into actor_name from public.profiles where id=p_actor;
 if exists(select 1 from app_private.pdf_derivatives d where d.actor_id=p_actor and d.asset_id=asset.id
 and d.asset_version=asset.content_version and d.source_digest=asset.checksum_sha256 and d.policy_id=policy and d.display_name=actor_name
 and (d.state='failed' or (d.state='preparing' and d.attempts>=3 and (d.lease_until is null or d.lease_until<=clock_timestamp())))) then
 raise exception 'SERVICE_UNAVAILABLE' using errcode='55000'; end if;
 if p_resource is null then
 select d.* into derivative from app_private.pdf_derivatives d where d.actor_id=p_actor and d.asset_id=asset.id and d.asset_version=asset.content_version
 and d.source_digest=asset.checksum_sha256 and d.policy_id=policy and d.display_name=actor_name and d.state='ready';
 else
 select d.* into derivative from app_private.pdf_derivatives d where d.id=p_resource and d.actor_id=p_actor and d.asset_id=asset.id
 and d.asset_version=asset.content_version and d.source_digest=asset.checksum_sha256 and d.policy_id=policy and d.display_name=actor_name and d.state='ready';
 if derivative.id is null then raise exception 'PDF_NOT_FOUND' using errcode='P0002'; end if;
 end if;
 if derivative.id is null then
 -- A single durable reservation per trusted identity/version. Never return source.
 declare new_license uuid:=gen_random_uuid(); begin
 insert into app_private.pdf_derivatives(actor_id,asset_id,asset_version,source_digest,license_id,policy_id,display_name,object_path)
 values(p_actor,asset.id,asset.content_version,asset.checksum_sha256,new_license,policy,actor_name,
 'derivatives/'||asset.id::text||'/v'||asset.content_version::text||'/'||new_license::text||'/'||policy::text||'.pdf')
 on conflict(actor_id,asset_id,asset_version,source_digest,policy_id,display_name) do nothing;
 end;
 return jsonb_build_object('state','preparing','lesson_id',p_lesson,'resource_id',null);
 end if;
 if not exists(select 1 from storage.objects where bucket_id='course-pdfs' and name=derivative.object_path) then
 raise exception 'SERVICE_UNAVAILABLE' using errcode='55000'; end if;
 return jsonb_build_object('state','ready','lesson_id',p_lesson,'resource_id',derivative.id,'bucket','course-pdfs','object_path',derivative.object_path,'size_bytes',derivative.size_bytes,'checksum_sha256',derivative.checksum_sha256);
end; $$;
revoke all on function public.csa140_resolve_pdf(uuid,uuid,text,uuid,uuid) from public,anon,authenticated,service_role;
grant execute on function public.csa140_resolve_pdf(uuid,uuid,text,uuid,uuid) to service_role;

commit;
