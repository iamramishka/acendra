-- COM-022: add email_notifications_enabled preference to profiles
-- locale column (D-4) already exists; this adds the D-8 backend field.

alter table public.profiles
  add column if not exists email_notifications_enabled boolean not null default true;

-- Allow authenticated users to toggle their own notification preference.
grant update (email_notifications_enabled) on table public.profiles to authenticated;
