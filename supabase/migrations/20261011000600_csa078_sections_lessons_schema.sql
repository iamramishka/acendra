-- CSA-078 metadata foundation; CSA-079 owns publication policies and access.
begin;
create table public.course_sections (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete restrict,
  title text not null,
  description text,
  position integer not null,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint course_sections_title_nonblank check (char_length(title) between 1 and 200 and title ~ '[^[:space:]]'),
  constraint course_sections_position_nonnegative check (position >= 0),
  constraint course_sections_course_position_unique unique (course_id, position),
  constraint course_sections_timestamp_order check (updated_at >= created_at)
);
create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  section_id uuid not null references public.course_sections(id) on delete restrict,
  title text not null,
  description text,
  lesson_type text not null,
  position integer not null,
  duration_seconds integer,
  is_preview boolean not null default false,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint lessons_title_nonblank check (char_length(title) between 1 and 200 and title ~ '[^[:space:]]'),
  constraint lessons_type_supported check (lesson_type in ('video','pdf','text','image')),
  constraint lessons_position_nonnegative check (position >= 0),
  constraint lessons_section_position_unique unique (section_id, position),
  constraint lessons_duration_nonnegative check (duration_seconds is null or duration_seconds >= 0),
  constraint lessons_timestamp_order check (updated_at >= created_at)
);
-- Parent-first unique indexes also support FK lookup and curriculum ordering.
create function public.csa078_set_metadata_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := statement_timestamp();
  return new;
end;
$$;
revoke all on function public.csa078_set_metadata_updated_at()
  from public, anon, authenticated, service_role;
create trigger course_sections_set_updated_at before update on public.course_sections
  for each row execute function public.csa078_set_metadata_updated_at();
create trigger lessons_set_updated_at before update on public.lessons
  for each row execute function public.csa078_set_metadata_updated_at();
alter table public.course_sections enable row level security;
alter table public.lessons enable row level security;
revoke all on table public.course_sections, public.lessons
  from public, anon, authenticated, service_role;
comment on table public.course_sections is
  'Curriculum metadata only; no application grants or publication policies until CSA-079.';
comment on table public.lessons is
  'Safe metadata only. Never store paid body, private paths, signed URLs or playback secrets here.';
comment on column public.lessons.is_preview is
  'Metadata designation only; does not authorize protected lesson content delivery.';
commit;
