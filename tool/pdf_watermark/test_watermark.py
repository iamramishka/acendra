import hashlib
import io
import unittest
import subprocess
import sys
from pathlib import Path
from uuid import uuid4
from reportlab.pdfgen.canvas import Canvas
from pypdf import PdfReader, PdfWriter
from pypdf.generic import NameObject, DictionaryObject, BooleanObject, ArrayObject, EncodedStreamObject
from watermark import generate, Limits, WatermarkError


def fixture():
    stream = io.BytesIO()
    canvas = Canvas(stream, pagesize=(600, 800))
    for size in [(600,800),(800,600),(450,700)]:
        canvas.setPageSize(size)
        canvas.drawString(100,200,'Original selectable lesson text')
        canvas.showPage()
    canvas.save()
    reader = PdfReader(stream)
    reader.pages[1].rotate(90)
    reader.pages[2].cropbox.lower_left = (40,60)
    reader.pages[2].cropbox.upper_right = (400,650)
    writer = PdfWriter()
    for page in reader.pages: writer.add_page(page)
    out = io.BytesIO(); writer.write(out)
    return out.getvalue()

class Tests(unittest.TestCase):
    def setUp(self):
        self.source = fixture()
        self.digest = hashlib.sha256(self.source).hexdigest()
        self.identity = str(uuid4())
    def run_generation(self, source=None, **kwargs):
        return generate(source or self.source, display_name='Synthetic Student', license_id=self.identity, source_sha256=self.digest, **kwargs)
    def test_every_page_text_geometry_and_identity(self):
        output = self.run_generation()
        old,new = PdfReader(io.BytesIO(self.source)),PdfReader(io.BytesIO(output))
        for before,after in zip(old.pages,new.pages):
            self.assertIn('Original selectable lesson text',after.extract_text())
            self.assertIn('Licensed to Synthetic Student',after.extract_text())
            self.assertIn(self.identity,after.extract_text())
            self.assertEqual(before.mediabox,after.mediabox)
            self.assertEqual(before.cropbox,after.cropbox)
            self.assertEqual(before.rotation,after.rotation)
        other = generate(self.source,display_name='Other Student',license_id=str(uuid4()),source_sha256=self.digest)
        self.assertNotEqual(output,other)
        self.assertNotIn(self.identity,PdfReader(io.BytesIO(other)).pages[0].extract_text())
    def test_rejections(self):
        for limits in [Limits(max_input_bytes=1),Limits(max_pages=1),Limits(max_output_bytes=1)]:
            with self.assertRaises(WatermarkError): self.run_generation(limits=limits)
        with self.assertRaises(WatermarkError): generate(self.source,display_name='Name',license_id=self.identity,source_sha256='0'*64)
        with self.assertRaises(WatermarkError): generate(b'broken',display_name='Name',license_id=self.identity,source_sha256=hashlib.sha256(b'broken').hexdigest())
    def test_unsafe_and_tagged_and_encrypted(self):
        for kind in ['js','attachment','tagged','encrypted','action']:
            writer=PdfWriter(); writer.append(io.BytesIO(self.source))
            if kind=='js': writer.add_js('app.alert(1)')
            if kind=='attachment': writer.add_attachment('file.txt',b'secret')
            if kind=='tagged': writer.root_object[NameObject('/StructTreeRoot')]=DictionaryObject()
            if kind=='encrypted': writer.encrypt('password')
            if kind=='action': writer.root_object[NameObject('/OpenAction')]=DictionaryObject({NameObject('/S'):NameObject('/URI')})
            out=io.BytesIO(); writer.write(out); data=out.getvalue()
            with self.assertRaises(WatermarkError): generate(data,display_name='Name',license_id=self.identity,source_sha256=hashlib.sha256(data).hexdigest())
    def test_positive_bounds_and_identity(self):
        for value in [0,-1,True]:
            with self.assertRaises(WatermarkError): self.run_generation(limits=Limits(max_pages=value))
        for name in ['', 'bad\nname', '名前']:
            with self.assertRaises(WatermarkError): generate(self.source,display_name=name,license_id=self.identity,source_sha256=self.digest)



