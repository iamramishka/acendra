"""Private, authenticated service. Deploy behind TLS; never expose the scanner socket."""
import datetime
import hashlib
import hmac
import http.server
import json
import os
from pathlib import Path
import socket
import struct
import subprocess
import sys
import time

POLICY = "csa267-media-v1"
LIMITS = {"application/pdf": 50 * 1024 * 1024, "image/png": 5 * 1024 * 1024, "image/jpeg": 5 * 1024 * 1024}


def reply(sock):
    result = bytearray()
    while len(result) <= 1024:
        chunk = sock.recv(1)
        if not chunk:
            raise ValueError("Scanner closed")
        if chunk == b"\0":
            return bytes(result)
        result.extend(chunk)
    raise ValueError("Scanner reply")


def scanner_clean(data):
    host = os.environ["CLAMD_HOST"]
    port = int(os.environ.get("CLAMD_PORT", "3310"))
    # Reject stale signature databases rather than accepting a scanner process alone.
    with socket.create_connection((host, port), timeout=5) as sock:
        sock.sendall(b"zVERSION\0")
        version = reply(sock).decode("ascii").split("/", 2)
    stamp = datetime.datetime.strptime(version[2], "%a %b %d %H:%M:%S %Y").replace(tzinfo=datetime.timezone.utc)
    age = (datetime.datetime.now(datetime.timezone.utc) - stamp).total_seconds()
    if not 0 <= age <= 72 * 3600:
        raise ValueError("Scanner signatures")
    with socket.create_connection((host, port), timeout=5) as sock:
        deadline = time.monotonic() + 8
        sock.sendall(b"zINSTREAM\0")
        for offset in range(0, len(data), 65536):
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError("Scanner deadline")
            sock.settimeout(remaining)
            chunk = data[offset:offset + 65536]
            sock.sendall(struct.pack("!I", len(chunk)) + chunk)
        sock.sendall(b"\0" * 4)
        sock.settimeout(max(0.001, deadline - time.monotonic()))
        if reply(sock) != b"stream: OK":
            raise ValueError("Scanner rejected")


def inspect(data, mime, digest, policy):
    if policy != POLICY or mime not in LIMITS or not 0 < len(data) <= LIMITS[mime]:
        raise ValueError("Metadata")
    if not hmac.compare_digest(hashlib.sha256(data).hexdigest(), digest):
        raise ValueError("Digest")
    result = subprocess.run(
        [sys.executable, "-I", str(Path(__file__).with_name("parse.py")), mime],
        input=data, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
        timeout=10, check=True,
        env={"PATH": "/usr/local/bin:/usr/bin", "LANG": "C.UTF-8"},
    )
    if result.stdout.strip() != b'{"parseable": true}':
        raise ValueError("Parser")
    scanner_clean(data)
    return {"safe": True, "parseable": True, "encrypted": False, "withinResourceLimits": True,
            "sha256": digest, "size": len(data), "mime": mime, "policyReference": POLICY}


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # No object bytes, tokens, identities or file names in request logs.

    def do_POST(self):
        self.connection.settimeout(10)
        status, result = 422, {"error": "INSPECTION_FAILED"}
        try:
            secret = os.environ["MEDIA_INSPECTOR_KEY"]
            if len(secret) < 32 or not hmac.compare_digest(self.headers.get("Authorization", ""), "Bearer " + secret):
                status = 401
                raise ValueError("Auth")
            if self.path != "/inspect" or self.headers.get("Transfer-Encoding"):
                raise ValueError("Request")
            mime = self.headers.get("Content-Type", "")
            size = int(self.headers.get("Content-Length", "0"))
            if not 0 < size <= LIMITS.get(mime, 0):
                status = 413
                raise ValueError("Size")
            data = self.rfile.read(size)
            if len(data) != size:
                raise ValueError("Truncated")
            result = inspect(data, mime, self.headers.get("X-Media-SHA256", ""),
                             self.headers.get("X-Media-Policy", ""))
            status = 200
        except Exception:
            pass
        body = json.dumps(result).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    # Serial server bounds concurrency and memory; reverse proxy must bound queued requests.
    http.server.HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
