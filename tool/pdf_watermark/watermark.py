"""Local trusted PDF derivative generation; never a client authorization API."""
import hashlib
import io
import math
import re
import unicodedata
from pathlib import Path
from dataclasses import dataclass
from uuid import UUID
from pypdf import PdfReader, PdfWriter
from pypdf.generic import DictionaryObject, ArrayObject, IndirectObject
from reportlab.pdfgen.canvas import Canvas
from reportlab.pdfbase.pdfmetrics import stringWidth, registerFont
from reportlab.pdfbase.ttfonts import TTFont, shapeStr

class WatermarkError(ValueError):
    """Fail-closed input or generation failure; contains no document data."""

@dataclass(frozen=True)
class Limits:
    max_input_bytes: int = 50 * 1024 * 1024
    max_pages: int = 500
    max_output_bytes: int = 50 * 1024 * 1024
    max_objects: int = 100000

class _BoundedOutput(io.BytesIO):
    def __init__(self, limit):
        super().__init__(); self.limit = limit
    def write(self, data):
        if self.tell() + len(data) > self.limit:
            raise WatermarkError('Output bound exceeded')
        return super().write(data)

# Reject interactive content, signatures/forms and structures whose semantic
# fidelity has not been validated. Inspect reachable objects including resources.
_FORBIDDEN = {'/JS','/JavaScript','/AA','/OpenAction','/A','/EmbeddedFiles',
              '/EF','/AcroForm','/StructTreeRoot','/MarkInfo','/RichMedia',
              '/XFA','/Collection','/Launch','/SubmitForm','/ImportData'}

def _inspect(root, limit):
    pending=[root]; seen=set(); count=0
    while pending:
        item=pending.pop()
        if isinstance(item, IndirectObject):
            identity=(id(item.pdf),item.idnum,item.generation)
            if identity in seen: continue
            seen.add(identity); item=item.get_object()
        elif isinstance(item,(DictionaryObject,ArrayObject)):
            identity=('direct',id(item))
            if identity in seen: continue
            seen.add(identity)
        else: continue
        count+=1
        if count>limit: raise WatermarkError('Object bound exceeded')
        if isinstance(item,DictionaryObject):
            if _FORBIDDEN.intersection(item.keys()):
                raise WatermarkError('Unsupported active or semantic PDF content')
            if str(item.get('/Type','')) in {'/Filespec','/EmbeddedFile'} or str(item.get('/Subtype','')) in {'/FileAttachment','/Screen','/Movie','/Sound','/RichMedia','/Widget'}:
                raise WatermarkError('Unsupported embedded content')
            pending.extend(item.values())
        else: pending.extend(item)

def _runs(text):
    # HarfBuzz guesses one script per buffer: isolate locale script runs so
    # the Latin license prefix cannot suppress Sinhala/Tamil shaping.
    runs=[]; current=''; previous=None
    for char in text:
        code=ord(char)
        script='sinhala' if 0xD80<=code<=0xDFF else 'tamil' if 0xB80<=code<=0xBFF else 'latin'
        if char.isspace(): script=previous or script
        if previous is not None and script!=previous:
            runs.append(current); current=''
        current+=char; previous=script
    if current: runs.append(current)
    return runs

def _shaped_parts(label,font_name,size):
    parts=[shapeStr(run,font_name,size,force=True) for run in _runs(label)]
    widths=[sum(sd.x_advance for sd in part.__shapeData__)*size/1000
            if hasattr(part,'__shapeData__') else stringWidth(part,font_name,size)
            for part in parts]
    return parts,widths