class AdditionalTests(unittest.TestCase):
    def test_all_right_angle_rotations_and_object_bound(self):
        source=fixture(); reader=PdfReader(io.BytesIO(source)); writer=PdfWriter()
        for angle in (0,90,180,270):
            page=writer.add_page(reader.pages[0]); page.rotation=angle
        stream=io.BytesIO(); writer.write(stream); data=stream.getvalue()
        digest=hashlib.sha256(data).hexdigest()
        output=generate(data,display_name='Student',license_id='22222222-2222-4222-8222-222222222222',source_sha256=digest)
        self.assertEqual([page.rotation for page in PdfReader(io.BytesIO(output)).pages],[0,90,180,270])
        with self.assertRaises(WatermarkError): generate(data,display_name='Student',license_id='22222222-2222-4222-8222-222222222222',source_sha256=digest,limits=Limits(max_objects=1))



import os
from unittest.mock import patch
from reportlab.pdfbase.ttfonts import shapeStr

class UnicodeAndSupervisorTests(unittest.TestCase):
    def test_unicode_shaping_and_missing_glyph(self):
        font=os.environ.get('CSA148_TEST_FONT','C:/Windows/Fonts/Nirmala.ttc')
        if not os.path.isfile(font): self.skipTest('Configured locale font unavailable')
        data=fixture(); digest=hashlib.sha256(data).hexdigest()
        kwargs=dict(license_id='33333333-3333-4333-8333-333333333333',source_sha256=digest,trusted_font_path=font)
        output=generate(data,display_name='රමිෂ්ක தமிழ்',**kwargs)
        reader=PdfReader(io.BytesIO(output))
        for page in reader.pages:
            self.assertIn(kwargs['license_id'],page.extract_text())
            self.assertIn('Original selectable lesson text',page.extract_text())
            self.assertIn(b'/FontFile2',output)
        name='Acedra'+hashlib.sha256(__import__('pathlib').Path(font).read_bytes()).hexdigest()[:16]
        shaped=shapeStr('රමිෂ්ක தமிழ்',name,10,force=True)
        self.assertTrue(hasattr(shaped,'__shapeData__'))
        with self.assertRaises(WatermarkError): generate(data,display_name='Student \U0010FFFF',**kwargs)
    def test_unsupported_supervisor_fails_closed(self):
        from supervisor import supervised_generate
        with patch('supervisor.os.name','nt'):
            with self.assertRaises(WatermarkError): supervised_generate(fixture())




class DeterminismTests(unittest.TestCase):
    def test_repeated_generation_is_byte_identical(self):
        from unittest.mock import patch
        data=fixture()
        kwargs=dict(display_name='Trusted Student',license_id='44444444-4444-4444-8444-444444444444',source_sha256=hashlib.sha256(data).hexdigest())
        with patch('time.time',return_value=1000000000): first=generate(data,**kwargs)
        with patch('time.time',return_value=2000000000): second=generate(data,**kwargs)
        self.assertEqual(first,second)

    def test_profile_name_limit(self):
        data=fixture()
        kwargs=dict(license_id='44444444-4444-4444-8444-444444444444',source_sha256=hashlib.sha256(data).hexdigest())
        self.assertTrue(generate(data,display_name='i'*100,**kwargs))
        with self.assertRaises(WatermarkError): generate(data,display_name='A'*101,**kwargs)

