"""Image build only: fetch a hash-pinned GNU font with its distribution notices."""
import hashlib
import io
import json
from pathlib import Path
import urllib.request
import zipfile

URL = 'https://ftp.gnu.org/gnu/freefont/freefont-ttf-20120503.zip'
ARCHIVE_SHA256 = '7c85baf1bf82a1a1845d1322112bc6ca982221b484e3b3925022e25b5cae89af'
FONT_SHA256 = '658563c732eafdc851de2b3f38b27d0afcde5674b2f93440971b9693438c6494'


def install(destination):
    with urllib.request.urlopen(URL, timeout=30) as response:
        data = response.read(10 * 1024 * 1024 + 1)
    if len(data) > 10 * 1024 * 1024 or hashlib.sha256(data).hexdigest() != ARCHIVE_SHA256:
        raise ValueError('Unverified font archive')
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for name in ('FreeSerif.ttf', 'COPYING', 'CREDITS', 'README'):
            content = archive.read('freefont-20120503/' + name)
            if name == 'FreeSerif.ttf' and hashlib.sha256(content).hexdigest() != FONT_SHA256:
                raise ValueError('Unverified font')
            (destination / name).write_bytes(content)
    (destination / 'provenance.json').write_text(json.dumps({
        'url': URL, 'archive_sha256': ARCHIVE_SHA256, 'font_sha256': FONT_SHA256,
        'license': 'GPL-3.0-or-later WITH Font-exception-2.0',
    }, indent=2) + '\n')


if __name__ == '__main__':
    install(Path('/opt/acendra/font'))