def generate(source: bytes, *, display_name: str, license_id: str,
             source_sha256: str, limits: Limits = Limits(), trusted_font_path: str | None = None) -> bytes:
    """Use ONLY backend-trusted identity and the immutable asset digest.

    Preserves page boxes/rotation and text for supported untagged PDFs.
    Unicode names require a server-configured font with complete glyph coverage.
    Unicode is shaped using the pinned HarfBuzz runtime and embedded font.
    """
    try:
        if not isinstance(limits, Limits) or any(type(v) is not int or v<=0 for v in vars(limits).values()):
            raise WatermarkError('Invalid bounds')
        if type(source) is not bytes or not source or len(source)>limits.max_input_bytes:
            raise WatermarkError('Input bound exceeded')
        if not isinstance(source_sha256,str) or not re.fullmatch('[0-9a-f]{64}',source_sha256) or hashlib.sha256(source).hexdigest()!=source_sha256:
            raise WatermarkError('Source integrity mismatch')
        if not isinstance(display_name,str) or not 1<=len(display_name.strip())<=100 or any(unicodedata.category(c).startswith("C") for c in display_name):
            raise WatermarkError('Unsupported display name')
        if not isinstance(license_id,str) or str(UUID(license_id))!=license_id:
            raise WatermarkError('Invalid license identifier')
        font_name='Helvetica'
        if any(ord(c)>126 for c in display_name):
            if trusted_font_path is None: raise WatermarkError('Unicode font required')
            path=Path(trusted_font_path)
            if not path.is_absolute() or not path.is_file() or path.stat().st_size>20*1024*1024:
                raise WatermarkError('Invalid trusted font')
            font_name='Acedra'+hashlib.sha256(path.read_bytes()).hexdigest()[:16]
            font=TTFont(font_name,str(path),subfontIndex=0)
            if any(ord(c) not in font.face.charToGlyph for c in display_name):
                raise WatermarkError('Missing Unicode glyph')
            if not font.shapable: raise WatermarkError('Unicode shaping runtime required')
            registerFont(font)
        reader=PdfReader(io.BytesIO(source),strict=True)
        if reader.is_encrypted: raise WatermarkError('Encrypted PDF unsupported')
        _inspect(reader.trailer,limits.max_objects)
        if not 1<=len(reader.pages)<=limits.max_pages: raise WatermarkError('Page bound exceeded')
        writer=PdfWriter()
        label=f'Licensed to {display_name.strip()} - {license_id}'
        unit_width=sum(_shaped_parts(label,font_name,1)[1]) if font_name!='Helvetica' else stringWidth(label,font_name,1)
        for original_page in reader.pages:
            page = writer.add_page(original_page)
            box=page.cropbox
            x,y,w,h=float(box.left),float(box.bottom),float(box.width),float(box.height)
            if not all(math.isfinite(v) for v in (x,y,w,h)) or min(w,h)<100 or max(w,h)>14400 or page.rotation%90 or page.get('/UserUnit',1)!=1:
                raise WatermarkError('Unsupported page geometry')
            # Paint inside the crop box without normalizing rotation or changing
            # original boxes. This is permanent page content, not an annotation.
            overlay=io.BytesIO(); canvas=Canvas(overlay,pagesize=(w,h),invariant=1)
            font_size=min(10,(w-24)/unit_width)
            if font_size<4: raise WatermarkError('Watermark would be unreadable')
            canvas.setFillColorRGB(.35,.35,.35)
            canvas.setFillAlpha(.6)
            canvas.setFont(font_name,font_size)
            if font_name=='Helvetica':
                canvas.drawCentredString(w/2,12,label)
            else:
                parts,widths=_shaped_parts(label,font_name,font_size)
                cursor=(w-sum(widths))/2
                for part,width in zip(parts,widths):
                    canvas.drawString(cursor,12,part)
                    cursor+=width
            canvas.save()
            stamp=PdfReader(overlay,strict=True).pages[0]
            page.merge_translated_page(stamp,x,y,expand=False)
        writer.add_metadata({'/Producer':'Acedra watermark policy v1', '/SourceSHA256':source_sha256})
        output=_BoundedOutput(limits.max_output_bytes); writer.write(output)
        data=output.getvalue()
        # Reparse all pages and verify identity content prior to returning bytes.
        check=PdfReader(io.BytesIO(data),strict=True)
        if len(check.pages)!=len(reader.pages) or any(license_id not in p.extract_text() for p in check.pages):
            raise WatermarkError('Derivative verification failed')
        return data
    except WatermarkError:
        raise
    except Exception:
        raise WatermarkError('PDF generation rejected') from None
