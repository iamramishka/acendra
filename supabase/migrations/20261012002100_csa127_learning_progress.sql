-- CSA-127 model only; CSA-133 owns authorized persistence and read contracts.
begin;
create table public.lesson_progress (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 lesson_id uuid not null references public.lessons(id) on delete cascade,
 progress_seconds integer,
 pdf_page integer,
 pdf_position numeric,
 is_completed boolean not null default false,
 last_opened_at timestamptz,
 created_at timestamptz not null default statement_timestamp(),
 updated_at timestamptz not null default statement_timestamp(),
 constraint lesson_progress_user_lesson_unique unique(user_id,lesson_id),
 constraint lesson_progress_seconds_nonnegative check(progress_seconds is null or progress_seconds>=0),
 constraint lesson_progress_pdf_page_positive check(pdf_page is null or pdf_page>0),
 constraint lesson_progress_pdf_position_bounds check(pdf_position is null or (pdf_page is not null and pdf_position>=0 and pdf_position<=1)),
 constraint lesson_progress_timestamp_order check(updated_at>=created_at)
);
create index lesson_progress_user_resume on public.lesson_progress(user_id,last_opened_at desc nulls last,lesson_id);
create index lesson_progress_user_updated on public.lesson_progress(user_id,updated_at desc);
create index lesson_progress_lesson on public.lesson_progress(lesson_id);

create function public.csa127_progress_metadata() returns trigger
language plpgsql set search_path='' as $$
begin
 if new.id is distinct from old.id or new.user_id is distinct from old.user_id or new.lesson_id is distinct from old.lesson_id then
  raise exception using errcode='23514',message='Progress identity is immutable.';
 end if;
 new.created_at:=old.created_at;
 new.updated_at:=greatest(old.updated_at,statement_timestamp());
 return new;
end; $$;
revoke all on function public.csa127_progress_metadata() from public,anon,authenticated,service_role;
create trigger csa127_progress_metadata before update on public.lesson_progress
for each row execute function public.csa127_progress_metadata();
alter table public.lesson_progress enable row level security;
revoke all on public.lesson_progress from public,anon,authenticated,service_role;
comment on table public.lesson_progress is 'Student-owned resume/completion data, not an entitlement or assessment. No application access until CSA-133 implements authorization.';
comment on column public.lesson_progress.pdf_position is 'Normalized within-page scroll offset [0,1]; requires pdf_page. Page plus offset fulfills FR-LEARN-007 PDF resume.';
comment on column public.lesson_progress.is_completed is 'Student completion preference only; never evidence for certificates or financial/course access.';
commit;
