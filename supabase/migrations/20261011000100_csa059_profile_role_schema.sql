-- CSA-059: schema foundation only. CSA-060/061 add reviewed access policies
-- and trusted role operations. No signup metadata is authoritative for roles.
begin;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete restrict,
  display_name text not null,
  avatar_path text,
  locale text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_valid check (
    char_length(btrim(display_name)) between 1 and 100
  ),
  constraint profiles_avatar_path_nonempty check (
    avatar_path is null or char_length(btrim(avatar_path)) > 0
  ),
  constraint profiles_locale_nonempty check (
    locale is null or char_length(btrim(locale)) > 0
  ),
  constraint profiles_timestamp_order check (updated_at >= created_at)
);

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  constraint roles_code_supported check (
    code in ('student', 'content_manager', 'finance_admin', 'super_admin')
  ),
  constraint roles_name_nonempty check (char_length(btrim(name)) > 0)
);

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete restrict,
  role_id uuid not null references public.roles (id) on delete restrict,
  granted_by uuid references public.profiles (id) on delete restrict,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz,
  revoked_by uuid references public.profiles (id) on delete restrict,
  constraint user_roles_revocation_order check (
    revoked_at is null or revoked_at >= granted_at
  ),
  constraint user_roles_revocation_actor check (
    revoked_by is null or revoked_at is not null
  )
);

create unique index user_roles_one_active_grant
  on public.user_roles (user_id, role_id) where revoked_at is null;
-- Include revoked history and actor references in FK lookup indexes.
create index user_roles_user_id_idx on public.user_roles (user_id);
create index user_roles_role_id_idx on public.user_roles (role_id);
create index user_roles_granted_by_idx on public.user_roles (granted_by);
create index user_roles_revoked_by_idx on public.user_roles (revoked_by);

create function public.csa059_set_profile_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := statement_timestamp();
  return new;
end;
$$;

revoke all on function public.csa059_set_profile_updated_at()
  from public, anon, authenticated, service_role;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.csa059_set_profile_updated_at();

insert into public.roles (code, name, description) values
  ('student', 'Student', 'Ordinary authenticated user; no elevated capability.'),
  ('content_manager', 'Content Manager', 'Authoring within current assigned courses.'),
  ('finance_admin', 'Finance Admin', 'Explicit finance operations with independent verification.'),
  ('super_admin', 'Super Admin', 'Explicit administrative operations subject to audit and safeguards.');

-- Deny access even on installations with permissive default table grants.
-- No permissive policies or privileged RPCs are introduced in this task.
alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.user_roles enable row level security;
revoke all on table public.profiles, public.roles, public.user_roles
  from public, anon, authenticated, service_role;

comment on table public.profiles is
  'Application profile, separate from Auth credentials and authoritative roles. CSA-060 owns client access.';
comment on column public.profiles.avatar_path is
  'Optional storage reference; not a public URL. Validation/delivery requires the approved storage policy.';
comment on table public.user_roles is
  'Current and historical role grants. Trusted assignment, bootstrap, MFA and audit operations belong to CSA-061.';
comment on column public.user_roles.granted_by is
  'Nullable for controlled operator bootstrap/system provenance; never public signup.';

commit;
