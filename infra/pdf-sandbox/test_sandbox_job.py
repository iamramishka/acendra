import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from sandbox_job import read_bounded, read_identity, check_process_environment


class ImageProtocolTests(unittest.TestCase):
    def test_fixed_environment_accepts_bubblewrap_pwd_but_no_secrets_or_path_override(self):
        environment = {'PATH': '/opt/acendra/venv/bin:/usr/bin:/bin', 'LANG': 'C.UTF-8', 'PWD': '/work'}
        check_process_environment(environment)
        for invalid in [{**environment, 'SUPABASE_SERVICE_ROLE_KEY': 'synthetic'},
                        {**environment, 'PWD': '/untrusted'}, {**environment, 'PATH': '/untrusted'}]:
            with self.assertRaises(ValueError):
                check_process_environment(invalid)

    def test_identity_accepts_only_fixed_backend_fields(self):
        identity = {'display_name': 'Synthetic Student', 'license_id': 'opaque',
                    'source_sha256': 'digest', 'policy_id': 'policy'}
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'identity.json'
            path.write_text(json.dumps(identity))
            self.assertEqual(read_identity(path), identity)
            for invalid in [{**identity, 'trusted_font_path': '/untrusted'}, [], None, {'display_name': 'Only'}]:
                path.write_text(json.dumps(invalid))
                with self.assertRaises(ValueError):
                    read_identity(path)

    def test_file_bounds_reject_empty_and_excessive_input(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'bytes'
            path.write_bytes(b'abc')
            self.assertEqual(read_bounded(path, 3), b'abc')
            for content in [b'', b'abcd']:
                path.write_bytes(content)
                with self.assertRaises(ValueError):
                    read_bounded(path, 3)
            path.write_bytes(b'x' * 2049)
            with self.assertRaises(ValueError):
                read_identity(path)

    def test_unconfined_invocation_returns_no_document_or_private_diagnostics(self):
        # This is a rejection test, not a simulated successful Linux sandbox.
        script = Path(__file__).with_name('sandbox_job.py')
        result = subprocess.run([sys.executable, str(script), '--generate'],
                                capture_output=True, timeout=5)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, b'')
        self.assertEqual(result.stderr, b'')


if __name__ == '__main__':
    unittest.main()
