-- Preserve historical/non-upload audit paths; only CSA-267 reservations attach artwork.
begin;
create or replace function app_private.csa267_attach_artwork() returns trigger
language plpgsql set search_path='' as $$
declare r app_private.csa164_media_uploads%rowtype; current_art app_private.course_artwork%rowtype;
begin
 select * into r from app_private.csa164_media_uploads where asset_id=new.asset_id;
 if not found or r.asset_type is distinct from 'public_thumbnail'
   or r.policy_reference is distinct from 'csa267-media-v1' then return new; end if;
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
commit;
