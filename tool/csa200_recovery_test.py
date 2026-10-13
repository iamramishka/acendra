import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from csa200_recovery import object_restore, safe_env, run


class Safeguards(unittest.TestCase):
    def test_hosted_libpq_configuration_is_removed(self):
        with patch.dict(os.environ, {'PGHOST': 'production.invalid', 'PGSERVICE': 'prod', 'PGPASSWORD': 'synthetic'}):
            self.assertFalse(any(k.upper().startswith('PG') for k in safe_env()))

    def test_unreserved_ports_rejected_before_processes(self):
        for port in (5432, 61010, 0):
            with self.assertRaises(ValueError):
                run(Path('/missing'), port)

    def test_path_traversal_and_unknown_objects_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            for name in ('../escape', '/absolute', 'real-student.bin'):
                with self.assertRaises(ValueError):
                    object_restore({name: b'synthetic'}, Path(directory), set())

    def test_tombstones_prevent_resurrection_and_bytes_match(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory)
            object_restore({'receipt.bin': b'deleted', 'private.pdf': b'synthetic'}, target, {'receipt.bin'})
            self.assertFalse((target / 'receipt.bin').exists())
            self.assertEqual((target / 'private.pdf').read_bytes(), b'synthetic')

    def test_existing_object_directory_refused_without_mutation(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory)
            (target / 'receipt.bin').write_bytes(b'original')
            with self.assertRaises(ValueError):
                object_restore({'receipt.bin': b'replacement'}, target, set())
            self.assertEqual((target / 'receipt.bin').read_bytes(), b'original')


if __name__ == '__main__':
    unittest.main()
