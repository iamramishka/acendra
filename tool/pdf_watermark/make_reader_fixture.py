"""Regenerate the synthetic COM-020 browser fixture; no student data or secrets."""
import hashlib
import io
import sys
from pathlib import Path
from reportlab.pdfgen.canvas import Canvas
from pypdf import PdfReader, PdfWriter
from watermark import generate

def fixture():
    stream = io.BytesIO()
    canvas = Canvas(stream, pagesize=(600, 800), invariant=1)
    for page in range(1, 5):
        canvas.setFont('Helvetica-Bold', 22)
        canvas.drawString(48, 738, 'Synthetic PDF reader verification')
        canvas.setFont('Helvetica', 14)
        canvas.drawString(48, 700, f'Page {page} of 4 - test content only')
        canvas.drawString(48, 660, 'Introduction' if page < 3 else 'Practice')
        canvas.drawString(48, 620, 'Selectable lesson text is preserved in the delivered PDF.')
        canvas.rect(48, 90, 504, 480)
        canvas.showPage()
    canvas.save()
    writer = PdfWriter()
    writer.append(PdfReader(stream))
    intro = writer.add_outline_item('Introduction', 0)
    writer.add_outline_item('Reading controls', 1, parent=intro)
    writer.add_outline_item('Practice', 2)
    original = io.BytesIO(); writer.write(original)
    source = original.getvalue()
    return generate(source, display_name='Demo Student',
                    license_id='27100000-0000-4000-8000-000000000001',
                    policy_id='14000000-0000-4000-8000-000000000002',
                    source_sha256=hashlib.sha256(source).hexdigest())

if __name__ == '__main__':
    destination = Path(sys.argv[1])
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(fixture())
    print('Synthetic watermarked reader fixture generated')
