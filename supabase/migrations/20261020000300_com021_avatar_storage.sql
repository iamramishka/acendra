-- COM-021: private avatar storage. Each user may read and write only objects
-- in their own '<auth.uid()>/' folder. Delivery to the UI is by short-lived
-- signed URL; the bucket is never public.
begin;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

do $$ begin
  if not exists (
    select 1 from storage.buckets
    where id = 'avatars' and name = 'avatars' and public = false
      and file_size_limit between 1 and 5242880
      and allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']::text[]
  ) then
    raise exception 'Unsafe existing avatars bucket configuration.' using errcode = '23514';
  end if;
end; $$;

create policy com021_avatar_select_own on storage.objects
  for select to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select public.csa060_account_eligible())
  );

create policy com021_avatar_insert_own on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select public.csa060_account_eligible())
  );

create policy com021_avatar_update_own on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select public.csa060_account_eligible())
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select public.csa060_account_eligible())
  );

create policy com021_avatar_delete_own on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select public.csa060_account_eligible())
  );

-- profiles.avatar_path already exists (CSA-059). Let the owner set it (row
-- access is still limited to the own row by csa060_profile_update_own) and
-- only to a path inside their own avatar folder.
alter table public.profiles
  add constraint profiles_avatar_path_own_folder check (
    avatar_path is null or avatar_path like id::text || '/%'
  );
grant update (avatar_path) on table public.profiles to authenticated;

comment on constraint profiles_avatar_path_own_folder on public.profiles is
  'COM-021: avatar objects live in the private avatars bucket under <profile id>/.';

commit;
