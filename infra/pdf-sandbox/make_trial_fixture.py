"""Deterministic synthetic source for the separately approved two-job trial."""
import io
import hashlib
from pathlib import Path
from reportlab.pdfgen.canvas import Canvas


def fixture():
    stream = io.BytesIO()
    canvas = Canvas(stream, pagesize=(600, 800), invariant=1, pageCompression=0)
    for index, size in enumerate(((600, 800), (800, 600))):
        canvas.setPageSize(size)
        canvas.bookmarkPage('chapter-' + str(index))
        canvas.addOutlineEntry(('Introduction', 'Practice')[index], 'chapter-' + str(index))
        canvas.setFont('Helvetica-Bold', 22)
        canvas.drawString(48, size[1] - 64, 'Synthetic watermark runtime verification')
        canvas.setFont('Helvetica', 12)
        for line in range(12):
            canvas.drawString(48, size[1] - 110 - line * 22, 'Original selectable lesson text - synthetic content only.')
        canvas.showPage()
    canvas.save()
    return stream.getvalue()


if __name__ == '__main__':
    destination = Path(__file__).resolve().parents[2] / 'build/com020-readiness/sandbox-trial/source.pdf'
    destination.parent.mkdir(parents=True, exist_ok=True)
    data = fixture()
    destination.write_bytes(data)
    print('Synthetic fixture SHA256:', hashlib.sha256(data).hexdigest())
