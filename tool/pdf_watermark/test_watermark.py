import hashlib
import io
import unittest
from uuid import uuid4
from reportlab.pdfgen.canvas import Canvas
from pypdf import PdfReader, PdfWriter
from pypdf.generic import NameObject, DictionaryObject, BooleanObject
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

if __name__=='__main__': unittest.main()

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
