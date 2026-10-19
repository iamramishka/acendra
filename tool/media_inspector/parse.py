"""One untrusted file per OS-limited child process. Never called in the HTTP process."""
import io
import json
import sys
import warnings

MAX_PIXELS = 16_000_000
MAX_EXPANDED = 128 * 1024 * 1024


def parse(data, mime):
    if mime in ("image/png", "image/jpeg"):
        from PIL import Image, ImageFile, PngImagePlugin
        Image.MAX_IMAGE_PIXELS = MAX_PIXELS
        ImageFile.LOAD_TRUNCATED_IMAGES = False
        PngImagePlugin.MAX_TEXT_CHUNK = 65536
        PngImagePlugin.MAX_TEXT_MEMORY = 262144
        warnings.simplefilter("error")
        expected = {"image/png": "PNG", "image/jpeg": "JPEG"}[mime]
        if mime == "image/png" and not data.endswith(b"\x00\x00\x00\x00IEND\xaeB\x60\x82"):
            raise ValueError("PNG end")
        if mime == "image/jpeg" and not data.endswith(b"\xff\xd9"):
            raise ValueError("JPEG end")
        with Image.open(io.BytesIO(data), formats=[expected]) as image:
            if image.format != expected or getattr(image, "n_frames", 1) != 1:
                raise ValueError("Image format")
            if not 0 < image.width * image.height <= MAX_PIXELS:
                raise ValueError("Pixels")
            image.verify()
        with Image.open(io.BytesIO(data), formats=[expected]) as image:
            image.load()  # verify alone does not decode pixel data
        return
    if mime != "application/pdf" or not data.startswith(b"%PDF-") or not data.rstrip().endswith(b"%%EOF"):
        raise ValueError("Format")
    from pypdf import PdfReader
    from pypdf.generic import ArrayObject, DictionaryObject, IndirectObject, StreamObject
    warnings.simplefilter("error")
    reader = PdfReader(io.BytesIO(data), strict=True)
    if reader.is_encrypted or not 0 < len(reader.pages) <= 1000:
        raise ValueError("PDF pages/encryption")
    forbidden = {"/JS", "/JavaScript", "/OpenAction", "/AA", "/Launch", "/EmbeddedFiles",
                 "/EmbeddedFile", "/RichMedia", "/XFA", "/AcroForm", "/SubmitForm", "/ImportData"}
    visited = set()
    expanded = 0
    count = 0

    def visit(value, depth=0):
        nonlocal expanded, count
        if depth > 64:
            raise ValueError("PDF depth")
        if isinstance(value, IndirectObject):
            key = (value.idnum, value.generation)
            if key in visited:
                return
            visited.add(key)
            if len(visited) > 20000:
                raise ValueError("PDF objects")
            value = value.get_object()
        count += 1
        if count > 200000:
            raise ValueError("PDF complexity")
        if isinstance(value, DictionaryObject):
            if forbidden.intersection(str(k) for k in value.keys()) or any(
                str(v) in forbidden for v in value.values()
            ):
                raise ValueError("Active PDF")
            if isinstance(value, StreamObject):
                expanded += len(value.get_data())
                if expanded > MAX_EXPANDED:
                    raise ValueError("Expanded PDF")
            for child in value.values():
                visit(child, depth + 1)
        elif isinstance(value, ArrayObject):
            for child in value:
                visit(child, depth + 1)
    visit(reader.trailer)
    # Inspect unused and compressed objects too; hidden actions must not escape traversal.
    for generation, entries in reader.xref.items():
        for object_id in entries:
            if object_id:
                visit(IndirectObject(object_id, generation, reader))
    for object_id in reader.xref_objStm:
        visit(IndirectObject(object_id, 0, reader))
    for page in reader.pages:
        contents = page.get_contents()
        if contents is not None:
            # pypdf defers operator parsing; force it inside the bounded child.
            _ = contents.operations


if __name__ == "__main__":
    import resource
    resource.setrlimit(resource.RLIMIT_AS, (512 * 1024 * 1024,) * 2)
    resource.setrlimit(resource.RLIMIT_CPU, (8, 8))
    resource.setrlimit(resource.RLIMIT_FSIZE, (0, 0))
    resource.setrlimit(resource.RLIMIT_NOFILE, (32, 32))
    try:
        data = sys.stdin.buffer.read(50 * 1024 * 1024 + 1)
        if len(data) > 50 * 1024 * 1024:
            raise ValueError("Size")
        parse(data, sys.argv[1])
        print(json.dumps({"parseable": True}))
    except Exception:
        sys.exit(1)
