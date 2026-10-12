-- Requires CSA139 migration024. No original or student Storage delivery grant.
begin;
create table app_private.pdf_derivatives (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid not null references public.profiles(id) on delete restrict,
 asset_id uuid not null references app_private.media_assets(id) on delete restrict,
 asset_version integer not null check(asset_version>0),
 source_digest text not null check(source_digest ~ '^[0-9a-f]{64}$'),
 license_id uuid not null default gen_random_uuid(),
 policy_id uuid not null,
 display_name text not null check(char_length(display_name) between 1 and 100 and display_name !~ '[[:cntrl:]]'),
 state text not null default 'preparing' check(state in ('preparing','ready','failed')),
 object_path text not null unique,
 size_bytes bigint check(size_bytes between 1 and 52428800),
 checksum_sha256 text check(checksum_sha256 ~ '^[0-9a-f]{64}$'),
 created_at timestamptz not null default clock_timestamp(),
 ready_at timestamptz,
 lease_token uuid,
 lease_until timestamptz,
 attempts integer not null default 0 check(attempts between 0 and 3),
 unique(actor_id,asset_id,asset_version,source_digest,policy_id,display_name),
 constraint pdf_derivative_path check(object_path='derivatives/'||asset_id::text||'/v'||asset_version::text||'/'||license_id::text||'/'||policy_id::text||'.pdf'),
 constraint pdf_derivative_ready check((state='ready' and size_bytes is not null and checksum_sha256 is not null and ready_at is not null) or (state<>'ready' and size_bytes is null and checksum_sha256 is null and ready_at is null))
);
create index pdf_derivatives_actor on app_private.pdf_derivatives(actor_id);
create index pdf_derivatives_asset on app_private.pdf_derivatives(asset_id);
alter table app_private.pdf_derivatives enable row level security;
revoke all on app_private.pdf_derivatives from public,anon,authenticated,service_role;
-- Ready resource bytes/identity cannot change between ranges.
create function app_private.csa140_preserve_derivative() returns trigger
language plpgsql set search_path='' as $$ begin
 if old.state='ready' or row(new.id,new.actor_id,new.asset_id,new.asset_version,new.source_digest,new.license_id,new.policy_id,new.display_name,new.object_path,new.created_at)
 is distinct from row(old.id,old.actor_id,old.asset_id,old.asset_version,old.source_digest,old.license_id,old.policy_id,old.display_name,old.object_path,old.created_at) then
 raise exception 'PDF derivative identity is immutable.' using errcode='23514'; end if;
 return new;
end; $$;
create trigger pdf_derivative_immutable before update on app_private.pdf_derivatives for each row execute function app_private.csa140_preserve_derivative();
revoke all on function app_private.csa140_preserve_derivative() from public,anon,authenticated,service_role;

create function public.csa140_resolve_pdf(p_actor uuid,p_session_id uuid,p_aal text,p_lesson uuid,p_resource uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare course uuid; asset app_private.media_assets; derivative app_private.pdf_derivatives; actor_name text;
 policy constant uuid:='14000000-0000-4000-8000-000000000001';
begin
 perform app_private.csa108_require_session(p_actor,p_session_id,p_aal,false);
 select s.course_id into course from public.lessons l join public.course_sections s on s.id=l.section_id
 join public.courses c on c.id=s.course_id
 where l.id=p_lesson and l.lesson_type='pdf' and l.is_published and s.is_published and c.status='published' and c.published_at is not null;
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
create function public.csa148_claim_pdf_job() returns jsonb
language plpgsql security definer set search_path='' as $$
declare d app_private.pdf_derivatives; asset app_private.media_assets; token uuid:=gen_random_uuid();
begin
 select x.* into d from app_private.pdf_derivatives x join auth.users u on u.id=x.actor_id
 where x.state='preparing' and x.attempts<3 and (x.lease_until is null or x.lease_until<clock_timestamp())
 and u.deleted_at is null and not coalesce(u.is_anonymous,false) and (u.banned_until is null or u.banned_until<=clock_timestamp())
 and exists(select 1 from app_private.lesson_assets la join public.lessons l on l.id=la.lesson_id
 join public.course_sections s on s.id=l.section_id join public.courses c on c.id=s.course_id
 where la.media_asset_id=x.asset_id and l.is_published and s.is_published and c.status='published' and app_private.csa117_has_access(x.actor_id,c.id))
 order by x.created_at for update of x skip locked limit 1;
 if d.id is null then return null; end if;
 select * into asset from app_private.media_assets where id=d.asset_id and content_version=d.asset_version and checksum_sha256=d.source_digest
 and validation_status='validated' and deleted_at is null and bucket_name='course-pdfs' and mime_type='application/pdf';
 if asset.id is null then update app_private.pdf_derivatives set state='failed' where id=d.id; return null; end if;
 update app_private.pdf_derivatives set lease_token=token,lease_until=clock_timestamp()+interval '90 seconds',attempts=attempts+1 where id=d.id;
 return jsonb_build_object('resource_id',d.id,'lease_token',token,'bucket','course-pdfs','source_path',asset.object_path,'source_digest',d.source_digest,
 'size_bytes',asset.size_bytes,'display_name',d.display_name,'license_id',d.license_id,'object_path',d.object_path);
end; $$;
create function public.csa148_complete_pdf_job(p_resource uuid,p_lease uuid,p_digest text,p_size bigint) returns boolean
language plpgsql security definer set search_path='' as $$
declare d app_private.pdf_derivatives;
begin
 select * into d from app_private.pdf_derivatives where id=p_resource for update;
 if d.id is null or d.state<>'preparing' or d.lease_token is distinct from p_lease or d.lease_until<=clock_timestamp()
 or p_digest is null or p_digest !~ '^[0-9a-f]{64}$' or p_size is null or p_size not between 1 and 52428800 then
 raise exception 'Invalid PDF job completion.' using errcode='22023'; end if;
 if not exists(select 1 from storage.objects where bucket_id='course-pdfs' and name=d.object_path) then
 raise exception 'PDF output absent.' using errcode='55000'; end if;
 update app_private.pdf_derivatives set state='ready',size_bytes=p_size,checksum_sha256=p_digest,ready_at=clock_timestamp(),lease_token=null,lease_until=null where id=d.id;
 return true;
end; $$;
revoke all on function public.csa148_claim_pdf_job(),public.csa148_complete_pdf_job(uuid,uuid,text,bigint) from public,anon,authenticated,service_role;
grant execute on function public.csa148_claim_pdf_job(),public.csa148_complete_pdf_job(uuid,uuid,text,bigint) to service_role;
comment on table app_private.pdf_derivatives is 'Trusted offline worker registration only pending deployment approval; no browser/service direct DML. Per-actor immutable personalized bytes. Missing readiness never authorizes original fallback.';
commit;
