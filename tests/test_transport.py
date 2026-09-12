#!/usr/bin/env python3
"""Exercise the real MascotRemoteQuery transport against a loopback HTTP server."""

import http.server
import os
import subprocess
import sys
import threading
import time
import unittest
import urllib.parse


class MascotTransport(unittest.TestCase):
    def test_upload_http_errors_and_target_decoy_export(self):
        for scenario in ("post_error", "get_error", "success"):
            with self.subTest(scenario=scenario):
                requests = []

                class Handler(http.server.BaseHTTPRequestHandler):
                    def log_message(self, *_args):
                        pass

                    def respond(self, status, body):
                        payload = body.encode("utf-8")
                        self.send_response(status)
                        self.send_header("Content-Length", str(len(payload)))
                        self.end_headers()
                        self.wfile.write(payload)

                    def do_POST(self):
                        body = self.rfile.read(int(self.headers["Content-Length"]))
                        requests.append(("POST", self.path, dict(self.headers), body))
                        if scenario == "post_error":
                            self.respond(503, "Service unavailable")
                        else:
                            self.respond(200, '<a href="master_results.pl?file=../data/20260101/F000123.dat">'
                                         'Click here to see Search Report</a>')

                    def do_GET(self):
                        requests.append(("GET", self.path, dict(self.headers), b""))
                        if scenario == "get_error":
                            self.respond(503, "Service unavailable")
                        else:
                            params = urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query)
                            tag = "decoy" if params.get("show_decoy") == ["1"] else "target"
                            self.respond(200, f"<mascot_search_results><{tag}>local</{tag}></mascot_search_results>")

                with http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler) as server:
                    thread = threading.Thread(target=server.serve_forever, daemon=True)
                    thread.start()
                    try:
                        environment = os.environ.copy()
                        # Keep the local fixture local even on hosts configured with HTTP proxies.
                        environment["NO_PROXY"] = environment["no_proxy"] = "127.0.0.1"
                        started = time.monotonic()
                        try:
                            completed = subprocess.run(
                                [DRIVER, str(server.server_port), scenario],
                                env=environment, capture_output=True, text=True, timeout=60,
                            )
                        except subprocess.TimeoutExpired as timeout:
                            # Say what the driver managed to do before it stalled; a bare
                            # TimeoutExpired hides which request hung.
                            self.fail(f"driver stalled after {time.monotonic() - started:.1f}s with "
                                      f"{len(requests)} request(s) served {[r[:2] for r in requests]}; "
                                      f"stdout={timeout.stdout!r} stderr={timeout.stderr!r}")
                        elapsed = time.monotonic() - started
                    finally:
                        server.shutdown()
                        thread.join(timeout=5)
                    self.assertFalse(thread.is_alive())

                self.assertEqual(completed.returncode, 0, completed.stdout + completed.stderr)
                print(f"{scenario}: {elapsed:.2f}s", file=sys.stderr)
                self.assertEqual(len(requests), {"post_error": 1, "get_error": 2, "success": 3}[scenario])
                method, path, headers, body = requests[0]
                self.assertEqual((method, path), ("POST", "/mascot/cgi/nph-mascot.exe?1"))
                self.assertIn("multipart/form-data; boundary=", headers["Content-Type"])
                self.assertIn(b'Content-Disposition: form-data; name="QUE"', body)
                self.assertIn(b"BEGIN IONS\nTITLE=local transport regression\n500.0 100.0\nEND IONS\n", body)
                for method, path, _headers, _body in requests[1:]:
                    self.assertEqual(method, "GET")
                    parsed = urllib.parse.urlsplit(path)
                    self.assertEqual(parsed.path, "/mascot/cgi/export_dat_2.pl")
                    params = urllib.parse.parse_qs(parsed.query)
                    self.assertEqual(params["file"], ["../data/20260101/F000123.dat"])
                    self.assertEqual(params["do_export"], ["1"])
                    self.assertEqual(params["export_format"], ["XML"])
                if scenario == "success":
                    self.assertNotIn("show_decoy=1", requests[1][1])
                    self.assertIn("show_decoy=1", requests[2][1])


if __name__ == "__main__":
    DRIVER = sys.argv.pop(1)
    unittest.main()
