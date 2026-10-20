import datetime
import hashlib
import io
import os
import socket
import struct
import sys
import threading
import unittest
from unittest.mock import patch
from PIL import Image
from pypdf import PdfWriter
from pypdf.generic import NameObject, TextStringObject, DecodedStreamObject
import parse
import server


class ParsingTests(unittest.TestCase):
    def image(self, kind="PNG", size=(2, 2)):
        out = io.BytesIO()
        Image.new("RGB", size).save(out, kind)
        return out.getvalue()

    def pdf(self, active=False, encrypted=False):
        writer = PdfWriter()
        writer.add_blank_page(width=100, height=100)
        if active:
            writer._root_object[NameObject("/OpenAction")] = TextStringObject("unsafe")
        if encrypted:
            writer.encrypt("synthetic")
        out = io.BytesIO()
        writer.write(out)
        return out.getvalue()

    def test_real_image_decode(self):
        parse.parse(self.image(), "image/png")
        parse.parse(self.image("JPEG"), "image/jpeg")

    def test_image_magic_truncation_trailing_and_mime(self):
        for data, mime in [(b"\x89PNG\r\n\x1a\n", "image/png"),
                           (self.image()[:-8], "image/png"),
                           (self.image() + b"unexpected", "image/png"),
                           (self.image(), "image/jpeg")]:
            with self.assertRaises(Exception):
                parse.parse(data, mime)

    def test_resource_bomb(self):
        with patch.object(parse, "MAX_PIXELS", 1):
            with self.assertRaises(Exception):
                parse.parse(self.image(), "image/png")

    def test_real_pdf_and_active_encrypted_rejection(self):
        parse.parse(self.pdf(), "application/pdf")
        for data in [self.pdf(active=True), self.pdf(encrypted=True), b"%PDF-forged"]:
            with self.assertRaises(Exception):
                parse.parse(data, "application/pdf")

    def test_pdf_content_operators_reject_malformed_stream(self):
        def document(content):
            writer = PdfWriter()
            page = writer.add_blank_page(width=100, height=100)
            stream = DecodedStreamObject()
            stream.set_data(content)
            page[NameObject("/Contents")] = writer._add_object(stream)
            out = io.BytesIO()
            writer.write(out)
            return out.getvalue()

        parse.parse(document(b"q\nQ\n"), "application/pdf")
        with self.assertRaises(Exception):
            parse.parse(document(b"q\n(unterminated"), "application/pdf")

    def test_metadata_and_digest_fail_before_any_parser_or_scan(self):
        for mime, digest, policy in [("text/plain", "a"*64, server.POLICY),
                                    ("image/png", "b"*64, server.POLICY),
                                    ("image/png", "a"*64, "unknown")]:
            with patch.object(server.subprocess, "run") as process:
                with self.assertRaises(Exception):
                    server.inspect(self.image(), mime, digest, policy)
                process.assert_not_called()

    @unittest.skipUnless(sys.platform == "linux", "Resource-limited child requires Linux")
    def test_real_limited_child_and_required_scanner(self):
        data = self.image()
        digest = hashlib.sha256(data).hexdigest()
        with patch.object(server, "scanner_clean", side_effect=ValueError("unavailable")):
            with self.assertRaises(Exception):
                server.inspect(data, "image/png", digest, server.POLICY)
        with patch.object(server, "scanner_clean") as scanner:
            verdict = server.inspect(data, "image/png", digest, server.POLICY)
            scanner.assert_called_once_with(data)
            self.assertTrue(verdict["withinResourceLimits"])
            self.assertEqual(verdict["sha256"], digest)

    def test_scanner_protocol_requires_explicit_clean_and_fresh_database(self):
        for verdict in [b"stream: OK", b"stream: Eicar-Test-Signature FOUND",
                        b"INSTREAM size limit exceeded ERROR"]:
            listener = socket.socket()
            listener.bind(("127.0.0.1", 0))
            listener.listen()
            received = []
            errors = []

            def exact(sock, size):
                data = b""
                while len(data) < size:
                    data += sock.recv(size - len(data))
                return data

            def scanner():
                try:
                    with listener.accept()[0] as sock:
                        self.assertEqual(exact(sock, 9), b"zVERSION\0")
                        stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%a %b %d %H:%M:%S %Y")
                        sock.sendall(("ClamAV 1.4.0/999/" + stamp).encode() + b"\0")
                    with listener.accept()[0] as sock:
                        self.assertEqual(exact(sock, 10), b"zINSTREAM\0")
                        data = bytearray()
                        while True:
                            size = struct.unpack("!I", exact(sock, 4))[0]
                            if not size:
                                break
                            data.extend(exact(sock, size))
                        received.append(bytes(data))
                        sock.sendall(verdict + b"\0")
                except BaseException as error:
                    errors.append(error)
                finally:
                    listener.close()
            worker = threading.Thread(target=scanner, daemon=True)
            worker.start()
            with patch.dict(os.environ, {"CLAMD_HOST": "127.0.0.1", "CLAMD_PORT": str(listener.getsockname()[1])}):
                if verdict == b"stream: OK":
                    server.scanner_clean(b"synthetic")
                else:
                    with self.assertRaises(ValueError):
                        server.scanner_clean(b"synthetic")
            worker.join(5)
            self.assertFalse(worker.is_alive())
            self.assertEqual(errors, [])
            self.assertEqual(received, [b"synthetic"])



class HTTPTests(unittest.TestCase):
    def test_auth_and_exact_body_verdict(self):
        import http.client
        httpd = server.http.server.HTTPServer(("127.0.0.1", 0), server.Handler)
        worker = threading.Thread(target=httpd.serve_forever, daemon=True)
        worker.start()
        try:
            with patch.dict(os.environ, {"MEDIA_INSPECTOR_KEY": "k" * 32}):
                connection = http.client.HTTPConnection("127.0.0.1", httpd.server_port, timeout=5)
                connection.request("POST", "/inspect", b"data", {"Content-Type": "image/png"})
                response = connection.getresponse()
                self.assertEqual(response.status, 401)
                response.read()
                connection.close()
                connection = http.client.HTTPConnection("127.0.0.1", httpd.server_port, timeout=5)
                with patch.object(server, "inspect", return_value={"safe": True}) as inspector:
                    connection.request("POST", "/inspect", b"data", {
                        "Authorization": "Bearer " + "k" * 32,
                        "Content-Type": "image/png",
                        "X-Media-SHA256": "a" * 64,
                        "X-Media-Policy": server.POLICY,
                    })
                    response = connection.getresponse()
                    self.assertEqual(response.status, 200)
                    self.assertEqual(response.getheader("Cache-Control"), "no-store")
                    response.read()
                    inspector.assert_called_once_with(b"data", "image/png", "a" * 64, server.POLICY)
                connection.close()
        finally:
            httpd.shutdown()
            httpd.server_close()
            worker.join(5)

if __name__ == "__main__":
    unittest.main()
