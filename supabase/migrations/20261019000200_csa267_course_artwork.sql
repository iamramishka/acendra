-- CSA-267: attach only inspected artwork; never expose originals through Storage policies.
begin;
create table app_private.course_artwork (
 course_id uuid primary key references public.courses(id) on delete restrict,
 asset_id uuid not null unique references app_private.media_assets(id) on delete restrict,
 reserved_at timestamptz not null
);
alter table app_private.course_artwork enable row level security;
revoke all on app_private.course_artwork from public,anon,authenticated,service_role;
create function app_private.csa267_attach_artwork() returns trigger
language plpgsql set search_path='' as $$
declare r app_private.csa164_media_uploads%rowtype; current_art app_private.course_artwork%rowtype;
begin
 select * into r from app_private.csa164_media_uploads where asset_id=new.asset_id;
 if r.asset_type<>'public_thumbnail' or r.policy_reference<>'csa267-media-v1' then return new; end if;
 -- Finalization already holds the common authorization/course lock. A replay does
 -- not insert another audit, so it cannot restore a superseded thumbnail.
 select * into current_art from app_private.course_artwork where course_id=r.course_id for update;
 if found and r.created_at<current_art.reserved_at then
  raise exception using errcode='22023',message='Newer artwork already selected.';
 end if;
 if not exists(select 1 from app_private.media_assets a where a.id=r.asset_id
   and a.asset_type='public_thumbnail' and a.validation_status='validated'
   and a.deleted_at is null and a.checksum_sha256=new.checksum_sha256) then
  raise exception using errcode='22023',message='Validated artwork required.';
 end if;
 insert into app_private.course_artwork(course_id,asset_id,reserved_at)
 values(r.course_id,r.asset_id,r.created_at)
 on conflict(course_id) do update set asset_id=excluded.asset_id,reserved_at=excluded.reserved_at;
 return new;
end; $$;
revoke all on function app_private.csa267_attach_artwork() from public,anon,authenticated,service_role;
create trigger csa267_attach_artwork after insert on app_private.csa164_media_validation_audit
 for each row execute function app_private.csa267_attach_artwork();

create function public.csa267_resolve_artwork(p_course uuid,p_actor uuid default null,
 p_session_id uuid default null,p_aal text default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare c public.courses%rowtype; result jsonb;
begin
 select * into c from public.courses where id=p_course;
 if not found then return null; end if;
 if c.status<>'published' then
  if p_actor is null then return null; end if;
  perform app_private.csa164_authorize(p_actor,p_session_id,p_aal,p_course,null);
 end if;
 select jsonb_build_object('asset_id',a.id,'course_id',c.id,'bucket',a.bucket_name,
  'path',a.object_path,'mime',a.mime_type,'size',a.size_bytes,'sha256',a.checksum_sha256)
 into result from app_private.course_artwork ca
 join app_private.media_assets a on a.id=ca.asset_id
 join app_private.csa164_media_uploads r on r.asset_id=a.id and r.course_id=c.id
 join app_private.csa164_media_validation_audit v on v.asset_id=a.id and v.checksum_sha256=a.checksum_sha256
 where ca.course_id=c.id and a.asset_type='public_thumbnail' and r.lesson_id is null
  and a.validation_status='validated' and a.deleted_at is null and a.validated_at is not null
  and r.policy_reference='csa267-media-v1' and v.policy_reference=r.policy_reference
  and a.bucket_name='course-media' and a.mime_type in ('image/png','image/jpeg')
  and a.size_bytes between 1 and 5242880 and a.size_bytes=r.size_bytes and a.mime_type=r.mime_type
  and a.object_path=c.id::text||'/thumbnails/'||a.id::text||case a.mime_type when 'image/png' then '.png' else '.jpg' end
  and exists(select 1 from storage.buckets b where b.id='course-media' and not b.public);
 return result;
end; $$;
revoke all on function public.csa267_resolve_artwork(uuid,uuid,uuid,text) from public,anon,authenticated,service_role;
grant execute on function public.csa267_resolve_artwork(uuid,uuid,uuid,text) to service_role;
comment on function public.csa267_resolve_artwork(uuid,uuid,uuid,text) is
 'Service-only artwork resolver. Public published covers only; draft previews recheck current content authority. Never resolves lesson media.';
commit;
