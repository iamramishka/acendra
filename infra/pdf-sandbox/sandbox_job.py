"""Fixed image-side protocol; no network endpoint, secrets or client font path."""
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import socket
import sys

APP = Path('/opt/acendra')
FONT = APP / 'font/FreeSerif.ttf'
FONT_SHA256 = '658563c732eafdc851de2b3f38b27d0afcde5674b2f93440971b9693438c6494'
LIMIT = 50 * 1024 * 1024
IDENTITY_FIELDS = {'display_name', 'license_id', 'source_sha256', 'policy_id'}


def check_process_environment(environment):
    expected = {'PATH': '/opt/acendra/venv/bin:/usr/bin:/bin', 'LANG': 'C.UTF-8', 'PWD': '/work'}
    if set(environment) - set(expected) - {'LC_CTYPE'}:
        raise ValueError('environment')
    if any(environment.get(key) != value for key, value in expected.items()):
        raise ValueError('environment')
    if environment.get('LC_CTYPE', 'C.UTF-8') not in ('C.UTF-8', 'C.utf8'):
        raise ValueError('locale')


def check_environment():
    if sys.platform != 'linux' or os.getuid() == 0 or os.geteuid() == 0:
        raise ValueError('runtime')
    status = dict(line.split(':', 1) for line in Path('/proc/self/status').read_text().splitlines() if ':' in line)
    if status['NoNewPrivs'].strip() != '1' or any(int(status[key].strip(), 16) != 0 for key in ('CapEff', 'CapPrm', 'CapAmb')):
        raise ValueError('privileges')
    # bubblewrap itself sets PWD after --chdir; accept only the fixed work path.
    check_process_environment(os.environ)
    if Path('/etc').exists() or os.access(APP, os.W_OK) or os.access('/input', os.W_OK):
        raise ValueError('filesystem')
    if hashlib.sha256(FONT.read_bytes()).hexdigest() != FONT_SHA256:
        raise ValueError('font')
    # Verify the actual namespace has no outbound route before parsing a PDF.
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
        probe.settimeout(0.2)
        if probe.connect_ex(('198.51.100.1', 9)) == 0:
            raise ValueError('network')
    for line in (APP / 'requirements.txt').read_text().splitlines():
        line = line.strip()
        if line and not line.startswith('#'):
            name, version = line.split('==', 1)
            if importlib.metadata.version(name) != version:
                raise ValueError('dependency')


def read_bounded(path, maximum):
    with path.open('rb') as stream:
        raw = stream.read(maximum + 1)
    if not 0 < len(raw) <= maximum:
        raise ValueError('size')
    return raw


def read_identity(path):
    raw = read_bounded(path, 2048)
    value = json.loads(raw)
    if type(value) is not dict or set(value) != IDENTITY_FIELDS:
        raise ValueError('metadata')
    return value


def generate_job():
    source_path = Path('/input/source.pdf')
    source = read_bounded(source_path, LIMIT)
    identity = read_identity(Path('/input/identity.json'))
    # -I ignores ambient Python paths; only the read-only packaged code is added.
    sys.path.insert(0, str(APP / 'pdf_watermark'))
    from supervisor import generate_isolated
    output = generate_isolated(source, {**identity, 'trusted_font_path': str(FONT)})
    if not 0 < len(output) <= LIMIT or not output.startswith(b'%PDF-'):
        raise ValueError('output')
    descriptor = os.open('/output/derivative.pdf', os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(descriptor, 'wb') as stream:
        stream.write(output)


def main():
    try:
        if len(sys.argv) != 2 or sys.argv[1] not in ('--check', '--generate'):
            return 1
        check_environment()
        if sys.argv[1] == '--generate':
            generate_job()
        return 0
    except Exception:
        # The launcher discards child diagnostics; only a generic exit reaches SDK.
        return 1


if __name__ == '__main__':
    sys.exit(main())
