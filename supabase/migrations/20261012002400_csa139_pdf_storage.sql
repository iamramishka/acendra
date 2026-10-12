-- CSA-139: originals and derivatives have no direct student delivery path.
begin;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
 values('course-pdfs','course-pdfs',false,52428800,array['application/pdf'])
 on conflict(id) do nothing;
do $$ begin
 if not exists(select 1 from storage.buckets where id='course-pdfs' and name='course-pdfs'
   and public=false and file_size_limit between 1 and 52428800
   and allowed_mime_types=array['application/pdf']::text[]) then
  raise exception 'Unsafe existing PDF bucket configuration.' using errcode='23514';
 end if;
end; $$;
create policy csa139_no_direct_pdf on storage.objects as restrictive for all to anon,authenticated
 using(bucket_id<>'course-pdfs') with check(bucket_id<>'course-pdfs');
create policy csa139_no_direct_pdf_bucket on storage.buckets as restrictive for all to anon,authenticated
 using(id<>'course-pdfs') with check(id<>'course-pdfs');
create function app_private.csa139_pdf_path_valid(p_name text)
returns boolean language sql immutable set search_path='' as $$
 select coalesce(p_name ~ '^(originals/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/v[1-9][0-9]{0,8}|derivatives/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/v[1-9][0-9]{0,8}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\.pdf$',false);
$$;
create function app_private.csa139_pdf_bucket_guard()
returns trigger language plpgsql set search_path='' as $$
begin
 if tg_op='DELETE' then
  if old.id='course-pdfs' then raise exception 'Protected PDF bucket cannot be deleted.' using errcode='23514'; end if;
  return old;
 end if;
 if tg_op='UPDATE' and old.id='course-pdfs' and new.id is distinct from old.id then
  raise exception 'Protected PDF bucket identity is immutable.' using errcode='23514';
 end if;
 if new.id='course-pdfs' and (new.name is distinct from 'course-pdfs'
   or new.public is distinct from false or new.file_size_limit is null
   or new.file_size_limit not between 1 and 52428800
   or new.allowed_mime_types is distinct from array['application/pdf']::text[]) then
  raise exception 'Protected PDFs require private bounded PDF-only storage.' using errcode='23514';
 end if;
 return new;
end; $$;
create function app_private.csa139_pdf_object_guard()
returns trigger language plpgsql set search_path='' as $$
begin
 if tg_op='UPDATE' and (old.bucket_id='course-pdfs' or new.bucket_id='course-pdfs') then
  raise exception 'PDF objects are immutable; create a new version.' using errcode='23514';
 end if;
 if new.bucket_id='course-pdfs' and not app_private.csa139_pdf_path_valid(new.name) then
  raise exception 'Invalid protected PDF object identity.' using errcode='23514';
 end if;
 return new;
end; $$;
-- Trigger functions need private function lookup while Storage uses service_role.
-- SECURITY DEFINER is bounded to path validation; no client-callable RPC is granted.
alter function app_private.csa139_pdf_object_guard() security definer;
revoke all on function app_private.csa139_pdf_path_valid(text),app_private.csa139_pdf_bucket_guard(),app_private.csa139_pdf_object_guard()
 from public,anon,authenticated,service_role;
create trigger csa139_pdf_bucket_guard before insert or update or delete on storage.buckets
 for each row execute function app_private.csa139_pdf_bucket_guard();
create trigger csa139_pdf_object_guard before insert or update on storage.objects
 for each row execute function app_private.csa139_pdf_object_guard();
do $$ begin
 if exists(select 1 from storage.objects where bucket_id='course-pdfs' and not app_private.csa139_pdf_path_valid(name)) then
  raise exception 'Existing PDF objects require reviewed migration.' using errcode='23514';
 end if;
end; $$;
comment on function app_private.csa139_pdf_path_valid(text) is
 'Opaque originals/<asset>/v<version>.pdf or derivatives/<asset>/v<version>/<license>/<watermark-policy>.pdf; no student identifiers or filenames.';
commit;
