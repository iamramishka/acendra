"""Disposable native PostgreSQL recovery drill; never accepts a connection URL."""
import argparse
import difflib
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
BOOTSTRAP = '''
create role anon; create role authenticated; create role service_role;
create schema auth; create schema storage; create schema extensions;
create table auth.users(id uuid primary key,raw_user_meta_data jsonb,deleted_at timestamptz,banned_until timestamptz,is_anonymous boolean default false,email text);
create table auth.sessions(id uuid primary key,user_id uuid references auth.users(id),aal text,not_after timestamptz);
create function auth.jwt() returns jsonb language sql stable as $$select coalesce(nullif(current_setting('request.jwt.claims',true),''),'{}')::jsonb$$;
create function auth.uid() returns uuid language sql stable as $$select (auth.jwt()->>'sub')::uuid$$;
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text references storage.buckets(id),name text,owner uuid,metadata jsonb,unique(bucket_id,name));
alter table storage.objects enable row level security;
grant usage on schema public,auth,storage,extensions to anon,authenticated,service_role;
grant select on storage.objects,storage.buckets to authenticated;
'''

def safe_env():
    # libpq environment variables can redirect connections or execute services.
    return {k: v for k, v in os.environ.items() if not k.upper().startswith('PG')}

def object_restore(backup, destination, ledger):
    """Restore allowlisted synthetic bytes, replay tombstones before availability."""
    if destination.is_symlink() or not destination.is_dir() or any(destination.iterdir()):
        raise ValueError('Object restore requires a new empty directory')
    if not set(backup).issubset({'private.pdf', 'lesson.bin', 'receipt.bin', 'course.png'}):
        raise ValueError('Unexpected object name')
    for name, content in backup.items():
        if name in ledger:
            continue
        (destination / name).write_bytes(content)
        if hashlib.sha256((destination / name).read_bytes()).digest() != hashlib.sha256(content).digest():
            raise ValueError('Object digest mismatch')

