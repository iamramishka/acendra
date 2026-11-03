# Build only from the allowlisted context produced by prepare_context.mjs.
# Official python:3.13-slim-bookworm index resolved on 2026-11-03.
FROM python@sha256:281d39ff02e3b389401586134ff9e6572954687822a58055ec07a60ded4e0b7f
RUN apt-get update \
 && apt-get install -y --no-install-recommends bubblewrap util-linux ca-certificates \
 && mkdir -p /opt/acendra \
 && dpkg-query -W > /opt/acendra/os-packages.txt \
 && rm -rf /var/lib/apt/lists/*
COPY requirements-linux.lock /opt/acendra/requirements-linux.lock
COPY requirements.txt /opt/acendra/requirements.txt
RUN python -m venv /opt/acendra/venv \
 && /opt/acendra/venv/bin/pip install --no-cache-dir --only-binary=:all: --require-hashes \
      -r /opt/acendra/requirements-linux.lock
COPY install_font.py /opt/acendra/install_font.py
RUN python /opt/acendra/install_font.py
COPY pdf_watermark /opt/acendra/pdf_watermark
COPY sandbox_job.py launch /opt/acendra/
RUN chmod 0555 /opt/acendra/launch \
 && groupadd --gid 10001 pdf-worker \
 && useradd --uid 10001 --gid 10001 --no-create-home --shell /usr/sbin/nologin pdf-worker \
 && mkdir -p /vercel/sandbox \
 && chown 10001:10001 /vercel/sandbox \
 && chmod 0700 /vercel/sandbox
WORKDIR /vercel/sandbox
USER 10001:10001
# Vercel ignores ENTRYPOINT/CMD; the SDK invokes /opt/acendra/launch explicitly.
