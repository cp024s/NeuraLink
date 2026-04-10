#!/usr/bin/env python3
import argparse
import json
import pathlib
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse


def run_single(root: pathlib.Path, payload: dict):
  out_dir = root / "results" / "live_ui"
  out_dir.mkdir(parents=True, exist_ok=True)
  run_name = payload.get("run_name", "ui_run")
  rows = int(payload.get("rows", 8))
  cols = int(payload.get("cols", 8))
  k = int(payload.get("k", 32))
  warmup = int(payload.get("warmup", 4))
  maxbw = int(payload.get("maxbw", 64))
  opclass = int(payload.get("op_class", 0))
  log_path = out_dir / f"{run_name}.log"

  subprocess.run([str(root / "scripts" / "build_sim.sh")], cwd=root, check=True)
  subprocess.run(
    [
      str(root / "scripts" / "run_config.sh"),
      str(rows), str(cols), str(k), str(warmup), str(maxbw), str(log_path), str(opclass)
    ],
    cwd=root,
    check=True,
  )

  subprocess.run(
    [str(root / "benchmarks" / "benchmark_runner.py"), "--config", str(root / "configs" / "demo_configs.json"), "--out-dir", str(out_dir)],
    cwd=root,
    check=True,
  )
  subprocess.run([str(root / "scripts" / "run_plots.sh"), str(out_dir / "metrics.csv"), str(out_dir)], cwd=root, check=True)
  subprocess.run(
    [
      str(root / "benchmarks" / "baseline_compare.py"),
      "--metrics-csv", str(out_dir / "metrics.csv"),
      "--baseline-json", str(root / "configs" / "baseline_equivalent.json"),
      "--out-json", str(out_dir / "baseline_comparison.json"),
    ],
    cwd=root,
    check=True,
  )
  subprocess.run(
    [
      str(root / "benchmarks" / "html_report.py"),
      "--metrics-csv", str(out_dir / "metrics.csv"),
      "--comparison-json", str(out_dir / "baseline_comparison.json"),
      "--capability-json", str(root / "configs" / "capability_matrix.json"),
      "--out-html", str(out_dir / "benchmark_report.html"),
      "--title", "NeuraLink Benchmark Report",
    ],
    cwd=root,
    check=True,
  )
  return {
    "ok": True,
    "report_path": "/results/live_ui/benchmark_report.html",
    "log_path": f"/results/live_ui/{run_name}.log"
  }


class Handler(BaseHTTPRequestHandler):
  root: pathlib.Path = pathlib.Path(".")

  def _send(self, code, body, ctype="application/json"):
    self.send_response(code)
    self.send_header("Content-Type", ctype)
    self.end_headers()
    if isinstance(body, str):
      body = body.encode()
    self.wfile.write(body)

  def do_GET(self):
    parsed = urlparse(self.path)
    if parsed.path == "/" or parsed.path == "/index.html":
      p = self.root / "webui" / "index.html"
      self._send(200, p.read_text(), "text/html; charset=utf-8")
      return
    if parsed.path.startswith("/results/"):
      p = self.root / parsed.path.lstrip("/")
      if p.exists() and p.is_file():
        ctype = "text/plain"
        if p.suffix == ".html":
          ctype = "text/html; charset=utf-8"
        elif p.suffix == ".svg":
          ctype = "image/svg+xml"
        elif p.suffix == ".json":
          ctype = "application/json"
        self._send(200, p.read_bytes(), ctype)
      else:
        self._send(404, b"not found", "text/plain")
      return
    self._send(404, b"not found", "text/plain")

  def do_POST(self):
    parsed = urlparse(self.path)
    if parsed.path != "/api/run":
      self._send(404, b'{"error":"not found"}')
      return
    length = int(self.headers.get("Content-Length", "0"))
    try:
      payload = json.loads(self.rfile.read(length).decode() if length > 0 else "{}")
      resp = run_single(self.root, payload)
      self._send(200, json.dumps(resp))
    except Exception as e:
      self._send(500, json.dumps({"ok": False, "error": str(e)}))


def main():
  ap = argparse.ArgumentParser()
  ap.add_argument("--port", type=int, default=8080)
  ap.add_argument("--root", default=".")
  args = ap.parse_args()
  Handler.root = pathlib.Path(args.root).resolve()
  httpd = HTTPServer(("0.0.0.0", args.port), Handler)
  print(f"UI server running at http://localhost:{args.port}")
  httpd.serve_forever()


if __name__ == "__main__":
  main()