def run(bin_dir, port):
    if not 61000 <= port <= 61009:
        raise ValueError('CSA-200 only uses reserved loopback ports 61000..61009')
    env = safe_env()
    started = False
    with tempfile.TemporaryDirectory(prefix='acendra-csa200-') as scratch:
        base = Path(scratch)
        data = base / 'cluster'
        def call(tool, args, sql=None):
            if tool == 'pg_ctl':
                with (base / 'control.log').open('a') as log:
                    process = subprocess.Popen([str(bin_dir / (tool + ('.exe' if os.name == 'nt' else ''))), *args],
                                               stdin=subprocess.DEVNULL, stdout=log, stderr=log, env=env)
                    deadline = time.monotonic() + 60
                    while process.poll() is None:
                        if time.monotonic() > deadline:
                            raise TimeoutError('pg_ctl did not exit')
                        time.sleep(0.1)
                if process.returncode:
                    raise RuntimeError('pg_ctl failed; inspect isolated control log')
                return ''
            result = subprocess.run([str(bin_dir / (tool + ('.exe' if os.name == 'nt' else ''))), *args],
                                    input=sql, text=True, capture_output=True, env=env)
            if result.returncode:
                raise RuntimeError(f'{tool} failed: {result.stderr[-3000:]}')
            return result.stdout
        def query(db, sql):
            return call('psql', ['-X', '-h', '127.0.0.1', '-p', str(port), '-U', 'postgres', '-d', db,
                                  '-v', 'ON_ERROR_STOP=1', '-A', '-t'], sql)
        try:
            call('initdb', ['-D', str(data), '-U', 'postgres', '--auth-local=trust', '--auth-host=trust', '--encoding=UTF8'])
            # No TCP access beyond loopback; all data and logs are synthetic and temporary.
            call('pg_ctl', ['-D', str(data), '-l', str(base / 'postgres.log'), '-o', f'-h 127.0.0.1 -p {port}', '-w', 'start'])
            started = True
            query('postgres', 'create database csa200_source;')
            query('postgres', 'create database csa200_restored;')
            query('postgres', 'create database csa200_schema_normalized;')
            query('csa200_source', BOOTSTRAP)
            migrations = sorted((ROOT / 'supabase/migrations').glob('*.sql'))
            for migration in migrations:
                query('csa200_source', migration.read_text(encoding='utf-8-sig'))
            # Existing financial suite supplies meaningful constrained fixtures and
            # verifies them. Commit this disposable fixture transaction for backup.
            fixture = (ROOT / 'supabase/tests/database/csa096_financial_integrity.test.sql').read_text()
            if fixture.count('rollback;') != 1:
                raise ValueError('Fixture rollback shape changed; review before use')
            fixture_result = query('csa200_source', fixture.replace('rollback;', 'commit;'))
            for name in ('csa121_126_financial_recovery.test.sql', 'csa133_progress.test.sql'):
                extra = (ROOT / 'supabase/tests/database' / name).read_text()
                if not extra.rstrip().endswith('rollback;'):
                    raise ValueError('Fixture final rollback changed')
                extra = extra.rsplit('rollback;', 1)[0] + 'commit;'
                fixture_result += query('csa200_source', extra)
            def fingerprint(db):
                sql = '''
create function pg_temp.csa200_snapshot() returns jsonb language plpgsql as $$
declare item record; rows_json jsonb; result jsonb := '{}'::jsonb;
begin
 for item in select schemaname,tablename from pg_tables
   where schemaname in ('public','app_private','auth','storage') order by 1,2 loop
  execute format('select coalesce(jsonb_agg(to_jsonb(t) order by to_jsonb(t)::text), ''[]''::jsonb) from %I.%I t',item.schemaname,item.tablename) into rows_json;
  result := result || jsonb_build_object(item.schemaname||'.'||item.tablename,rows_json);
 end loop;
 return result;
end $$;
select pg_temp.csa200_snapshot();
'''
                result = query(db, sql)
                rows = json.loads(result[result.index('{'):])
                return {name: {'rows': len(value), 'sha256': hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()}
                        for name, value in rows.items()}
            before = fingerprint('csa200_source')
            archive = base / 'database.dump'
            begin = time.monotonic()
            call('pg_dump', ['-h','127.0.0.1','-p',str(port),'-U','postgres','-d','csa200_source','-Fc','-f',str(archive)])
            dump_seconds = time.monotonic() - begin
            begin = time.monotonic()
            call('pg_restore', ['-h','127.0.0.1','-p',str(port),'-U','postgres','-d','csa200_restored','--exit-on-error',str(archive)])
            restore_seconds = time.monotonic() - begin
            after = fingerprint('csa200_restored')
            if before != after:
                raise AssertionError('Restored rows differ from backup source')
            # Compare schema-only dumps: includes policies, grants, functions,
            # constraints and ownership. Random dump restrict tokens are excluded.
            def schema(db):
                text = call('pg_dump', ['-h','127.0.0.1','-p',str(port),'-U','postgres','-d',db,'--schema-only'])
                return '\n'.join(line for line in text.splitlines() if not line.startswith(('\\restrict', '\\unrestrict')))
            source_schema, restored_schema = schema('csa200_source'), schema('csa200_restored')
            # PostgreSQL reparses CHECK expressions on restore, flattening nested
            # associative AND groups. Independently reparse source DDL rather
            # than stripping parentheses or weakening comparison assertions.
            query('csa200_schema_normalized', source_schema)
            normalized_schema = schema('csa200_schema_normalized')
            if normalized_schema != restored_schema:
                difference = '\n'.join(difflib.unified_diff(normalized_schema.splitlines(), restored_schema.splitlines()))
                raise AssertionError('Restored schema, policies or grants differ: ' + difference[:4000])
            policy = ROOT / 'supabase/tests/database/csa074_profile_isolation.test.sql'
            query('csa200_restored', policy.read_text())
            objects = {'private.pdf': b'%PDF synthetic', 'lesson.bin': b'synthetic lesson',
                       'receipt.bin': b'synthetic receipt', 'course.png': b'synthetic course'}
            target = base / 'objects'; target.mkdir()
            object_restore(objects, target, {'receipt.bin'})
            if (target / 'receipt.bin').exists():
                raise AssertionError('Deleted receipt resurrected')
            return {'migrations': len(migrations), 'table_fingerprints': after,
                    'dump_seconds': round(dump_seconds, 3), 'restore_seconds': round(restore_seconds, 3),
                    'schema_acl_rls_equal': True, 'profile_isolation_restored': True,
                    'financial_fixture_assertions': fixture_result.count('ok '),
                    'synthetic_objects_restored': 3, 'deletion_tombstones_replayed': 1,
                    'scope': 'native PostgreSQL17 with synthetic Auth/Storage shims; not Supabase/provider recovery'}
        finally:
            # pg_ctl can start postgres before its own wait command fails.
            # Only this newly created task-owned directory is ever inspected.
            if started or (data / 'postmaster.pid').exists():
                call('pg_ctl', ['-D', str(data), '-m', 'fast', '-w', 'stop'])

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--postgres-bin', type=Path, default=Path('C:/Program Files/PostgreSQL/17/bin'))
    parser.add_argument('--port', type=int, default=61000)
    args = parser.parse_args()
    print(json.dumps(run(args.postgres_bin, args.port), indent=2))
