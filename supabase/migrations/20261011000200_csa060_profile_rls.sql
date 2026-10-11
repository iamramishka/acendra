-- Own safe profiles only. Role operations remain a separately ordered migration.
begin;

create function public.csa060_account_eligible()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from auth.users u
    where u.id = (select auth.uid())
      and u.deleted_at is null
      and (u.banned_until is null or u.banned_until <= statement_timestamp())
      and coalesce(u.is_anonymous, false) = false
  );
$$;
revoke all on function public.csa060_account_eligible() from public, anon, authenticated, service_role;
grant execute on function public.csa060_account_eligible() to authenticated;

create function public.csa060_create_profile()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare candidate text;
begin
  -- Metadata is untrusted: only a bounded display string can be copied.
  if jsonb_typeof(new.raw_user_meta_data -> 'full_name') = 'string' then
    candidate := new.raw_user_meta_data ->> 'full_name';
  end if;
  if candidate is null or char_length(candidate) not between 1 and 100
    or candidate !~ '[^[:space:]]' then candidate := 'Student'; end if;
  insert into public.profiles(id, display_name) values (new.id, candidate)
    on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function public.csa060_create_profile() from public, anon, authenticated, service_role;
create trigger csa060_auth_signup_profile
  after insert on auth.users
  for each row execute function public.csa060_create_profile();

-- Preserve existing profile values; missing profiles get the same safe fallback.
insert into public.profiles(id, display_name)
select u.id, case
  when jsonb_typeof(u.raw_user_meta_data -> 'full_name') = 'string'
    and char_length(u.raw_user_meta_data ->> 'full_name') between 1 and 100
    and (u.raw_user_meta_data ->> 'full_name') ~ '[^[:space:]]'
  then u.raw_user_meta_data ->> 'full_name' else 'Student' end
from auth.users u
on conflict (id) do nothing;

revoke all on table public.profiles from public, anon, authenticated, service_role;
grant select on table public.profiles to authenticated;
grant update (display_name, locale) on table public.profiles to authenticated;

create policy csa060_profile_select_own on public.profiles
for select to authenticated
using (id = (select auth.uid()) and (select public.csa060_account_eligible()));
create policy csa060_profile_update_own on public.profiles
for update to authenticated
using (id = (select auth.uid()) and (select public.csa060_account_eligible()))
with check (id = (select auth.uid()) and (select public.csa060_account_eligible()));

comment on function public.csa060_account_eligible() is
  'Current caller eligibility only; no arbitrary identity lookup or Auth row projection.';
comment on function public.csa060_create_profile() is
  'Restricted signup trigger; no roles, avatar paths or client timestamps copied from metadata.';
commit;
