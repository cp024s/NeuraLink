#!/usr/bin/env python3
import argparse
import csv
import json
import pathlib
import re
import subprocess
from datetime import datetime


METRIC_RE = re.compile(r"^METRIC\s+([a-zA-Z0-9_]+)=(.+)$")


def parse_metrics(log_path: pathlib.Path) -> dict:
  metrics = {}
  for line in log_path.read_text().splitlines():
    match = METRIC_RE.match(line.strip())
    if not match:
      continue
    key = match.group(1)
    raw_val = match.group(2)
    try:
      if "." in raw_val:
        metrics[key] = float(raw_val)
      else:
        metrics[key] = int(raw_val)
    except ValueError:
      metrics[key] = raw_val
  return metrics


def run_single(root: pathlib.Path, out_dir: pathlib.Path, cfg: dict) -> dict:
  run_name = cfg["name"]
  log_path = out_dir / f"{run_name}.log"

  cmd = [
    str(root / "scripts" / "run_config.sh"),
    str(cfg["rows"]),
    str(cfg["cols"]),
    str(cfg["k"]),
    str(cfg.get("warmup", 4)),
    str(cfg.get("maxbw", 64)),
    str(log_path),
  ]
  subprocess.run(cmd, cwd=root, check=True)

  metrics = parse_metrics(log_path)
  metrics["name"] = run_name
  metrics["rows"] = cfg["rows"]
  metrics["cols"] = cfg["cols"]
  metrics["k"] = cfg["k"]
  metrics["timestamp"] = datetime.utcnow().isoformat() + "Z"
  return metrics


def main() -> None:
  parser = argparse.ArgumentParser()
  parser.add_argument("--config", required=True, help="Path to JSON config file")
  parser.add_argument("--out-dir", required=True, help="Directory for outputs")
  args = parser.parse_args()

  root = pathlib.Path(__file__).resolve().parent.parent
  out_dir = pathlib.Path(args.out_dir)
  out_dir.mkdir(parents=True, exist_ok=True)

  config_data = json.loads(pathlib.Path(args.config).read_text())
  runs = config_data["runs"]

  results = []
  for run_cfg in runs:
    result = run_single(root, out_dir, run_cfg)
    results.append(result)

  json_path = out_dir / "metrics.json"
  json_path.write_text(json.dumps(results, indent=2))

  if results:
    ordered_keys = [
      "name",
      "rows",
      "cols",
      "k",
      "latency_cycles",
      "throughput_ops_per_cycle",
      "efficiency",
      "bandwidth_utilization",
      "pipeline_depth",
      "total_mac_ops",
      "timestamp",
    ]
    csv_path = out_dir / "metrics.csv"
    with csv_path.open("w", newline="") as f:
      writer = csv.DictWriter(f, fieldnames=ordered_keys)
      writer.writeheader()
      for row in results:
        writer.writerow({k: row.get(k, "") for k in ordered_keys})

  print(f"Wrote benchmark results to: {out_dir}")


if __name__ == "__main__":
  main()
