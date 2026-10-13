-- Minimal native-only shims, not the Supabase Auth/Storage runtime.
create role anon;
create role authenticated;
create role service_role bypassrls;
create schema auth;
create schema storage;
create schema extensions;
create table auth.users(id uuid primary key,raw_user_meta_data jsonb,deleted_at timestamptz,banned_until timestamptz,is_anonymous boolean default false,email text);
create table auth.sessions(id uuid primary key,user_id uuid references auth.users(id),aal text,not_after timestamptz);
create function auth.jwt() returns jsonb language sql stable as $$select coalesce(nullif(current_setting('request.jwt.claims',true),''),'{}')::jsonb$$;
create function auth.uid() returns uuid language sql stable as $$select (auth.jwt()->>'sub')::uuid$$;
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text references storage.buckets(id),name text,owner uuid,metadata jsonb,unique(bucket_id,name));
alter table storage.objects enable row level security;
grant usage on schema public,auth,storage,extensions to anon,authenticated,service_role;
grant select on storage.objects to authenticated;
