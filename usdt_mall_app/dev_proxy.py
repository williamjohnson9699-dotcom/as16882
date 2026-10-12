#!/usr/bin/env python3
"""Serve the Flutter web build and reverse-proxy /api to the public site."""

import ssl
import urllib.error
import urllib.request
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

UPSTREAM = "https://www.as1688.me"
ROOT = "build/web"
PORT = 8090
HOP_BY_HOP = {
    "transfer-encoding",
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "upgrade",
    "content-length",
    "content-encoding",
}


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def do_GET(self):
        if self.path.startswith("/api/"):
            self._proxy()
        else:
            super().do_GET()

    def do_HEAD(self):
        if self.path.startswith("/api/"):
            self._proxy()
        else:
            super().do_HEAD()

    def do_POST(self):
        self._proxy() if self.path.startswith("/api/") else self.send_error(405)

    def do_PUT(self):
        self._proxy() if self.path.startswith("/api/") else self.send_error(405)

    def do_PATCH(self):
        self._proxy() if self.path.startswith("/api/") else self.send_error(405)

    def do_DELETE(self):
        self._proxy() if self.path.startswith("/api/") else self.send_error(405)

    def do_OPTIONS(self):
        self._proxy() if self.path.startswith("/api/") else self.send_error(405)

    def _proxy(self):
        length = int(self.headers.get("Content-Length", "0") or "0")
        body = self.rfile.read(length) if length else None
        request = urllib.request.Request(
            UPSTREAM + self.path, data=body, method=self.command
        )
        for key, value in self.headers.items():
            if key.lower() in ("host", "content-length", "connection", "accept-encoding"):
                continue
            request.add_header(key, value)
        try:
            response = urllib.request.urlopen(
                request, context=ssl.create_default_context(), timeout=60
            )
            status, headers, data = response.status, response.headers, response.read()
        except urllib.error.HTTPError as error:
            status, headers, data = error.code, error.headers, error.read()
        except Exception as error:
            self.send_error(502, explain=str(error))
            return

        self.send_response(status)
        for key, value in headers.items():
            if key.lower() in HOP_BY_HOP:
                continue
            self.send_header(key, value)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(data)


if __name__ == "__main__":
    print(f"serving {ROOT} on {PORT}, proxy /api -> {UPSTREAM}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