class ParserSecurityRegressionTests(unittest.TestCase):
    def test_truncated_xref_rejected_without_hanging(self):
        # Upstream GHSA-39mj-jf6j-2qj3 fixture; bound the subprocess so a
        # vulnerable parser cannot hang the test runner itself.
        body = b'%PDF-1.0\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[]/Count 0>>endobj\n'
        tail = b'\nstartxref\n%d\n%%%%EOF' % len(body)
        data = body + b'xref\n0 3\n0000000000 65535 f \n' + tail
        script = '''
import hashlib, sys
from watermark import generate, WatermarkError
data = sys.stdin.buffer.read()
try:
    generate(data, display_name='Student',
             license_id='44444444-4444-4444-8444-444444444444',
             source_sha256=hashlib.sha256(data).hexdigest())
except WatermarkError:
    raise SystemExit(0)
raise SystemExit(1)
'''
        try:
            result = subprocess.run([sys.executable, '-c', script], input=data,
                                    cwd=Path(__file__).resolve().parent,
                                    capture_output=True, timeout=10)
        except subprocess.TimeoutExpired:
            self.fail('Malformed xref did not fail closed within the deadline')
        self.assertEqual(result.returncode, 0, 'Malformed xref must reject without output')

    def test_excessive_filters_rejected_and_ordinary_filters_preserved(self):
        # Valid nested filters exercise the real merge/decode path rather than
        # rejection of an unknown filter name. No decompression bomb is needed.
        for count in (2, 17):
            with self.subTest(filter_count=count):
                reader = PdfReader(io.BytesIO(fixture()))
                writer = PdfWriter()
                page = writer.add_page(reader.pages[0])
                content = page.get_contents().get_data()
                for _ in range(count):
                    content = content.hex().encode('ascii') + b'>'
                stream = EncodedStreamObject()
                stream._data = content
                stream[NameObject('/Filter')] = ArrayObject([NameObject('/ASCIIHexDecode')] * count)
                page[NameObject('/Contents')] = writer._add_object(stream)
                source = io.BytesIO(); writer.write(source); data = source.getvalue()
                kwargs = dict(display_name='Student',
                              license_id='44444444-4444-4444-8444-444444444444',
                              source_sha256=hashlib.sha256(data).hexdigest())
                if count == 17:
                    with self.assertRaises(WatermarkError):
                        generate(data, **kwargs)
                else:
                    output = generate(data, **kwargs)
                    text = PdfReader(io.BytesIO(output)).pages[0].extract_text()
                    self.assertIn('Original selectable lesson text', text)
                    self.assertIn(kwargs['license_id'], text)

class LinuxSupervisorTests(unittest.TestCase):
    @unittest.skipUnless(__import__('sys').platform=='linux' and hasattr(os,'getuid') and os.getuid()!=0,'Requires non-root Linux runtime')
    def test_real_confined_generation_and_rejection(self):
        from supervisor import generate_isolated
        data=fixture(); kwargs=dict(display_name='Student',license_id='44444444-4444-4444-8444-444444444444',source_sha256=hashlib.sha256(data).hexdigest())
        result=generate_isolated(data,kwargs)
        self.assertIn(kwargs['license_id'],PdfReader(io.BytesIO(result)).pages[0].extract_text())
        with self.assertRaises(WatermarkError): generate_isolated(data,{**kwargs,'limits':Limits(max_output_bytes=1)})

    def test_wall_timeout_kills_child_and_cleans_up(self):
        from unittest.mock import MagicMock,patch
        from supervisor import supervised_generate
        fake=MagicMock(); fake.is_alive.side_effect=[True,False]
        context=MagicMock(); context.Process.return_value=fake
        path_type=type(__import__('pathlib').Path('.'))
        with patch('supervisor.Path',path_type),patch('supervisor.sys.platform','linux'),patch('supervisor.os.name','posix'),patch('supervisor.os.getuid',return_value=1000,create=True),patch('supervisor.multiprocessing.get_context',return_value=context):
            with self.assertRaises(WatermarkError): supervised_generate(fixture(),wall_seconds=1)
        fake.kill.assert_called_once()
        fake.close.assert_called_once()

if __name__=='__main__': unittest.main()
