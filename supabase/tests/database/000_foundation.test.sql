begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(8);
select has_schema('auth', 'Supabase Auth schema exists');
select has_schema('storage', 'Supabase Storage schema exists');
select has_table('auth', 'users', 'Auth user identity table exists');
select has_table('storage', 'objects', 'Storage object metadata exists');
select has_table('public', 'profiles', 'Ordered migrations created profiles');
select has_table('public', 'roles', 'Ordered migrations created role definitions');
select has_table('public', 'user_roles', 'Ordered migrations created role history');
select ok(exists (
  select from pg_constraint
  where conrelid = 'public.profiles'::regclass
    and confrelid = 'auth.users'::regclass and contype = 'f'
), 'Application profile identity references actual Supabase Auth users');
select * from finish();
rollback;
