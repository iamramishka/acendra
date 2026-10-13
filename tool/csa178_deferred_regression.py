"""Reproduce restricted-caller deferred checks before/after the scoped migration."""
import os
from pathlib import Path
import subprocess
import tempfile
from csa200_recovery import BOOTSTRAP, ROOT, safe_env

pg_bin = Path('C:/Program Files/PostgreSQL/17/bin')
port = 61615
env = safe_env()
with tempfile.TemporaryDirectory(prefix='acendra-csa178-deferred-') as scratch:
    task_root = Path(scratch)
    cluster = task_root / 'cluster'
    started = False
    def run(name, args, sql=None):
        return subprocess.run([str(pg_bin / (name + ('.exe' if os.name == 'nt' else ''))), *args],
                              input=sql, text=True, capture_output=True, env=env, timeout=60)
    def query(sql):
        return run('psql', ['-h','127.0.0.1','-p',str(port),'-U','postgres','-d','postgres',
                            '-v','ON_ERROR_STOP=1','-qAt'], sql)
    try:
        assert run('initdb', ['-D',str(cluster),'-U','postgres','-A','trust','--encoding=UTF8','--locale=C']).returncode == 0
        with (task_root / 'control.log').open('w') as log:
            start = subprocess.run([str(pg_bin / 'pg_ctl.exe'), '-D',str(cluster),'-l',str(task_root / 'server.log'),
                                    '-o',f'-h 127.0.0.1 -p {port}','-w','start'],
                                   stdout=log, stderr=log, env=env, timeout=60)
        assert start.returncode == 0
        started = True
        assert query(BOOTSTRAP).returncode == 0
        fix = ROOT / 'supabase/migrations/20261013003400_csa178_deferred_financial_checks.sql'
        for migration in sorted((ROOT / 'supabase/migrations').glob('*.sql')):
            if migration == fix:
                continue
            result = query(migration.read_text(encoding='utf-8-sig'))
            assert result.returncode == 0, f'Migration failed: {migration.name}'
        regression = (ROOT / 'supabase/tests/database/csa178_deferred_financial_checks.test.sql').read_text()
        before = query(regression)
        assert before.returncode != 0 and 'permission denied for table orders' in before.stderr
        print('RED: restricted service caller fails deferred orders permission check before migration034.')
        assert query(fix.read_text()).returncode == 0
        after = query(regression)
        assert after.returncode == 0, 'Corrected deferred check regression must pass.'
        assert after.stdout.count('ok ') == 4
        print('GREEN: four deferred-check and privilege regressions pass after migration034.')
    finally:
        if started:
            with (task_root / 'stop.log').open('w') as log:
                stop = subprocess.run([str(pg_bin / 'pg_ctl.exe'),'-D',str(cluster),'-m','fast','-w','stop'],
                                      stdout=log, stderr=log, env=env, timeout=60)
            if stop.returncode:
                raise RuntimeError('Task-owned regression cluster cleanup failed.')
