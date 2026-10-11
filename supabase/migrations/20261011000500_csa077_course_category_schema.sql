-- CSA-077 metadata foundation. CSA-079 owns reviewed publication/authoring access.
begin;
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  sort_order integer not null default 0 check (sort_order >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint categories_name_valid check (char_length(name) between 1 and 200 and name ~ '[^[:space:]]'),
  constraint categories_slug_valid check (char_length(slug) between 1 and 200 and slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  constraint categories_timestamp_order check (updated_at >= created_at)
);
create table public.courses (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories(id) on delete restrict,
  slug text not null unique,
  title text not null,
  short_description text,
  description text,
  thumbnail_path text,
  price_minor bigint not null check (price_minor >= 0),
  currency_code text not null default 'LKR' check (currency_code = 'LKR'),
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_by uuid references public.profiles(id) on delete restrict,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint courses_title_valid check (char_length(title) between 1 and 200 and title ~ '[^[:space:]]'),
  constraint courses_slug_valid check (char_length(slug) between 1 and 200 and slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  constraint courses_published_metadata check (status <> 'published' or published_at is not null),
  constraint courses_timestamp_order check (updated_at >= created_at),
  constraint courses_thumbnail_nonblank check (thumbnail_path is null or thumbnail_path ~ '[^[:space:]]')
);
create index categories_listing_idx on public.categories(is_active,sort_order,id);
create index courses_category_id_idx on public.courses(category_id);
create index courses_created_by_idx on public.courses(created_by);
create index courses_publication_idx on public.courses(status,published_at desc,id);
create function public.csa077_set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at := statement_timestamp(); return new; end;
$$;
revoke all on function public.csa077_set_updated_at() from public,anon,authenticated,service_role;
create trigger categories_set_updated_at before update on public.categories
  for each row execute function public.csa077_set_updated_at();
create trigger courses_set_updated_at before update on public.courses
  for each row execute function public.csa077_set_updated_at();
alter table public.categories enable row level security;
alter table public.courses enable row level security;
revoke all on table public.categories,public.courses from public,anon,authenticated,service_role;
comment on table public.courses is 'Marketplace metadata only. CSA-079 supplies reviewed access; trusted checkout snapshots current price into orders.';
comment on column public.courses.thumbnail_path is 'Optional storage reference; not a content authorization or delivery URL.';
comment on column public.courses.price_minor is 'Exact LKR minor units. Zero is allowed; historical order prices are independent snapshots.';
commit;
