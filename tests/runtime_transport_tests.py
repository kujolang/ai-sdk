"""Loopback HTTP regression harness; Python owns fixtures, SDK behavior stays Kujo."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import threading
import time
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = os.environ.get("KUJO_BIN", "kujo")
CHAT = b'{"choices":[{"message":{"content":"ok"}}],"usage":{"total_tokens":2}}'
EMBED = b'{"data":[{"index":0,"embedding":[0.1]}],"usage":{"total_tokens":1}}'

class TransportTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.marker = Path(self.tmp.name) / "first-chunk"
        self.counts = {}
        owner = self
        class Handler(BaseHTTPRequestHandler):
            protocol_version = "HTTP/1.1"
            def log_message(self, *args):
                pass
            def do_GET(self):
                self.do_POST()
            def do_POST(self):
                owner.counts[self.path] = owner.counts.get(self.path, 0) + 1
                self.rfile.read(int(self.headers.get("Content-Length", 0)))
                path = self.path
                if path == "/redirect":
                    self.send_response(307)
                    self.send_header("Location", f"http://localhost:{self.server.server_port}/target")
                    self.send_header("Content-Length", "0")
                    self.end_headers()
                    return
                if path == "/large":
                    body = b"x" * 16384
                    self.send_response(200)
                    self.send_header("Content-Length", str(len(body)))
                    self.end_headers()
                    try: self.wfile.write(body)
                    except (BrokenPipeError, ConnectionResetError): pass
                    return
                if path in ("/stream", "/cancel", "/chunked-large"):
                    self.send_response(200)
                    self.send_header("Content-Type", "text/event-stream")
                    self.send_header("Transfer-Encoding", "chunked")
                    self.end_headers()
                    def chunk(data):
                        self.wfile.write(f"{len(data):x}\r\n".encode() + data + b"\r\n")
                        self.wfile.flush()
                    try:
                        if path == "/chunked-large":
                            for _ in range(32): chunk(b"x" * 128)
                        else:
                            chunk(b'data: {"choices":[{"delta":{"content":"first"}}]}\n\n')
                            if path == "/stream":
                                deadline = time.monotonic() + 5
                                while not owner.marker.exists() and time.monotonic() < deadline:
                                    time.sleep(.01)
                                if not owner.marker.exists(): return
                            # Split a multibyte code point between network writes.
                            chunk(b'data: {"choices":[{"delta":{"content":"\xc3')
                            time.sleep(.03)
                            chunk(b'\xa9"},"finish_reason":"stop"}],"usage":{"total_tokens":2}}\n\ndata: [DONE]\n\n')
                        self.wfile.write(b"0\r\n\r\n")
                        self.wfile.flush()
                    except (BrokenPipeError, ConnectionResetError): pass
                    return
                body = EMBED if path == "/embeddings" else CHAT
                self.send_response(200)
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
        class QuietServer(ThreadingHTTPServer):
            def handle_error(self, request, client_address):
                pass
        self.server = QuietServer(("127.0.0.1", 0), Handler)
        self.server.daemon_threads = True
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()
        self.tmp.cleanup()

    def run_kujo(self, code, interpreter=True, extra=()):
        source = Path(self.tmp.name) / "probe.kujo"
        # Root imports resolve relative to the invocation cwd.
        source.write_text(code)
        command = [RUNTIME, "run", str(source)] + (["--interpreter"] if interpreter else []) + list(extra)
        result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True, timeout=25)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def sdk(self, path, options, embedding=False, prefix="", interpreter=True, suffix=""):
        base = f"http://127.0.0.1:{self.server.server_port}"
        call = 'embeddings(client, "x"' if embedding else "chat_completion(client, []"
        code = f'''from src.providers import openai_provider
from src.ai_sdk import create_client, chat_completion, embeddings
provider := openai_provider()
provider["base_url"] = {json.dumps(base)}
provider["allow_insecure_localhost"] = true
provider["chat_path"] = {json.dumps(path)}
provider["embeddings_path"] = {json.dumps(path)}
client := create_client(provider, "fixture-key")
{prefix}
result := {call}, {options})
print("RESULT:" + to_json(result))
{suffix}
'''
        output = self.run_kujo(code, interpreter)
        return json.loads(next(line[7:] for line in output.splitlines() if line.startswith("RESULT:")))

    def has_collector(self):
        source = Path(self.tmp.name) / "capability.kujo"
        source.write_text('print(type(http_stream_collect))')
        result = subprocess.run([RUNTIME, "run", str(source), "--interpreter"], cwd=ROOT, capture_output=True, text=True, timeout=15)
        available = result.returncode == 0 and result.stdout.strip().endswith("function")
        if os.environ.get("KUJO_REQUIRE_STREAM_COLLECT") == "1":
            self.assertTrue(available, "stream consumer required on this runtime")
        return available

    def test_redirect_policy_and_allowlist_prevent_following(self):
        for interpreter in (True, False):
            with self.subTest(interpreter=interpreter):
                result = self.sdk("/redirect", '{"max_retries":0,"endpoint_allowlist_enabled":true,"endpoint_allowlist_hosts":["127.0.0.1"]}', interpreter=interpreter)
                self.assertFalse(result["ok"])
                self.assertEqual(result["status_code"], 307)
                self.assertEqual(self.counts.get("/target", 0), 0)
        self.assertTrue(self.sdk("/redirect", '{"max_retries":0}')["ok"])
        self.assertEqual(self.counts["/target"], 1)
        self.assertFalse(self.sdk("/redirect", '{"max_retries":0,"redirects":"none"}')["ok"])
        self.assertEqual(self.counts["/target"], 1)

    def test_download_limit_is_terminal_for_chat_and_embeddings(self):
        for embedding in (False, True):
            before = self.counts.get("/large", 0)
            result = self.sdk("/large", '{"max_raw_response_bytes":128,"max_retries":2}', embedding)
            self.assertEqual(result["error"]["code"], "response_too_large")
            self.assertFalse(result["error"]["retryable"])
            self.assertEqual(self.counts["/large"] - before, 1)
        result = self.sdk("/chunked-large", '{"max_raw_response_bytes":128,"max_retries":2}')
        self.assertEqual(result["error"]["code"], "response_too_large")
        self.assertEqual(self.counts["/chunked-large"], 1)

    def test_bounded_success_and_legacy_custom_transport(self):
        self.assertTrue(self.sdk("/target", '{"max_raw_response_bytes":1024}')["ok"])
        self.assertTrue(self.sdk("/embeddings", '{"max_raw_response_bytes":1024}', True)["ok"])
        result = self.sdk("/target", '{"transport":func(u,o){return Err("offline")} ,"max_retries":0}')
        self.assertEqual(result["error"]["code"], "network_error")

    def test_incremental_delivery_utf8_and_old_runtime_rejection(self):
        if not self.has_collector():
            result = self.sdk("/stream", '{"stream":true,"on_transport_chunk":func(e){return true},"max_retries":2}')
            self.assertEqual(result["error"]["code"], "unsupported_feature")
            self.assertEqual(self.counts.get("/stream", 0), 0)
            return
        for interpreter in (True, False):
            self.marker.unlink(missing_ok=True)
            prefix = f'''shared_set("stream-text", "")
callback := func(event) {{
 shared_set("stream-text", shared_get("stream-text") + event["text"])
 write_file({json.dumps(str(self.marker))}, "seen", true)
 return true
}}
'''
            result = self.sdk("/stream", '{"stream":true,"on_transport_chunk":callback,"max_raw_response_bytes":2048}', prefix=prefix, interpreter=interpreter, suffix='assert_equal(contains(shared_get("stream-text"), "é"), 1)\nassert_equal(contains(shared_get("stream-text"), "�"), 0)')
            self.assertTrue(result["ok"], result)
            self.assertEqual(result["output_text"], "firsté")
            self.assertTrue(self.marker.exists())

    def test_incremental_cancellation_and_size_failure_are_not_retried(self):
        if not self.has_collector():
            self.skipTest("published runtime has no consumer API; rejection tested separately")
        for path, code in (("/cancel", "transport_error"), ("/chunked-large", "response_too_large")):
            callback = "false" if path == "/cancel" else "true"
            result = self.sdk(path, '{"stream":true,"max_retries":3,"max_raw_response_bytes":128,"on_transport_chunk":func(e){return '+callback+'}}')
            self.assertEqual(result["error"]["code"], code)
            self.assertFalse(result["error"]["retryable"])
            self.assertEqual(self.counts[path], 1)
        result = self.sdk("/cancel", '{"stream":true,"max_retries":3,"on_transport_chunk":func(e){throw "fixture-secret"}}')
        self.assertEqual(result["error"]["code"], "transport_error")
        self.assertNotIn("fixture-secret", json.dumps(result))
        self.assertEqual(self.counts["/cancel"], 2)
        result = self.sdk("/target", '{"stream":true,"max_retries":3,"structured_output_schema":{"required":["answer"]},"on_transport_chunk":func(e){return true}}')
        self.assertEqual(result["error"]["code"], "structured_output_invalid")
        self.assertFalse(result["error"]["retryable"])
        self.assertEqual(self.counts["/target"], 1)

    def test_native_consumer_single_use_reentrancy_and_capability(self):
        if not self.has_collector():
            self.skipTest("native consumer absent in unpatched published runtime")
        url = json.dumps(f"http://127.0.0.1:{self.server.server_port}/target")
        code = '''match http_request(URL, {"response_stream":true,"redirects":"none"}) {
 case Ok(stream): {
  result := http_stream_collect(stream, func(event) {
   nested := http_stream_collect(stream, func(e){return true})
   match nested { case Err(error): {} case other: {throw "alias was consumed twice"} }
   return true
  })
  match result { case Ok(response): {assert_equal(response["_status"],200)} case Err(error): {throw error} }
  again := http_stream_collect(stream,func(e){return true})
  match again { case Err(error): {} case other: {throw "stream reused"} }
 }
 case Err(error): {throw error}
}
'''.replace("URL", url)
        for interpreter in (True, False):
            self.run_kujo(code, interpreter)
            source = Path(self.tmp.name) / "restricted.kujo"
            source.write_text('http_stream_collect(null,func(e){return true})')
            command = [RUNTIME,"run",str(source),"--untrusted"] + (["--interpreter"] if interpreter else [])
            result = subprocess.run(command,cwd=ROOT,text=True,capture_output=True,timeout=15)
            self.assertNotEqual(result.returncode,0)
            self.assertIn("capability", (result.stdout+result.stderr).lower())

if __name__ == "__main__":
    unittest.main()
