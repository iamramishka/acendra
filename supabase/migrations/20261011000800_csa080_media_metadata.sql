-- CSA-080: private metadata only, never direct client media delivery.
begin;
create schema if not exists app_private;
create table app_private.media_assets (
 id uuid primary key default gen_random_uuid(),
 asset_type text not null,
 storage_provider text not null,
 bucket_name text,
 object_path text,
 external_asset_id text,
 mime_type text,
 size_bytes bigint,
 checksum_sha256 text,
 uploaded_by uuid references public.profiles(id) on delete restrict,
 content_version integer not null default 1,
 validation_status text not null default 'pending',
 validated_at timestamptz,
 created_at timestamptz not null default now(),
 deleted_at timestamptz,
 constraint media_assets_type check (asset_type in ('course_pdf','lesson_image','course_video','bank_receipt','public_thumbnail','other')),
 constraint media_assets_provider check (storage_provider ~ '[^[:space:]]'),
 constraint media_assets_bucket check (bucket_name is null or bucket_name ~ '[^[:space:]]'),
 constraint media_assets_path check (object_path is null or object_path ~ '[^[:space:]]'),
 constraint media_assets_external check (external_asset_id is null or external_asset_id ~ '[^[:space:]]'),
 constraint media_assets_mime check (mime_type is null or mime_type ~ '[^[:space:]]'),
 constraint media_assets_size check (size_bytes is null or size_bytes >= 0),
 constraint media_assets_digest check (checksum_sha256 is null or checksum_sha256 ~ '^[0-9a-f]{64}$'),
 constraint media_assets_version check (content_version > 0),
 constraint media_assets_status check (validation_status in ('pending','validated','rejected')),
 constraint media_assets_storage_pair check ((bucket_name is null) = (object_path is null)),
 constraint media_assets_validation_time check (validated_at is null or validated_at >= created_at),
 constraint media_assets_deletion_time check (deleted_at is null or deleted_at >= created_at),
 constraint media_assets_validated_shape check (
   validation_status <> 'validated' or (
     validated_at is not null and deleted_at is null and checksum_sha256 is not null
     and mime_type is not null and size_bytes is not null
     and ((bucket_name is not null and object_path is not null) or external_asset_id is not null)
   )
 )
);
create index media_assets_uploaded_by_idx on app_private.media_assets(uploaded_by);
create table app_private.lesson_assets (
 id uuid primary key default gen_random_uuid(),
 lesson_id uuid not null references public.lessons(id) on delete restrict,
 media_asset_id uuid not null references app_private.media_assets(id) on delete restrict,
 usage text not null,
 position integer not null,
 created_at timestamptz not null default now(),
 constraint lesson_assets_usage check (usage ~ '[^[:space:]]'),
 constraint lesson_assets_position check (position >= 0),
 constraint lesson_assets_order unique(lesson_id,position),
 constraint lesson_assets_association unique(lesson_id,media_asset_id,usage)
);
create index lesson_assets_media_asset_idx on app_private.lesson_assets(media_asset_id);
create function app_private.csa080_preserve_validated_identity()
returns trigger language plpgsql set search_path='' as $$
begin
 if old.validated_at is not null and (
   new.validated_at is distinct from old.validated_at
   or row(new.asset_type,new.storage_provider,new.bucket_name,new.object_path,
          new.external_asset_id,new.mime_type,new.size_bytes,new.checksum_sha256,
          new.content_version,new.created_at,new.uploaded_by)
      is distinct from
      row(old.asset_type,old.storage_provider,old.bucket_name,old.object_path,
          old.external_asset_id,old.mime_type,old.size_bytes,old.checksum_sha256,
          old.content_version,old.created_at,old.uploaded_by)
 ) then
   raise exception 'Validated media identity is immutable; create a new asset version.' using errcode='23514';
 end if;
 return new;
end;
$$;
create trigger media_assets_preserve_validated_identity before update on app_private.media_assets
 for each row execute function app_private.csa080_preserve_validated_identity();
revoke all on function app_private.csa080_preserve_validated_identity()
 from public,anon,authenticated,service_role;
alter table app_private.media_assets enable row level security;
alter table app_private.lesson_assets enable row level security;
revoke all on table app_private.media_assets,app_private.lesson_assets
 from public,anon,authenticated,service_role;
-- Schema is already private in the identity baseline; preserve that boundary.
revoke all on schema app_private from public,anon,authenticated,service_role;
comment on table app_private.media_assets is
 'Private immutable validated media metadata. Status=validated, validated_at present and deleted_at absent are necessary readiness conditions, never authorization.';
comment on column app_private.media_assets.validated_at is
 'First successful validation marker; retained unchanged even after rejection/deletion. Content replacement creates a new asset row.';
comment on table app_private.lesson_assets is
 'Private lesson associations. Asset UUID possession conveys no access; trusted delivery checks current entitlement.';
commit;
